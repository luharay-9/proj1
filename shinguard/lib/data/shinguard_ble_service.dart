import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/imu_sample.dart';

class ShinGuardBleService {
  ShinGuardBleService._();

  static final ShinGuardBleService instance = ShinGuardBleService._();

  static final Guid serviceUuid = Guid('4f3d0001-6847-4f1f-b4a8-5f12f735d201');
  static final Guid telemetryUuid = Guid(
    '4f3d0002-6847-4f1f-b4a8-5f12f735d201',
  );
  static final Guid controlUuid = Guid('4f3d0003-6847-4f1f-b4a8-5f12f735d201');

  final _stateController = StreamController<ShinGuardBleState>.broadcast();
  final _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _imuController = StreamController<ImuSample>.broadcast();
  final _imuFrames = ImuFrameAccumulator();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _telemetrySubscription;
  int _connectionAttempt = 0;

  static const _adapterTimeout = Duration(seconds: 10);
  static const _scanTimeout = Duration(seconds: 12);
  static const _connectTimeout = Duration(seconds: 12);
  static const _discoveryTimeout = Duration(seconds: 10);

  Stream<ShinGuardBleState> get states => _stateController.stream;
  Stream<Map<String, dynamic>> get telemetry => _telemetryController.stream;
  Stream<ImuSample> get imuSamples => _imuController.stream;

  ShinGuardBleState _state = const ShinGuardBleState(
    status: ShinGuardBleStatus.idle,
    message: 'No device connected',
  );

  ShinGuardBleState get currentState => _state;
  bool get isConnected => _state.status == ShinGuardBleStatus.connected;

  Future<void> startSession() async {
    _imuFrames.reset();
    await _sendSessionCommand('START');
  }

  Future<void> stopSession() => _sendSessionCommand('STOP');

