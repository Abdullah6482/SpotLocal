import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sleep_timer_service.dart';
import 'player_notifier.dart';

final sleepTimerServiceProvider = Provider<SleepTimerService>((ref) {
  final service = SleepTimerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  final service = ref.watch(sleepTimerServiceProvider);
  final playerNotifier = ref.watch(playerStateProvider.notifier);
  return SleepTimerNotifier(service, playerNotifier);
});

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final SleepTimerService _service;
  final PlayerNotifier _playerNotifier;

  SleepTimerNotifier(this._service, this._playerNotifier)
      : super(_service.currentState) {
    _service.stateStream.listen((state) {
      this.state = state;
    });
  }

  void startMinutes(int minutes) {
    _service.startTimer(Duration(minutes: minutes), () {
      _playerNotifier.pause();
    });
  }

  void setEndOfTrack() {
    _service.setEndOfTrack(() {
      _playerNotifier.pause();
    });
  }

  void cancel() {
    _service.cancelTimer();
  }
}
