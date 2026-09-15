import 'package:audio_service/audio_service.dart';
import '../../../core/models/track.dart';

class SpotPlayerState {
  final Track? currentTrack;
  final MediaItem? mediaItem;
  final String? currentLyrics;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final List<Track> queue;
  final int? currentIndex;
  final bool shuffleModeEnabled;
  final AudioServiceRepeatMode repeatMode;
  final double speed;

  const SpotPlayerState({
    this.currentTrack,
    this.mediaItem,
    this.currentLyrics,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.queue = const [],
    this.currentIndex,
    this.shuffleModeEnabled = false,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.speed = 1.0,
  });

  SpotPlayerState copyWith({
    Track? currentTrack,
    MediaItem? mediaItem,
    String? currentLyrics,
    bool clearLyrics = false,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    List<Track>? queue,
    int? currentIndex,
    bool? shuffleModeEnabled,
    AudioServiceRepeatMode? repeatMode,
    double? speed,
  }) {
    return SpotPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      mediaItem: mediaItem ?? this.mediaItem,
      currentLyrics: clearLyrics ? null : (currentLyrics ?? this.currentLyrics),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleModeEnabled: shuffleModeEnabled ?? this.shuffleModeEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
    );
  }
}