  Future<ShinGuardBleConnection?> connectToFirstAvailable() async {
    final attempt = ++_connectionAttempt;
    await _clearConnection(disconnectDevice: true);
    if (!_isCurrent(attempt)) return null;
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.scanning,
        message: 'Looking for ShinGuard...',
      ),
    );

    try {
      if (!await FlutterBluePlus.isSupported) {
        _emit(
          const ShinGuardBleState(
            status: ShinGuardBleStatus.error,
            message: 'Bluetooth LE is not supported on this device.',
          ),
        );
        return null;
      }

      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(_adapterTimeout);

      ScanResult? match;
      final subscription = FlutterBluePlus.onScanResults.listen((results) {
        if (!_isCurrent(attempt)) return;
        for (final result in results) {
          final name = _displayName(
            result.device,
            result.advertisementData.advName,
          );
          final advertisesService = result.advertisementData.serviceUuids
              .contains(serviceUuid);
          if (name.toLowerCase().contains('shinguard') || advertisesService) {
            match = result;
            FlutterBluePlus.stopScan();
            return;
          }
        }
      });
      try {
        await FlutterBluePlus.startScan(
          withServices: [serviceUuid],
          timeout: _scanTimeout,
        );
        await FlutterBluePlus.isScanning
            .where((value) => value == false)
            .first
            .timeout(_scanTimeout + const Duration(seconds: 2));
      } finally {
        await subscription.cancel();
      }

      if (!_isCurrent(attempt)) return null;

      final result = match;
      if (result == null) {
        _emit(
          const ShinGuardBleState(
            status: ShinGuardBleStatus.idle,
            message: 'No ShinGuard device found.',
          ),
        );
        return null;
      }

      return await _connect(
        result.device,
        _displayName(result.device, result.advertisementData.advName),
        attempt,
      );
    } catch (error) {
      await _connectionFailed(error, attempt);
      return null;
    }
  }

  Future<ShinGuardBleConnection?> autoConnect(String remoteId) async {
    if (remoteId.isEmpty) {
      return null;
    }

    final attempt = ++_connectionAttempt;
    await _clearConnection(disconnectDevice: true);
    if (!_isCurrent(attempt)) return null;
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.connecting,
        message: 'Waiting for saved ShinGuard...',
      ),
    );

    try {
      final device = BluetoothDevice.fromId(remoteId);
      return await _connect(device, _displayName(device, 'ShinGuard'), attempt);
    } catch (error) {
      await _connectionFailed(error, attempt);
      return null;
    }
  }

  Future<void> cancelConnectionAttempt() async {
    _connectionAttempt += 1;
    await _stopScan();
    await _clearConnection(disconnectDevice: true);
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.idle,
        message: 'Connection attempt cancelled',
      ),
    );
  }

  Future<void> disconnect({String message = 'Device disconnected'}) async {
    _connectionAttempt += 1;
    await _stopScan();
    await _clearConnection(disconnectDevice: true);
    _emit(ShinGuardBleState(status: ShinGuardBleStatus.idle, message: message));
  }

  Future<void> _clearConnection({required bool disconnectDevice}) async {
    await _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _device;
    _device = null;
    _controlCharacteristic = null;
    _imuFrames.reset();
    if (disconnectDevice && device != null) {
      try {
        await device.disconnect();
      } catch (_) {
        // The platform may already have removed a powered-off peripheral.
      }
    }
  }

  Future<ShinGuardBleConnection?> _connect(
    BluetoothDevice device,
    String name,
    int attempt,
  ) async {
    _device = device;
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.connecting,
        message: 'Connecting...',
      ),
    );

    await device
        .connect(license: License.nonprofit, timeout: _connectTimeout)
        .timeout(_connectTimeout);
    if (!_isCurrent(attempt)) {
      await device.disconnect();
      return null;
    }

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected &&
          _isCurrent(attempt) &&
          _state.status != ShinGuardBleStatus.idle) {
        unawaited(_handleUnexpectedDisconnect());
      }
    });

    final services = await device.discoverServices().timeout(_discoveryTimeout);
    if (!_isCurrent(attempt)) return null;
    BluetoothCharacteristic? telemetryCharacteristic;
    BluetoothCharacteristic? controlCharacteristic;
    for (final service in services) {
      if (service.uuid == serviceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == telemetryUuid) {
            telemetryCharacteristic = characteristic;
          } else if (characteristic.uuid == controlUuid) {
            controlCharacteristic = characteristic;
          }
        }
      }
    }
    if (telemetryCharacteristic == null) {
      throw StateError('The ShinGuard telemetry service was not found.');
    }
    _controlCharacteristic = controlCharacteristic;

    await _telemetrySubscription?.cancel();
    _telemetrySubscription = telemetryCharacteristic.onValueReceived.listen(
      _handleTelemetry,
    );
    await telemetryCharacteristic
        .setNotifyValue(true)
        .timeout(_discoveryTimeout);
    if (!_isCurrent(attempt)) return null;

    final connection = ShinGuardBleConnection(
      remoteId: device.remoteId.str,
      name: name.isEmpty ? 'ShinGuard' : name,
    );
    _emit(
      ShinGuardBleState(
        status: ShinGuardBleStatus.connected,
        message: 'Connected to ${connection.name}',
        connection: connection,
      ),
    );
    return connection;
  }

  Future<void> _handleUnexpectedDisconnect() async {
    _connectionAttempt += 1;
    await _clearConnection(disconnectDevice: false);
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.idle,
        message: 'ShinGuard connection lost',
      ),
    );
  }

  Future<void> _connectionFailed(Object error, int attempt) async {
    if (!_isCurrent(attempt)) return;
    await _stopScan();
    await _clearConnection(disconnectDevice: true);
    if (!_isCurrent(attempt)) return;
    final message = error is TimeoutException
        ? 'Connection timed out. Turn on ShinGuard and try again.'
        : error is StateError
        ? error.message.toString()
        : 'Unable to connect. Turn on ShinGuard and try again.';
    _emit(
      ShinGuardBleState(status: ShinGuardBleStatus.error, message: message),
    );
  }

  Future<void> _stopScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    } catch (_) {
      // Scanning may already have stopped due to its own timeout.
    }
  }

  bool _isCurrent(int attempt) => attempt == _connectionAttempt;

  Future<void> _sendSessionCommand(String command) async {
    if (!isConnected || _device == null) {
      throw StateError('Connect your ShinGuard before starting a session.');
    }
    final characteristic = _controlCharacteristic;
    if (characteristic == null) {
      throw StateError(
        'The connected ShinGuard firmware does not support sessions yet.',
      );
    }
    await characteristic.write(utf8.encode(command), withoutResponse: false);
  }

  void _handleTelemetry(List<int> value) {
    try {
      final decoded = utf8.decode(value);
      final parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) {
        _telemetryController.add(parsed);
        final sample = _imuFrames.add(parsed);
        if (sample != null) _imuController.add(sample);
      }
    } catch (_) {
      // Ignore malformed BLE fragments. The next notification should be complete.
    }
  }

  String _displayName(BluetoothDevice device, String advertisementName) {
    if (advertisementName.isNotEmpty) {
      return advertisementName;
    }
    if (device.advName.isNotEmpty) {
      return device.advName;
    }
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    return 'ShinGuard';
  }

  void _emit(ShinGuardBleState state) {
    _state = state;
    _stateController.add(state);
  }
}

enum ShinGuardBleStatus { idle, scanning, connecting, connected, error }

class ShinGuardBleState {
  const ShinGuardBleState({
    required this.status,
    required this.message,
    this.connection,
  });

  final ShinGuardBleStatus status;
  final String message;
  final ShinGuardBleConnection? connection;
}

class ShinGuardBleConnection {
  const ShinGuardBleConnection({required this.remoteId, required this.name});

  final String remoteId;
  final String name;
}
