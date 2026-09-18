class Track {
  final int? id;
  final String title;
  final String? artist;
  final String? album;
  final int? trackNumber;
  final int durationMs;
  final String filePath;
  final String folderPath;
  final String fileHash;
  final String? artworkPath;
  final DateTime dateAdded;
  final bool isFavorite;

  const Track({
    this.id,
    required this.title,
    this.artist,
    this.album,
    this.trackNumber,
    required this.durationMs,
    required this.filePath,
    required this.folderPath,
    required this.fileHash,
    this.artworkPath,
    required this.dateAdded,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'track_number': trackNumber,
      'duration_ms': durationMs,
      'file_path': filePath,
      'folder_path': folderPath,
      'file_hash': fileHash,
      'artwork_path': artworkPath,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      trackNumber: map['track_number'] as int?,
      durationMs: map['duration_ms'] as int,
      filePath: map['file_path'] as String,
      folderPath: map['folder_path'] as String,
      fileHash: map['file_hash'] as String,
      artworkPath: map['artwork_path'] as String?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
      isFavorite: map['is_favorite'] == 1 || map['is_favorite'] == true,
    );
  }

  Track copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? trackNumber,
    int? durationMs,
    String? filePath,
    String? folderPath,
    String? fileHash,
    String? artworkPath,
    DateTime? dateAdded,
    bool? isFavorite,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      trackNumber: trackNumber ?? this.trackNumber,
      durationMs: durationMs ?? this.durationMs,
      filePath: filePath ?? this.filePath,
      folderPath: folderPath ?? this.folderPath,
      fileHash: fileHash ?? this.fileHash,
      artworkPath: artworkPath ?? this.artworkPath,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          fileHash == other.fileHash;

  @override
  int get hashCode => id.hashCode ^ filePath.hashCode ^ fileHash.hashCode;
}
