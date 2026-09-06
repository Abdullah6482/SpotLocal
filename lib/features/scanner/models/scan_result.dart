import '../../../core/models/track.dart';

enum ScanStatus { idle, scanning, completed, error }

class ScanError {
  final String filePath;
  final String errorMessage;
  final DateTime timestamp;

  ScanError({
    required this.filePath,
    required this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ScanProgress {
  final ScanStatus status;
  final int totalFilesFound;
  final int processedFiles;
  final String? currentFile;
  final List<ScanError> errors;

  const ScanProgress({
    required this.status,
    this.totalFilesFound = 0,
    this.processedFiles = 0,
    this.currentFile,
    this.errors = const [],
  });

  double get progressPercentage =>
      totalFilesFound > 0 ? (processedFiles / totalFilesFound).clamp(0.0, 1.0) : 0.0;

  ScanProgress copyWith({
    ScanStatus? status,
    int? totalFilesFound,
    int? processedFiles,
    String? currentFile,
    List<ScanError>? errors,
  }) {
    return ScanProgress(
      status: status ?? this.status,
      totalFilesFound: totalFilesFound ?? this.totalFilesFound,
      processedFiles: processedFiles ?? this.processedFiles,
      currentFile: currentFile ?? this.currentFile,
      errors: errors ?? this.errors,
    );
  }
}

class ScanBatch {
  final List<Track> tracks;
  final int processedCount;
  final int totalCount;
  final String? currentFilePath;
  final ScanError? error;

  const ScanBatch({
    required this.tracks,
    required this.processedCount,
    required this.totalCount,
    this.currentFilePath,
    this.error,
  });
}

class ScanRequest {
  final List<String> folderPaths;
  final String artworkCacheDir;

  const ScanRequest({
    required this.folderPaths,
    required this.artworkCacheDir,
  });
}

