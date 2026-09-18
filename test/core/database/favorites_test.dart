import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/models/track.dart';

void main() {
  group('Favorites Domain Tests', () {
    test('Track isFavorite defaults to false', () {
      final track = Track(
        id: 1,
        title: 'Song',
        durationMs: 120000,
        filePath: '/path/song.mp3',
        folderPath: '/path',
        fileHash: 'hash',
        dateAdded: DateTime.now(),
      );

      expect(track.isFavorite, isFalse);
    });

    test('Track copyWith toggles isFavorite properly', () {
      final track = Track(
        id: 1,
        title: 'Song',
        durationMs: 120000,
        filePath: '/path/song.mp3',
        folderPath: '/path',
        fileHash: 'hash',
        dateAdded: DateTime.now(),
      );

      final favorited = track.copyWith(isFavorite: true);
      expect(favorited.isFavorite, isTrue);

      final unfavorited = favorited.copyWith(isFavorite: false);
      expect(unfavorited.isFavorite, isFalse);
    });

    test('Track.fromMap parses is_favorite column correctly', () {
      final mapWithFav = {
        'id': 1,
        'title': 'Song',
        'duration_ms': 120000,
        'file_path': '/path/song.mp3',
        'folder_path': '/path',
        'file_hash': 'hash',
        'date_added': DateTime.now().millisecondsSinceEpoch,
        'is_favorite': 1,
      };

      final track = Track.fromMap(mapWithFav);
      expect(track.isFavorite, isTrue);
    });
  });
}
