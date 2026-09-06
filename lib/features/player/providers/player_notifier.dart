import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/lyrics_service.dart';
import '../../../core/audio/spot_audio_handler.dart';
import '../../../core/models/track.dart';
import '../models/player_state_model.dart';

final audioHandlerProvider = Provider<SpotAudioHandler>((ref) => spotAudioHandler);

final playerStateProvider =
    StateNotifierProvider<PlayerNotifier, SpotPlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler);
});

class PlayerNotifier extends StateNotifier<SpotPlayerState> {
  final SpotAudioHandler _audioHandler;
  final List<StreamSubscription> _subscriptions = [];
  String? _lastLoadedLyricsPath;

  PlayerNotifier(this._audioHandler) : super(const SpotPlayerState()) {
    _initListeners();
  }

  void _initListeners() {
    // 1. Listen to mediaItem changes (updates title, artist, duration, artwork, active track, lyrics)
    _subscriptions.add(
      _audioHandler.mediaItem.listen((item) {
        if (item == null) return;

        // Find matching Track in current state queue or construct from MediaItem
        Track? track;
        final index = state.queue.indexWhere((t) => t.filePath == item.id);
        if (index != -1) {
          track = state.queue[index];
        } else {
          track = Track(
            title: item.title,
            artist: item.artist,
            album: item.album,
            durationMs: item.duration?.inMilliseconds ?? 0,
            filePath: item.id,
            folderPath: '',
            fileHash: (item.extras?['fileHash'] as String?) ?? '',
            artworkPath: item.artUri?.toFilePath(),
            dateAdded: DateTime.now(),
          );
        }

        state = state.copyWith(
          mediaItem: item,
          currentTrack: track,
          duration: item.duration ?? Duration.zero,
        );

        // Fetch embedded lyrics for the newly playing track
        _fetchTrackLyrics(item.id);
      }),
    );

    // 2. Listen to PlaybackState updates (playback controls, position, playing state)
    _subscriptions.add(
      _audioHandler.playbackState.listen((pbState) {
        state = state.copyWith(
          isPlaying: pbState.playing,
          isBuffering: pbState.processingState == AudioProcessingState.buffering,
          position: pbState.position,
          bufferedPosition: pbState.bufferedPosition,
          currentIndex: pbState.queueIndex,
          shuffleModeEnabled: pbState.shuffleMode == AudioServiceShuffleMode.all,
          repeatMode: pbState.repeatMode,
        );
      }),
    );

    // 3. Listen to queue updates
    _subscriptions.add(
      _audioHandler.queue.listen((mediaQueue) {
        final updatedQueue = mediaQueue.map((m) {
          final existingIndex = state.queue.indexWhere((t) => t.filePath == m.id);
          if (existingIndex != -1) {
            return state.queue[existingIndex];
          }
          return Track(
            title: m.title,
            artist: m.artist,
            album: m.album,
            durationMs: m.duration?.inMilliseconds ?? 0,
            filePath: m.id,
            folderPath: '',
            fileHash: (m.extras?['fileHash'] as String?) ?? '',
            artworkPath: m.artUri?.toFilePath(),
            dateAdded: DateTime.now(),
          );
        }).toList();

        state = state.copyWith(queue: updatedQueue);
      }),
    );

    // 4. Position stream listener for UI progress updates
    _subscriptions.add(
      _audioHandler.player.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );
  }

  /// Asynchronously extracts embedded ID3 USLT lyrics for the active track.
  Future<void> _fetchTrackLyrics(String filePath) async {
    if (filePath == _lastLoadedLyricsPath) return;
    _lastLoadedLyricsPath = filePath;

    state = state.copyWith(clearLyrics: true);
    final lyrics = await LyricsService.extractLyrics(filePath);

    // Ensure state matches current active track before setting
    if (state.currentTrack?.filePath == filePath) {
      state = state.copyWith(currentLyrics: lyrics);
    }
  }

  /// Plays a single track or plays it within a context queue.
  Future<void> playTrack(Track track, {List<Track>? contextQueue}) async {
    final queueToPlay = contextQueue ?? [track];
    final initialIndex = queueToPlay.indexWhere((t) => t.filePath == track.filePath);
    await playQueue(queueToPlay, initialIndex: initialIndex != -1 ? initialIndex : 0);
  }

  /// Plays a list of tracks starting at [initialIndex].
  Future<void> playQueue(List<Track> tracks, {int initialIndex = 0}) async {
    state = state.copyWith(queue: tracks);
    await _audioHandler.playTracks(tracks, initialIndex: initialIndex);
  }

  /// Resume playback.
  Future<void> play() async {
    await _audioHandler.play();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _audioHandler.pause();
  }

  /// Toggle play/pause state.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to specific position in track.
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  /// Skip to next track in queue.
  Future<void> skipToNext() async {
    await _audioHandler.skipToNext();
  }

  /// Skip to previous track in queue.
  Future<void> skipToPrevious() async {
    await _audioHandler.skipToPrevious();
  }

  /// Skip to a specific track index in queue.
  Future<void> skipToQueueItem(int index) async {
    await _audioHandler.skipToQueueItem(index);
  }

  /// Toggles shuffle mode on/off.
  Future<void> toggleShuffle() async {
    final nextMode = state.shuffleModeEnabled
        ? AudioServiceShuffleMode.none
        : AudioServiceShuffleMode.all;
    await _audioHandler.setShuffleMode(nextMode);
  }

  /// Cycles repeat mode: None -> Repeat All -> Repeat One -> None.
  Future<void> toggleRepeat() async {
    AudioServiceRepeatMode nextMode;
    switch (state.repeatMode) {
      case AudioServiceRepeatMode.none:
        nextMode = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        nextMode = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
        nextMode = AudioServiceRepeatMode.none;
        break;
    }
    await _audioHandler.setRepeatMode(nextMode);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
