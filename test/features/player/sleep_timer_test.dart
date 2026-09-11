import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/features/player/services/sleep_timer_service.dart';

void main() {
  group('SleepTimerService Tests', () {
    late SleepTimerService service;

    setUp(() {
      service = SleepTimerService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state should be inactive', () {
      final state = service.currentState;
      expect(state.isActive, isFalse);
      expect(state.remainingTime, isNull);
      expect(state.mode, isNull);
    });

    test('startTimer initiates countdown state', () {
      service.startTimer(const Duration(minutes: 15), () {});
      final state = service.currentState;

      expect(state.isActive, isTrue);
      expect(state.mode, SleepTimerMode.duration);
      expect(state.remainingTime?.inMinutes, 15);
    });

    test('cancelTimer resets state completely', () {
      service.startTimer(const Duration(minutes: 30), () {});
      expect(service.currentState.isActive, isTrue);

      service.cancelTimer();
      final state = service.currentState;

      expect(state.isActive, isFalse);
      expect(state.remainingTime, isNull);
      expect(state.mode, isNull);
    });

    test('setEndOfTrack activates end of track mode', () {
      bool completed = false;
      service.setEndOfTrack(() {
        completed = true;
      });

      expect(service.currentState.isActive, isTrue);
      expect(service.currentState.mode, SleepTimerMode.endOfTrack);

      service.notifyTrackFinished();

      expect(completed, isTrue);
      expect(service.currentState.isActive, isFalse);
    });
  });
}
