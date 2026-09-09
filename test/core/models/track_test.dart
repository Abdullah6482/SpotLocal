import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/models/track.dart';

void main() {
  group('Track Model Tests', () {
    final testDate = DateTime(2026, 9, 1, 12, 0, 0);

    final sampleTrack = Track(
      id: 1,
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      trackNumber: 2,
      durationMs: 243000,
      filePath: '/storage/emulated/0/Music/Midnight City.mp3',
      folderPath: '/storage/emulated/0/Music',
      fileHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      artworkPath: '/data/user/0/com.spotlocal/app_flutter/artworks/art_1.jpg',
      dateAdded: testDate,
    );

    test('should correctly serialize to Map', () {
      final map = sampleTrack.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Midnight City');
      expect(map['artist'], 'M83');
      expect(map['album'], 'Hurry Up, We\'re Dreaming');
      expect(map['track_number'], 2);
      expect(map['duration_ms'], 243000);
      expect(map['file_path'], '/storage/emulated/0/Music/Midnight City.mp3');
      expect(map['folder_path'], '/storage/emulated/0/Music');
      expect(map['file_hash'], 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(map['artwork_path'], '/data/user/0/com.spotlocal/app_flutter/artworks/art_1.jpg');
      expect(map['date_added'], testDate.millisecondsSinceEpoch);
    });

    test('should correctly deserialize from Map', () {
      final map = {
        'id': 2,
        'title': 'Starboy',
        'artist': 'The Weeknd',
        'album': 'Starboy',
        'track_number': 1,
        'duration_ms': 230000,
        'file_path': '/storage/emulated/0/Music/Starboy.mp3',
        'folder_path': '/storage/emulated/0/Music',
        'file_hash': 'abc123hash',
        'artwork_path': null,
        'date_added': testDate.millisecondsSinceEpoch,
      };

      final track = Track.fromMap(map);

      expect(track.id, 2);
      expect(track.title, 'Starboy');
      expect(track.artist, 'The Weeknd');
      expect(track.album, 'Starboy');
      expect(track.trackNumber, 1);
      expect(track.durationMs, 230000);
      expect(track.filePath, '/storage/emulated/0/Music/Starboy.mp3');
      expect(track.artworkPath, isNull);
      expect(track.dateAdded, testDate);
    });

    test('copyWith should override specified fields and preserve others', () {
      final updated = sampleTrack.copyWith(
        title: 'Midnight City (Remix)',
        durationMs: 250000,
      );

      expect(updated.id, sampleTrack.id);
      expect(updated.title, 'Midnight City (Remix)');
      expect(updated.durationMs, 250000);
      expect(updated.artist, sampleTrack.artist);
      expect(updated.filePath, sampleTrack.filePath);
    });

    test('equality and hashcode comparison', () {
      final duplicateTrack = Track(
        id: 1,
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        trackNumber: 2,
        durationMs: 243000,
        filePath: '/storage/emulated/0/Music/Midnight City.mp3',
        folderPath: '/storage/emulated/0/Music',
        fileHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        dateAdded: testDate,
      );

      expect(sampleTrack == duplicateTrack, isTrue);
      expect(sampleTrack.hashCode, equals(duplicateTrack.hashCode));
    });
  });
}
