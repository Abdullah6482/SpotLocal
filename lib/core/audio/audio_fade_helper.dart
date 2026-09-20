import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioFadeHelper {
  /// Linearly interpolates volume level for a discrete step.
  static double calculateStepVolume(
    double startVolume,
    double endVolume,
    int currentStep,
    int totalSteps,
  ) {
    if (totalSteps <= 0) return endVolume;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    return startVolume + (endVolume - startVolume) * progress;
  }

  /// Gradually fades out player volume over [fadeDuration] then invokes [onComplete].
  static Future<void> fadeOut(
    AudioPlayer player, {
    Duration fadeDuration = const Duration(milliseconds: 250),
    int steps = 10,
    Future<void> Function()? onComplete,
  }) async {
    final startVolume = player.volume;
    if (startVolume <= 0.0) {
      if (onComplete != null) await onComplete();
      return;
    }

    final stepDuration = Duration(
      milliseconds: (fadeDuration.inMilliseconds / steps).round(),
    );

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final newVolume = calculateStepVolume(startVolume, 0.0, i, steps);
      await player.setVolume(newVolume);
    }

    if (onComplete != null) {
      await onComplete();
    }

    // Reset volume back to original for subsequent playback
    await player.setVolume(startVolume);
  }
}
