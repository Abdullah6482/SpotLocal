import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/features/scanner/utils/audio_file_validator.dart';

void main() {
  group('AudioFileValidator Tests', () {
    test('recognizes standard audio formats', () {
      expect(AudioFileValidator.hasSupportedExtension('/path/song.mp3'), isTrue);
      expect(AudioFileValidator.hasSupportedExtension('/path/song.flac'), isTrue);
      expect(AudioFileValidator.hasSupportedExtension('/path/song.m4a'), isTrue);
      expect(AudioFileValidator.hasSupportedExtension('/path/song.wav'), isTrue);
      expect(AudioFileValidator.hasSupportedExtension('/path/song.aac'), isTrue);
      expect(AudioFileValidator.hasSupportedExtension('/path/song.ogg'), isTrue);
    });

    test('rejects non-audio formats', () {
      expect(AudioFileValidator.hasSupportedExtension('/path/doc.pdf'), isFalse);
      expect(AudioFileValidator.hasSupportedExtension('/path/image.png'), isFalse);
      expect(AudioFileValidator.hasSupportedExtension('/path/video.mp4'), isFalse);
    });

    test('deriveFallbackTitle sanitizes filenames effectively', () {
      // Strips leading track numbers
      expect(
        AudioFileValidator.deriveFallbackTitle('/music/01 - Bohemian Rhapsody.mp3'),
        'Bohemian Rhapsody',
      );
      expect(
        AudioFileValidator.deriveFallbackTitle('/music/12. Hotel California.flac'),
        'Hotel California',
      );

      // Replaces underscores with spaces
      expect(
        AudioFileValidator.deriveFallbackTitle('/music/stairway_to_heaven.m4a'),
        'stairway to heaven',
      );
    });
  });
}
