import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/track.dart';
import '../theme/app_theme.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const TrackListTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    required this.onTap,
    this.onMoreTap,
  });

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildArtwork() {
    if (track.artworkPath != null && track.artworkPath!.isNotEmpty) {
      final file = File(track.artworkPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: _buildArtwork(),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? AppColors.accent : AppColors.textPrimary,
          fontSize: 15,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${track.artist ?? "Unknown Artist"} • ${track.album ?? "Unknown Album"}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.durationMs),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (onMoreTap != null)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
              onPressed: onMoreTap,
            ),
        ],
      ),
    );
  }
}

