import 'package:sqflite/sqflite.dart';
import '../models/track.dart';

class RecentlyPlayedDao {
  static const String tableName = 'recently_played';
  static const int maxHistoryLimit = 50;

  /// Creates recently_played table and indices.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL,
        FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recent_played_at ON $tableName(played_at DESC)',
    );
  }

  /// Records a played track timestamp, deduplicating prior entries and pruning older history.
  static Future<void> recordPlay(Database db, int trackId) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(tableName, where: 'track_id = ?', whereArgs: [trackId]);
      await txn.insert(tableName, {
        'track_id': trackId,
        'played_at': now,
      });

      // Prune entries outside limit
      await txn.rawDelete('''
        DELETE FROM $tableName WHERE id NOT IN (
          SELECT id FROM $tableName ORDER BY played_at DESC LIMIT $maxHistoryLimit
        )
      ''');
    });
  }

  /// Retrieves recently played tracks ordered by most recently played first.
  static Future<List<Track>> getRecentlyPlayed(Database db) async {
    final maps = await db.rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN $tableName r ON t.id = r.track_id
      ORDER BY r.played_at DESC
      LIMIT $maxHistoryLimit
    ''');
    return maps.map((m) => Track.fromMap(m)).toList();
  }

  /// Clears recently played listening history.
  static Future<void> clearHistory(Database db) async {
    await db.delete(tableName);
  }
}
