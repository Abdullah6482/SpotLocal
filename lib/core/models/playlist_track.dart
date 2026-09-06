class PlaylistTrack {
  final int playlistId;
  final int trackId;
  final int position;
  final DateTime addedAt;

  const PlaylistTrack({
    required this.playlistId,
    required this.trackId,
    required this.position,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': position,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  factory PlaylistTrack.fromMap(Map<String, dynamic> map) {
    return PlaylistTrack(
      playlistId: map['playlist_id'] as int,
      trackId: map['track_id'] as int,
      position: map['position'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }
}

