import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/models/track.dart';
import 'package:spotlocal/features/player/models/player_state_model.dart';

void main() {
  group('SpotPlayerState Unit Tests', () {
    test('default state values should be initialized properly', () {
      const state = SpotPlayerState();

      expect(state.currentTrack, isNull);
      expect(state.mediaItem, isNull);
      expect(state.currentLyrics, isNull);
      expect(state.isPlaying, isFalse);
      expect(state.isBuffering, isFalse);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.bufferedPosition, Duration.zero);
      expect(state.queue, isEmpty);
      expect(state.currentIndex, isNull);
      expect(state.shuffleModeEnabled, isFalse);
      expect(state.repeatMode, AudioServiceRepeatMode.none);
      expect(state.speed, 1.0);
    });

    test('copyWith updates playback speed accurately', () {
      const state = SpotPlayerState();
      final speedState = state.copyWith(speed: 1.5);

      expect(speedState.speed, 1.5);
      expect(speedState.isPlaying, isFalse);

      final halfSpeedState = speedState.copyWith(speed: 0.5);
      expect(halfSpeedState.speed, 0.5);
    });

    test('copyWith updates lyrics and clearLyrics flag resets correctly', () {
      const state = SpotPlayerState();
      final withLyrics = state.copyWith(currentLyrics: 'Sample test lyrics');

      expect(withLyrics.currentLyrics, 'Sample test lyrics');

      final cleared = withLyrics.copyWith(clearLyrics: true);
      expect(cleared.currentLyrics, isNull);
    });

    test('queue and current track synchronization in state', () {
      final track = Track(
        id: 1,
        title: 'Song A',
        artist: 'Artist A',
        durationMs: 180000,
        filePath: '/music/a.mp3',
        folderPath: '/music',
        fileHash: 'hash1',
        dateAdded: DateTime.now(),
      );

      const state = SpotPlayerState();
      final updated = state.copyWith(
        queue: [track],
        currentTrack: track,
        currentIndex: 0,
        isPlaying: true,
      );

      expect(updated.queue.length, 1);
      expect(updated.currentTrack?.title, 'Song A');
      expect(updated.currentIndex, 0);
      expect(updated.isPlaying, isTrue);
    });
  });
}
