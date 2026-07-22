import 'dart:async';

import '../data/firebase_data_repository.dart';
import '../data/shinguard_ble_service.dart';

class SessionRecordingService {
  SessionRecordingService({
    ShinGuardBleService? ble,
    FirebaseDataRepository? repository,
  }) : _ble = ble ?? ShinGuardBleService.instance,
       _repository = repository ?? FirebaseDataRepository() {
    _telemetrySubscription = _ble.telemetry.listen(_handleTelemetry);
    _connectionSubscription = _ble.states.listen(_handleConnectionState);
  }

  static final SessionRecordingService instance = SessionRecordingService();

  final ShinGuardBleService _ble;
  final FirebaseDataRepository _repository;
  final _stateController = StreamController<SessionRecordingState>.broadcast();

  late final StreamSubscription<Map<String, dynamic>> _telemetrySubscription;
  late final StreamSubscription<ShinGuardBleState> _connectionSubscription;
  Timer? _timer;
  DateTime? _startedAt;
  String _position = '';
  int _sprints = 0;
  final List<Duration> _sprintEvents = [];
  bool _isFinishing = false;

  SessionRecordingState _state = const SessionRecordingState(
    status: SessionRecordingStatus.idle,
    elapsed: Duration.zero,
    sprints: 0,
    message: 'Ready to record BNO motion data.',
  );

  Stream<SessionRecordingState> get states => _stateController.stream;
  SessionRecordingState get currentState => _state;
  bool get hasUnsavedSession => _startedAt != null;

  Future<void> dispose() async {
    _timer?.cancel();
    await _telemetrySubscription.cancel();
    await _connectionSubscription.cancel();
    await _stateController.close();
  }

  Future<void> startSession({required String position}) async {
    if (_state.status == SessionRecordingStatus.recording ||
        _state.status == SessionRecordingStatus.starting ||
        _state.status == SessionRecordingStatus.saving) {
      return;
    }
    if (!_ble.isConnected) {
      _emit(
        const SessionRecordingState(
          status: SessionRecordingStatus.error,
          elapsed: Duration.zero,
          sprints: 0,
          message: 'Connect your ShinGuard before starting a session.',
        ),
      );
      return;
    }

    _emit(
      const SessionRecordingState(
        status: SessionRecordingStatus.starting,
        elapsed: Duration.zero,
        sprints: 0,
        message: 'Starting sensor recording...',
      ),
    );
    try {
      await _ble.startSession();
      _startedAt = DateTime.now();
      _position = position;
      _sprints = 0;
      _sprintEvents.clear();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _emit(
        const SessionRecordingState(
          status: SessionRecordingStatus.recording,
          elapsed: Duration.zero,
          sprints: 0,
          message: 'BNO motion recording is active.',
        ),
      );
    } catch (error) {
      _emitError(error);
    }
  }

  Future<void> stopSession() async {
    if (_state.status != SessionRecordingStatus.recording || _isFinishing) {
      return;
    }
    await _finish(sendStopCommand: true);
  }

  Future<void> retrySave() async {
    if (_state.status != SessionRecordingStatus.error ||
        !hasUnsavedSession ||
        _isFinishing) {
      return;
    }
    await _finish(sendStopCommand: _ble.isConnected);
  }

  void _handleTelemetry(Map<String, dynamic> telemetry) {
    if (_state.status != SessionRecordingStatus.recording) return;

    final count = sprintCountFromTelemetry(telemetry, _sprints);
    if (count > _sprints) {
      final elapsed = _elapsed;
      for (var index = _sprints; index < count; index++) {
        _sprintEvents.add(elapsed);
      }
      _sprints = count;
      _emitRecording();
      return;
    }
  }

  void _handleConnectionState(ShinGuardBleState state) {
    if (_state.status == SessionRecordingStatus.recording &&
        state.status == ShinGuardBleStatus.idle &&
        !_isFinishing) {
      unawaited(_finish(sendStopCommand: false));
    }
  }

  Future<void> _finish({required bool sendStopCommand}) async {
    _isFinishing = true;
    _timer?.cancel();
    final startedAt = _startedAt;
    final duration = _elapsed;
    _emit(
      SessionRecordingState(
        status: SessionRecordingStatus.saving,
        elapsed: duration,
        sprints: _sprints,
        message: 'Saving session statistics...',
      ),
    );

    try {
      if (sendStopCommand) await _ble.stopSession();
      if (startedAt == null) throw StateError('Session start time is missing.');
      await _repository.saveRecordedSession(
        startedAt: startedAt,
        duration: duration,
        position: _position,
        sprints: _sprints,
        sprintEvents: List<Duration>.from(_sprintEvents),
      );
      _startedAt = null;
      _emit(
        SessionRecordingState(
          status: SessionRecordingStatus.idle,
          elapsed: duration,
          sprints: _sprints,
          message: 'Session saved with $_sprints sprints.',
        ),
      );
    } catch (error) {
      _emitError(error, elapsed: duration, sprints: _sprints);
    } finally {
      _isFinishing = false;
    }
  }

  Duration get _elapsed {
    final startedAt = _startedAt;
    return startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
  }

  void _tick() => _emitRecording();

  void _emitRecording() {
    _emit(
      SessionRecordingState(
        status: SessionRecordingStatus.recording,
        elapsed: _elapsed,
        sprints: _sprints,
        message: 'BNO motion recording is active.',
      ),
    );
  }

  void _emitError(
    Object error, {
    Duration elapsed = Duration.zero,
    int sprints = 0,
  }) {
    _timer?.cancel();
    final message = error is StateError
        ? error.message
        : 'Unable to complete the session. Please try again.';
    _emit(
      SessionRecordingState(
        status: SessionRecordingStatus.error,
        elapsed: elapsed,
        sprints: sprints,
        message: message.toString(),
      ),
    );
  }

  void _emit(SessionRecordingState state) {
    _state = state;
    _stateController.add(state);
  }
}

int sprintCountFromTelemetry(Map<String, dynamic> telemetry, int currentCount) {
  final countValue =
      telemetry['sc'] ?? telemetry['sprint_count'] ?? telemetry['sprints'];
  if (countValue != null) {
    final hardwareCount = countValue is num
        ? countValue.toInt()
        : int.tryParse('$countValue') ?? currentCount;
    return hardwareCount > currentCount ? hardwareCount : currentCount;
  }
  final eventValue = telemetry['sp'] ?? telemetry['sprint'];
  final sprintEvent =
      eventValue == true ||
      (eventValue is num && eventValue != 0) ||
      eventValue == '1';
  return sprintEvent ? currentCount + 1 : currentCount;
}

enum SessionRecordingStatus { idle, starting, recording, saving, error }

class SessionRecordingState {
  const SessionRecordingState({
    required this.status,
    required this.elapsed,
    required this.sprints,
    required this.message,
  });

  final SessionRecordingStatus status;
  final Duration elapsed;
  final int sprints;
  final String message;

  bool get isRecording => status == SessionRecordingStatus.recording;
  bool get isBusy =>
      status == SessionRecordingStatus.starting ||
      status == SessionRecordingStatus.saving;
}
