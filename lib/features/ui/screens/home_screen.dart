import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/track.dart';
import '../../player/providers/player_notifier.dart';
import '../../scanner/models/scan_result.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  List<Track> _allTracks = [];
  Map<String, List<Track>> _groupedAlbums = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTracks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTracks();
    }
  }

  Map<String, List<Track>> groupSongsByAlbum(List<Track> allSongs) {
    final Map<String, List<Track>> grouped = {};

    for (var song in allSongs) {
      final albumName = (song.album != null && song.album!.trim().isNotEmpty)
          ? song.album!.trim()
          : 'Unknown Album';
      if (!grouped.containsKey(albumName)) {
        grouped[albumName] = [];
      }
      grouped[albumName]!.add(song);
    }

    // Sort tracks within each album by track number
    for (var album in grouped.keys) {
      grouped[album]!.sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
    }

    return grouped;
  }

  Future<void> _loadTracks() async {
    final tracks = await DbHelper().getAllTracks();
    final grouped = groupSongsByAlbum(tracks);

    if (mounted) {
      setState(() {
        _allTracks = tracks;
        _groupedAlbums = grouped;
        _isLoading = false;
      });
    }
  }

  Widget _buildAlbumArtImage(String? path, double size) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackArtIcon(size),
          ),
        );
      }
    }
    return _buildFallbackArtIcon(size);
  }

  Widget _buildFallbackArtIcon(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final scannerState = ref.watch(scannerStateProvider);

    // Reload tracks whenever library version increments (e.g. scan complete, folder toggle/delete)
    ref.listen(libraryVersionProvider, (_, __) {
      _loadTracks();
    });

    // Reload tracks live as batches insert and when scanning completes or resets
    ref.listen(scannerStateProvider, (previous, next) {
      if (next.status == ScanStatus.completed ||
          next.status == ScanStatus.idle ||
          next.processedFiles > (previous?.processedFiles ?? 0)) {
        _loadTracks();
      }
    });

    final albumNames = _groupedAlbums.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadTracks,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : _allTracks.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off, color: AppColors.textSecondary, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'No Local Tracks Found',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Go to Your Library -> Manage Folders to select directories for audio scanning.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Manage Folders', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  await Navigator.of(context).pushNamed('/manage_folders');
                                  _loadTracks();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                    if (scannerState.status == ScanStatus.scanning)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Scanning Local Folders...',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${scannerState.processedFiles}/${scannerState.totalFilesFound}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: scannerState.progressPercentage,
                                backgroundColor: AppColors.surfaceLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Outer Vertical List for Albums
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final albumName = albumNames[index];
                          final albumSongs = _groupedAlbums[albumName] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Album Title Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Text(
                                  albumName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1DB954), // SpotLocal green brand color
                                  ),
                                ),
                              ),

                              // Horizontal Scrolling Cards
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  itemCount: albumSongs.length,
                                  itemBuilder: (context, trackIndex) {
                                    final song = albumSongs[trackIndex];
                                    final isPlaying =
                                        playerState.currentTrack?.filePath == song.filePath;

                                    return GestureDetector(
                                      onTap: () {
                                        ref.read(playerStateProvider.notifier).playTrack(
                                              song,
                                              contextQueue: albumSongs,
                                            );
                                      },
                                      child: Container(
                                        width: 130,
                                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Album Art Square
                                            Stack(
                                              children: [
                                                _buildAlbumArtImage(song.artworkPath, 130),
                                                if (isPlaying)
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.equalizer,
                                                          color: AppColors.accent,
                                                          size: 32,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Track Title
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isPlaying
                                                    ? const Color(0xFF1DB954)
                                                    : Colors.white,
                                              ),
                                            ),

                                            // Artist Name
                                            Text(
                                              song.artist ?? 'Unknown Artist',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                        childCount: albumNames.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
      ),
    );
  }
}
