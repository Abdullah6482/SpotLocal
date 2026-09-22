import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import 'recently_played_dao.dart';

/// Helper function to normalize Android storage and SAF directory paths.
String normalizeFolderPath(String rawPath) {
  String path = Uri.decodeComponent(rawPath);

  if (path.contains('primary:')) {
    final relative = path.split('primary:').last;
    path = '/storage/emulated/0/$relative';
  } else if (path.contains('primary%3A')) {
    final relative = path.split('primary%3A').last;
    path = '/storage/emulated/0/$relative';
  }

  path = p.normalize(path);
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

class DbHelper {
  static const String _dbName = 'spotlocal.db';
  static const int _dbVersion = 4;

  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE tracks ADD COLUMN track_number INTEGER');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS favorites (
                track_id INTEGER PRIMARY KEY,
                added_at INTEGER NOT NULL,
                FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
              )
            ''');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await RecentlyPlayedDao.createTable(db);
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. scan_folders table
    await db.execute('''
      CREATE TABLE scan_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. tracks table
    await db.execute('''
      CREATE TABLE tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        track_number INTEGER,
        duration_ms INTEGER NOT NULL,
        file_path TEXT UNIQUE NOT NULL,
        folder_path TEXT NOT NULL,
        file_hash TEXT NOT NULL,
        artwork_path TEXT,
        date_added INTEGER NOT NULL,
        FOREIGN KEY (folder_path) REFERENCES scan_folders (path) ON DELETE CASCADE
      )
    ''');

    // 3. playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 4. playlist_tracks table
    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id INTEGER NOT NULL,
        track_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
      )
    ''');

    // 5. favorites table
    await db.execute('''
      CREATE TABLE favorites (
        track_id INTEGER PRIMARY KEY,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
      )
    ''');

    // Indices for performance
    await db.execute('CREATE INDEX idx_tracks_folder ON tracks(folder_path)');
    await db.execute('CREATE INDEX idx_tracks_file_path ON tracks(file_path)');
    await db.execute('CREATE INDEX idx_favorites_added ON favorites(added_at)');

    // 6. recently_played table
    await RecentlyPlayedDao.createTable(db);
  }

  // ===========================================================================
  // SCAN FOLDERS CRUD
  // ===========================================================================

  /// Inserts a new scan folder into the database with path normalization.
  Future<int> insertScanFolder(String rawPath) async {
    final db = await database;
    final normalizedPath = normalizeFolderPath(rawPath);
    final folder = ScanFolder(
      path: normalizedPath,
      createdAt: DateTime.now(),
      isEnabled: true,
    );
    return await db.insert(
      'scan_folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetches all scan folders.
  Future<List<ScanFolder>> getScanFolders() async {
    final db = await database;
    final maps = await db.query('scan_folders', orderBy: 'path ASC');
    return maps.map((map) => ScanFolder.fromMap(map)).toList();
  }

  /// Fetches only enabled scan folders.
  Future<List<ScanFolder>> getEnabledScanFolders() async {
    final db = await database;
    final maps = await db.query(
      'scan_folders',
      where: 'is_enabled = ?',
      whereArgs: [1],
      orderBy: 'path ASC',
    );
    return maps.map((map) => ScanFolder.fromMap(map)).toList();
  }

  /// Toggles whether a scan folder is enabled for media inclusion.
  Future<int> toggleScanFolder(int id, bool isEnabled) async {
    final db = await database;
    return await db.update(
      'scan_folders',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a scan folder (cascades to delete stored tracks under this folder).
  Future<int> deleteScanFolder(int id) async {
    final db = await database;
    return await db.delete(
      'scan_folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // TRACKS CRUD & BATCH INSERT
  // ===========================================================================

  /// Batch inserts a list of parsed audio tracks using an efficient SQLite transaction.
  Future<void> batchInsertTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final db = await database;

    // Fetch existing scan folders to ensure foreign key match
    final scanFolders = await getScanFolders();
    final folderPaths = scanFolders.map((f) => f.path).toSet();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final track in tracks) {
        final normFolderPath = normalizeFolderPath(track.folderPath);

        // Auto-register folder if missing in scan_folders to prevent foreign key failure
        if (!folderPaths.contains(normFolderPath)) {
          batch.insert(
            'scan_folders',
            {
              'path': normFolderPath,
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'is_enabled': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          folderPaths.add(normFolderPath);
        }

        final trackToInsert = track.copyWith(
          folderPath: normFolderPath,
        );

        batch.insert(
          'tracks',
          trackToInsert.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Fetches all audio tracks grouped by album name.
  Future<List<Track>> getAllTracks() async {
    final db = await database;
    final maps = await db.query(
      'tracks',
      orderBy: 'COALESCE(album, "Unknown Album") ASC, track_number ASC, title ASC',
    );
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  /// Fetches audio tracks belonging to a specific scan folder grouped by album.
  Future<List<Track>> getTracksForFolder(String folderPath) async {
    final db = await database;
    final normalized = normalizeFolderPath(folderPath);
    final maps = await db.query(
      'tracks',
      where: 'folder_path = ?',
      whereArgs: [normalized],
      orderBy: 'COALESCE(album, "Unknown Album") ASC, track_number ASC, title ASC',
    );
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  /// Fetches a single track by its primary ID.
  Future<Track?> getTrackById(int id) async {
    final db = await database;
    final maps = await db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Track.fromMap(maps.first);
  }

  /// Fetches a single track by file path.
  Future<Track?> getTrackByFilePath(String filePath) async {
    final db = await database;
    final maps = await db.query(
      'tracks',
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Track.fromMap(maps.first);
  }

  /// Deletes a track by ID.
  Future<int> deleteTrack(int id) async {
    final db = await database;
    return await db.delete(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes tracks associated with a given folder path.
  Future<int> deleteTracksByFolderPath(String folderPath) async {
    final db = await database;
    final normalized = normalizeFolderPath(folderPath);
    return await db.delete(
      'tracks',
      where: 'folder_path = ?',
      whereArgs: [normalized],
    );
  }

  // ===========================================================================
  // PLAYLISTS CRUD
  // ===========================================================================

  /// Creates a new user playlist.
  Future<int> createPlaylist(String name) async {
    final db = await database;
    final now = DateTime.now();
    final playlist = Playlist(
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    return await db.insert('playlists', playlist.toMap());
  }

  /// Retrieves all playlists.
  Future<List<Playlist>> getPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'name ASC');
    return maps.map((map) => Playlist.fromMap(map)).toList();
  }

  /// Deletes a playlist.
  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Adds a track to a playlist.
  Future<void> addTrackToPlaylist(int playlistId, int trackId) async {
    final db = await database;

    final posResult = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final maxPos = (posResult.first['max_pos'] as int?) ?? -1;

    final entry = PlaylistTrack(
      playlistId: playlistId,
      trackId: trackId,
      position: maxPos + 1,
      addedAt: DateTime.now(),
    );

    await db.insert(
      'playlist_tracks',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all tracks associated with a specific playlist, ordered by position.
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN playlist_tracks pt ON t.id = pt.track_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', [playlistId]);
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  /// Removes a track from a playlist.
  Future<int> removeTrackFromPlaylist(int playlistId, int trackId) async {
    final db = await database;
    return await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  // ===========================================================================
  // FAVORITES CRUD
  // ===========================================================================

  /// Toggles favorite status for a track. Returns true if now favorite, false if removed.
  Future<bool> toggleFavorite(int trackId) async {
    final db = await database;
    final exists = await isFavorite(trackId);
    if (exists) {
      await db.delete('favorites', where: 'track_id = ?', whereArgs: [trackId]);
      return false;
    } else {
      await db.insert(
        'favorites',
        {
          'track_id': trackId,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }
  }

  /// Checks if a track is marked as favorite.
  Future<bool> isFavorite(int trackId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Retrieves all favorited tracks ordered by date added descending.
  Future<List<Track>> getFavoriteTracks() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN favorites f ON t.id = f.track_id
      ORDER BY f.added_at DESC
    ''');
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  /// Retrieves the set of all favorited track IDs for fast in-memory lookups.
  Future<Set<int>> getFavoriteTrackIds() async {
    final db = await database;
    final maps = await db.query('favorites', columns: ['track_id']);
    return maps.map((row) => row['track_id'] as int).toSet();
  }

  // ===========================================================================
  // RECENTLY PLAYED
  // ===========================================================================

  /// Records a track play into listening history.
  Future<void> recordRecentPlay(int trackId) async {
    final db = await database;
    await RecentlyPlayedDao.recordPlay(db, trackId);
  }

  /// Retrieves list of recently played tracks.
  Future<List<Track>> getRecentlyPlayedTracks() async {
    final db = await database;
    return await RecentlyPlayedDao.getRecentlyPlayed(db);
  }

  /// Clears user listening history.
  Future<void> clearRecentlyPlayed() async {
    final db = await database;
    await RecentlyPlayedDao.clearHistory(db);
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
