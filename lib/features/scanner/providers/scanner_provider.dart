import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/scanner_service.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  final service = ScannerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final libraryVersionProvider = StateProvider<int>((ref) => 0);

final scannerStateProvider =
    StateNotifierProvider<ScannerNotifier, ScanProgress>((ref) {
  final service = ref.watch(scannerServiceProvider);
  return ScannerNotifier(service, ref);
});

class ScannerNotifier extends StateNotifier<ScanProgress> {
  final ScannerService _scannerService;
  final Ref _ref;
  StreamSubscription<ScanProgress>? _subscription;

  ScannerNotifier(this._scannerService, this._ref)
      : super(const ScanProgress(status: ScanStatus.idle)) {
    _subscription = _scannerService.progressStream.listen((progress) {
      state = progress;
      if (progress.status == ScanStatus.completed) {
        _ref.read(libraryVersionProvider.notifier).state++;
      }
    });
  }

  /// Starts scanning configured folders or explicit folder paths.
  Future<void> startScan({List<String>? targetFolderPaths}) async {
    await _scannerService.scanDirectories(targetFolderPaths: targetFolderPaths);
  }

  /// Stops current scan operation.
  void stopScan() {
    _scannerService.stopScan();
    state = state.copyWith(status: ScanStatus.idle);
    _ref.read(libraryVersionProvider.notifier).state++;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

