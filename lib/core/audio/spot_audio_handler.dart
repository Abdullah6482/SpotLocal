import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

/// SpotAudioHandler wraps just_audio's [AudioPlayer] and exposes background controls
/// and notification state via [BaseAudioHandler].
class SpotAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlistSource;

  SpotAudioHandler() {
    _initStreams();
  }

  AudioPlayer get player => _player;

  /// Helper to convert a domain [Track] model to an [AudioService] [MediaItem].
  static MediaItem trackToMediaItem(Track track) {
    return MediaItem(
      id: track.filePath,
      album: track.album ?? 'Unknown Album',
      title: track.title,
      artist: track.artist ?? 'Unknown Artist',
      duration: Duration(milliseconds: track.durationMs),
      artUri: track.artworkPath != null && track.artworkPath!.isNotEmpty
          ? Uri.file(track.artworkPath!)
          : null,
      extras: {
        'trackId': track.id,
        'fileHash': track.fileHash,
        'folderPath': track.folderPath,
      },
    );
  }

  /// Listens to internal player streams and updates AudioService playbackState and mediaItem.
  void _initStreams() {
    // 1. Player state (playing, processing state)
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (isPlaying) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.setShuffleMode,
            MediaAction.setRepeatMode,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: _mapProcessingState(processingState),
          playing: isPlaying,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
          shuffleMode: _player.shuffleModeEnabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
          repeatMode: _mapLoopModeToRepeatMode(_player.loopMode),
        ),
      );
    });

    // 2. Position updates
    _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
        ),
      );
    });

    // 3. Current sequence index changes -> updates active mediaItem for lockscreen notification drawer
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 4. Shuffle mode stream sync
    _player.shuffleModeEnabledStream.listen((enabled) {
      playbackState.add(
        playbackState.value.copyWith(
          shuffleMode: enabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
        ),
      );
    });

    // 5. Loop mode stream sync
    _player.loopModeStream.listen((loopMode) {
      playbackState.add(
        playbackState.value.copyWith(
          repeatMode: _mapLoopModeToRepeatMode(loopMode),
        ),
      );
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  AudioServiceRepeatMode _mapLoopModeToRepeatMode(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enable = shuffleMode != AudioServiceShuffleMode.none;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  /// Sets a new queue of tracks and starts playback at [initialIndex].
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;

    final mediaItems = tracks.map((t) => trackToMediaItem(t)).toList();
    queue.add(mediaItems);

    _playlistSource = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: mediaItems
          .map((item) => AudioSource.uri(Uri.file(item.id)))
          .toList(),
    );

    final safeIndex = initialIndex.clamp(0, tracks.length - 1);
    mediaItem.add(mediaItems[safeIndex]);

    await _player.setAudioSource(_playlistSource!, initialIndex: safeIndex);
    await _player.play();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    await _player.setAudioSource(AudioSource.uri(Uri.file(mediaItem.id)));
    await _player.play();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final currentQueue = queue.value;
    final updatedQueue = [...currentQueue, mediaItem];
    queue.add(updatedQueue);
    await _playlistSource?.add(AudioSource.uri(Uri.file(mediaItem.id)));
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(queue);
    _playlistSource = ConcatenatingAudioSource(
      children: queue
          .map((item) => AudioSource.uri(Uri.file(item.id)))
          .toList(),
    );
    await _player.setAudioSource(_playlistSource!);
  }

  /// Clean up player resources on dispose.
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Global AudioHandler instance holder for application lifecycle.
late final SpotAudioHandler spotAudioHandler;

/// Initializer for AudioService singleton background handler.
Future<SpotAudioHandler> initAudioService() async {
  spotAudioHandler = await AudioService.init(
    builder: () => SpotAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.spotlocal.musicplayer.channel.audio',
      androidNotificationChannelName: 'SpotLocal Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  return spotAudioHandler;
}
