import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/db_helper.dart';
import '../../../core/models/track.dart';
import '../models/scan_result.dart';
import '../utils/audio_file_validator.dart';

class IsolateScanner {
  static Set<String> get _allowedExtensions => AudioFileValidator.supportedExtensions;

  /// Entry point executed inside the spawned background Dart Isolate.
  @pragma('vm:entry-point')
  static Future<void> entryPoint(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    try {
      MetadataGod.initialize();
    } catch (e) {
      // Ignore metadata_god initialization failure to allow fallback scanning
    }

    await for (final message in receivePort) {
      if (message is ScanRequest) {
        await _processScanRequest(message, sendPort);
      } else if (message == 'stop') {
        break;
      }
    }

    receivePort.close();
  }

  static Future<void> _processScanRequest(
    ScanRequest request,
    SendPort sendPort,
  ) async {
    final List<File> audioFiles = [];
    final List<ScanError> errors = [];

    // 1. First pass: Collect all matching audio files across all directories
    for (final rawFolderPath in request.folderPaths) {
      final folderPath = normalizeFolderPath(rawFolderPath);
      try {
        final dir = Directory(folderPath);
        if (await dir.exists()) {
          _collectAudioFiles(dir, audioFiles, errors);
        } else {
          errors.add(
            ScanError(
              filePath: folderPath,
              errorMessage: 'Directory unreadable or does not exist: $folderPath',
            ),
          );
        }
      } catch (e) {
        errors.add(
          ScanError(
            filePath: folderPath,
            errorMessage: 'Error opening folder: $e',
          ),
        );
      }
    }

    final totalCount = audioFiles.length;
    if (totalCount == 0) {
      sendPort.send(
        ScanBatch(
          tracks: const [],
          processedCount: 0,
          totalCount: 0,
          error: errors.isNotEmpty ? errors.first : null,
        ),
      );
      return;
    }

    // Ensure artwork cache directory exists
    final artworkDir = Directory(p.join(request.artworkCacheDir, 'artworks'));
    if (!await artworkDir.exists()) {
      try {
        await artworkDir.create(recursive: true);
      } catch (_) {}
    }

    List<Track> currentBatch = [];
    int processedCount = 0;

    // 2. Second pass: Parse metadata and build Track objects
    for (final file in audioFiles) {
      processedCount++;
      Track? parsedTrack;
      ScanError? fileError;

      try {
        parsedTrack = await _parseAudioFile(
          file: file,
          artworkDir: artworkDir,
        );
      } catch (e) {
        fileError = ScanError(
          filePath: file.path,
          errorMessage: 'Fallback parser used: $e',
        );

        // Fallback: create basic track record using file system metadata
        try {
          final stat = file.statSync();
          final fileName = p.basenameWithoutExtension(file.path);
          final fileHash = md5
              .convert(utf8.encode(
                  '${file.path}_${stat.modified.millisecondsSinceEpoch}_${stat.size}'))
              .toString();

          parsedTrack = Track(
            title: fileName,
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            durationMs: 0,
            filePath: file.path,
            folderPath: normalizeFolderPath(p.dirname(file.path)),
            fileHash: fileHash,
            artworkPath: null,
            dateAdded: stat.modified,
          );
        } catch (_) {
          // Complete failure for this file
        }
      }

      if (parsedTrack != null) {
        currentBatch.add(parsedTrack);
      }

      // Batch size limit: 50 items
      if (currentBatch.length >= 50) {
        sendPort.send(
          ScanBatch(
            tracks: List.from(currentBatch),
            processedCount: processedCount,
            totalCount: totalCount,
            currentFilePath: file.path,
            error: fileError,
          ),
        );
        currentBatch.clear();
      } else if (fileError != null) {
        sendPort.send(
          ScanBatch(
            tracks: const [],
            processedCount: processedCount,
            totalCount: totalCount,
            currentFilePath: file.path,
            error: fileError,
          ),
        );
      }
    }

    // Flush remaining tracks in final batch
    if (currentBatch.isNotEmpty) {
      sendPort.send(
        ScanBatch(
          tracks: List.from(currentBatch),
          processedCount: processedCount,
          totalCount: totalCount,
        ),
      );
      currentBatch.clear();
    }
  }

  /// Recursively collects audio files safely without crashing on subfolder permission errors.
  static void _collectAudioFiles(
    Directory dir,
    List<File> audioFiles,
    List<ScanError> errors,
  ) {
    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_allowedExtensions.contains(ext)) {
            audioFiles.add(entity);
          }
        } else if (entity is Directory) {
          _collectAudioFiles(entity, audioFiles, errors);
        }
      }
    } catch (e) {
      errors.add(
        ScanError(
          filePath: dir.path,
          errorMessage: 'Permission failure: $e',
        ),
      );
    }
  }

  /// Parses metadata and extracts embedded artwork for an audio file.
  static Future<Track> _parseAudioFile({
    required File file,
    required Directory artworkDir,
  }) async {
    final stat = file.statSync();
    final fileHash = md5
        .convert(utf8.encode(
            '${file.path}_${stat.modified.millisecondsSinceEpoch}_${stat.size}'))
        .toString();

    String title = AudioFileValidator.deriveFallbackTitle(file.path);
    String? artist;
    String? album;
    int? trackNumber;
    int durationMs = 0;
    String? artworkPath;

    try {
      final metadata = await MetadataGod.readMetadata(file: file.path);

      if (metadata.title != null && metadata.title!.trim().isNotEmpty) {
        title = metadata.title!.trim();
      }
      if (metadata.artist != null && metadata.artist!.trim().isNotEmpty) {
        artist = metadata.artist!.trim();
      }
      if (metadata.album != null && metadata.album!.trim().isNotEmpty) {
        album = metadata.album!.trim();
      }
      if (metadata.trackNumber != null) {
        trackNumber = metadata.trackNumber;
      }
      if (metadata.durationMs != null) {
        durationMs = metadata.durationMs!.toInt();
      }

      // Extract embedded picture/artwork if present
      if (metadata.picture != null && metadata.picture!.data.isNotEmpty) {
        try {
          final artHash = md5.convert(metadata.picture!.data).toString();
          final artFile = File(p.join(artworkDir.path, 'art_$artHash.jpg'));
          if (!await artFile.exists()) {
            await artFile.writeAsBytes(metadata.picture!.data, flush: true);
          }
          artworkPath = artFile.path;
        } catch (_) {
          // Ignore artwork extraction error to allow track import
        }
      }
    } catch (e) {
      // Fallback values
    }

    return Track(
      title: title,
      artist: artist ?? 'Unknown Artist',
      album: album ?? 'Unknown Album',
      trackNumber: trackNumber,
      durationMs: durationMs,
      filePath: file.path,
      folderPath: normalizeFolderPath(p.dirname(file.path)),
      fileHash: fileHash,
      artworkPath: artworkPath,
      dateAdded: stat.modified,
    );
  }
}
