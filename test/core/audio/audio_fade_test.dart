import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/audio/audio_fade_helper.dart';

void main() {
  group('AudioFadeHelper Tests', () {
    test('calculateStepVolume produces accurate linear increments', () {
      // Step 0 of 4 (start)
      expect(AudioFadeHelper.calculateStepVolume(1.0, 0.0, 0, 4), 1.0);

      // Step 2 of 4 (midpoint)
      expect(AudioFadeHelper.calculateStepVolume(1.0, 0.0, 2, 4), 0.5);

      // Step 4 of 4 (end)
      expect(AudioFadeHelper.calculateStepVolume(1.0, 0.0, 4, 4), 0.0);
    });

    test('calculateStepVolume clamps values within range', () {
      expect(AudioFadeHelper.calculateStepVolume(0.0, 1.0, 5, 5), 1.0);
      expect(AudioFadeHelper.calculateStepVolume(0.0, 1.0, 10, 5), 1.0);
    });
  });
}
