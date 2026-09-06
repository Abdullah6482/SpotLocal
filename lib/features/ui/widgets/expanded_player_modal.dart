import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../core/models/track.dart';
import '../../player/providers/player_notifier.dart';
import '../theme/app_theme.dart';

class ExpandedPlayerModal extends ConsumerStatefulWidget {
  const ExpandedPlayerModal({super.key});

  @override
  ConsumerState<ExpandedPlayerModal> createState() => _ExpandedPlayerModalState();
}

class _ExpandedPlayerModalState extends ConsumerState<ExpandedPlayerModal> {
  double? _dragValue;

  // Dynamic Theme Colors
  Color _topColor = const Color(0xFF121212);
  Color _bottomColor = Colors.black;
  String? _lastArtworkPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final track = ref.read(playerStateProvider).currentTrack;
    if (track == null || track.artworkPath == _lastArtworkPath) return;

    _lastArtworkPath = track.artworkPath;

    if (track.artworkPath == null || track.artworkPath!.isEmpty) {
      if (mounted) {
        setState(() {
          _topColor = const Color(0xFF121212);
          _bottomColor = Colors.black;
        });
      }
      return;
    }

    final file = File(track.artworkPath!);
    if (!file.existsSync()) return;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(file),
        maximumColorCount: 16,
      );

      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          const Color(0xFF121212);

      final secondary = palette.mutedColor?.color ??
          palette.darkVibrantColor?.color ??
          Colors.black;

      if (mounted) {
        setState(() {
          _topColor = dominant;
          _bottomColor = secondary;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _topColor = const Color(0xFF121212);
          _bottomColor = Colors.black;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildArtwork(String? path, double size) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(size),
          ),
        );
      }
    }
    return _buildPlaceholder(size);
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.textSecondary,
        size: size * 0.4,
      ),
    );
  }

  void _showLyricsModalSheet(BuildContext context, Track track, String? lyrics) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final hasLyrics = lyrics != null && lyrics.trim().isNotEmpty;

            return Container(
              decoration: BoxDecoration(
                color: _bottomColor.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle Bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lyrics Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist ?? 'Unknown Artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lyrics, color: AppColors.accent, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // Lyrics Body
                  Expanded(
                    child: hasLyrics
                        ? SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Text(
                              lyrics,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.lyrics_outlined,
                                    size: 56,
                                    color: Colors.white30,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No lyrics embedded in this file.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTrackOptionsMenu(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _buildArtwork(track.artworkPath, 48),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${track.artist ?? "Unknown Artist"} • ${track.album ?? "Unknown Album"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const Divider(color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textPrimary),
                  title: const Text('Track Details & Info', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showTrackDetailsDialog(context, track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.textPrimary),
                  title: const Text('File Location', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    track.filePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackDetailsDialog(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            track.title,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Artist', track.artist ?? 'Unknown Artist'),
              _detailRow('Album', track.album ?? 'Unknown Album'),
              _detailRow('Duration', _formatDuration(Duration(milliseconds: track.durationMs))),
              _detailRow('File Path', track.filePath),
              _detailRow('Folder', track.folderPath),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final track = playerState.currentTrack;
    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = screenWidth * 0.78;

    // Trigger dynamic palette update on track change
    if (track != null && track.artworkPath != _lastArtworkPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePalette();
      });
    }

    if (track == null) {
      return Container(
        height: MediaQuery.of(context).size.height,
        color: AppColors.background,
        child: const Center(
          child: Text('No Track Selected', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final durationMs = playerState.duration.inMilliseconds.toDouble();
    final positionMs = playerState.position.inMilliseconds.toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: _bottomColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _topColor.withValues(alpha: 0.85),
            _bottomColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      const Text(
                        'PLAYING FROM YOUR LIBRARY',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.album ?? 'SpotLocal Player',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showTrackOptionsMenu(context, track),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 2. Large Album Artwork
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildArtwork(track.artworkPath, artworkSize),
              ),
            ),

            const Spacer(),

            // 3. Track Title & Artist Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist ?? 'Unknown Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lyrics Button
                      IconButton(
                        icon: Icon(
                          Icons.lyrics_outlined,
                          color: (playerState.currentLyrics != null &&
                                  playerState.currentLyrics!.trim().isNotEmpty)
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 26,
                        ),
                        onPressed: () => _showLyricsModalSheet(
                          context,
                          track,
                          playerState.currentLyrics,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 26),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Scrubber Slider & Progress Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: Theme.of(context).sliderTheme.copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.textPrimary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.textPrimary,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: durationMs > 0 ? durationMs : 1.0,
                      value: (_dragValue ?? positionMs).clamp(0.0, durationMs > 0 ? durationMs : 1.0),
                      onChanged: (val) {
                        setState(() {
                          _dragValue = val;
                        });
                      },
                      onChangeEnd: (val) {
                        ref.read(playerStateProvider.notifier).seek(Duration(milliseconds: val.toInt()));
                        setState(() {
                          _dragValue = null;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(Duration(milliseconds: (_dragValue ?? positionMs).toInt())),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(playerState.duration),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. Media Control Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playerState.shuffleModeEnabled ? AppColors.accent : AppColors.textSecondary,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(playerStateProvider.notifier).toggleShuffle();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: AppColors.textPrimary, size: 38),
                    onPressed: () {
                      ref.read(playerStateProvider.notifier).skipToPrevious();
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(playerStateProvider.notifier).togglePlayPause();
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 38,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: AppColors.textPrimary, size: 38),
                    onPressed: () {
                      ref.read(playerStateProvider.notifier).skipToNext();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      playerState.repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: playerState.repeatMode != AudioServiceRepeatMode.none
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(playerStateProvider.notifier).toggleRepeat();
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
