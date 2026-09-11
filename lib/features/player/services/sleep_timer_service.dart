import 'dart:async';

enum SleepTimerMode {
  duration,
  endOfTrack,
}

class SleepTimerState {
  final bool isActive;
  final Duration? remainingTime;
  final SleepTimerMode? mode;

  const SleepTimerState({
    this.isActive = false,
    this.remainingTime,
    this.mode,
  });

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remainingTime,
    SleepTimerMode? mode,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
      mode: mode ?? this.mode,
    );
  }
}

class SleepTimerService {
  Timer? _countdownTimer;
  Duration? _remaining;
  SleepTimerMode? _currentMode;
  void Function()? _onTimerFinished;

  final _stateController = StreamController<SleepTimerState>.broadcast();
  Stream<SleepTimerState> get stateStream => _stateController.stream;

  SleepTimerState get currentState => SleepTimerState(
        isActive: _countdownTimer != null || _currentMode == SleepTimerMode.endOfTrack,
        remainingTime: _remaining,
        mode: _currentMode,
      );

  /// Starts a countdown timer for the specified duration.
  void startTimer(Duration duration, void Function() onFinish) {
    cancelTimer();
    _remaining = duration;
    _currentMode = SleepTimerMode.duration;
    _onTimerFinished = onFinish;

    _emitState();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining == null || _remaining!.inSeconds <= 1) {
        _handleCompletion();
      } else {
        _remaining = _remaining! - const Duration(seconds: 1);
        _emitState();
      }
    });
  }

  /// Sets the timer to trigger when the current audio track completes.
  void setEndOfTrack(void Function() onFinish) {
    cancelTimer();
    _currentMode = SleepTimerMode.endOfTrack;
    _remaining = null;
    _onTimerFinished = onFinish;
    _emitState();
  }

  /// Called when audio handler reports track completion.
  void notifyTrackFinished() {
    if (_currentMode == SleepTimerMode.endOfTrack) {
      _handleCompletion();
    }
  }

  void _handleCompletion() {
    final callback = _onTimerFinished;
    cancelTimer();
    callback?.call();
  }

  /// Cancels any active sleep timer.
  void cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remaining = null;
    _currentMode = null;
    _onTimerFinished = null;
    _emitState();
  }

  void _emitState() {
    _stateController.add(currentState);
  }

  void dispose() {
    cancelTimer();
    _stateController.close();
  }
}
