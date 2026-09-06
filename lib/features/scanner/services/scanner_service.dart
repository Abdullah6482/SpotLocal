import 'dart:async';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/db_helper.dart';
import '../models/scan_result.dart';
import 'isolate_scanner.dart';

class ScannerService {
  final DbHelper _dbHelper;
  Isolate? _scannerIsolate;
  SendPort? _isolateSendPort;
  StreamController<ScanProgress>? _progressController;

  ScannerService({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper();

  /// Stream of scanning progress updates.
  Stream<ScanProgress> get progressStream =>
      _progressController?.stream ?? const Stream.empty();

  /// Scans specific directories or all enabled directories in SQLite `scan_folders`.
  Future<void> scanDirectories({List<String>? targetFolderPaths}) async {
    // 1. Fetch directories to scan
    List<String> folderPaths = targetFolderPaths ?? [];
    if (folderPaths.isEmpty) {
      final enabledFolders = await _dbHelper.getEnabledScanFolders();
      folderPaths = enabledFolders.map((f) => f.path).toList();
    }

    if (folderPaths.isEmpty) {
      _emitProgress(const ScanProgress(status: ScanStatus.completed));
      return;
    }

    // 2. Prepare progress stream controller
    _progressController?.close();
    _progressController = StreamController<ScanProgress>.broadcast();
    _emitProgress(const ScanProgress(status: ScanStatus.scanning));

    // 3. Resolve cache directory for saving extracted artwork JPEGs
    final cacheDir = await getApplicationCacheDirectory();

    // 4. Spawn background Dart Isolate
    final receivePort = ReceivePort();
    final List<ScanError> errors = [];
    int totalProcessed = 0;
    int totalFiles = 0;

    try {
      _scannerIsolate = await Isolate.spawn(
        IsolateScanner.entryPoint,
        receivePort.sendPort,
      );

      final Completer<void> scanCompleter = Completer<void>();

      receivePort.listen((message) async {
        if (message is SendPort) {
          _isolateSendPort = message;
          // Send scan request payload to isolate
          _isolateSendPort!.send(
            ScanRequest(
              folderPaths: folderPaths,
              artworkCacheDir: cacheDir.path,
            ),
          );
        } else if (message is ScanBatch) {
          totalFiles = message.totalCount;
          totalProcessed = message.processedCount;

          if (message.error != null) {
            errors.add(message.error!);
          }

          // Upsert batch of tracks (up to 50) into SQLite using database batch transaction
          if (message.tracks.isNotEmpty) {
            await _dbHelper.batchInsertTracks(message.tracks);
          }

          // Emit scanning progress
          _emitProgress(
            ScanProgress(
              status: ScanStatus.scanning,
              totalFilesFound: totalFiles,
              processedFiles: totalProcessed,
              currentFile: message.currentFilePath,
              errors: List.unmodifiable(errors),
            ),
          );

          // Check if scan finished
          if (totalProcessed >= totalFiles) {
            if (!scanCompleter.isCompleted) {
              scanCompleter.complete();
            }
          }
        }
      });

      await scanCompleter.future;

      _emitProgress(
        ScanProgress(
          status: ScanStatus.completed,
          totalFilesFound: totalFiles,
          processedFiles: totalProcessed,
          errors: List.unmodifiable(errors),
        ),
      );
    } catch (e) {
      errors.add(
        ScanError(
          filePath: 'General Scanner Failure',
          errorMessage: e.toString(),
        ),
      );
      _emitProgress(
        ScanProgress(
          status: ScanStatus.error,
          errors: List.unmodifiable(errors),
        ),
      );
    } finally {
      stopScan();
      receivePort.close();
    }
  }

  /// Broadcasts updated scan progress to subscribers.
  void _emitProgress(ScanProgress progress) {
    if (_progressController != null && !_progressController!.isClosed) {
      _progressController!.add(progress);
    }
  }

  /// Cancels any active background isolate scan operations.
  void stopScan() {
    _isolateSendPort?.send('stop');
    _scannerIsolate?.kill(priority: Isolate.immediate);
    _scannerIsolate = null;
    _isolateSendPort = null;
  }

  /// Clean up resources.
  void dispose() {
    stopScan();
    _progressController?.close();
  }
}

