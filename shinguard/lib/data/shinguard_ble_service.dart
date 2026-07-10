import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ShinGuardBleService {
  ShinGuardBleService._();

  static final ShinGuardBleService instance = ShinGuardBleService._();

  static final Guid serviceUuid = Guid('4f3d0001-6847-4f1f-b4a8-5f12f735d201');
  static final Guid telemetryUuid = Guid(
    '4f3d0002-6847-4f1f-b4a8-5f12f735d201',
  );

  final _stateController = StreamController<ShinGuardBleState>.broadcast();
  final _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();

  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _telemetrySubscription;

  Stream<ShinGuardBleState> get states => _stateController.stream;
  Stream<Map<String, dynamic>> get telemetry => _telemetryController.stream;

  ShinGuardBleState _state = const ShinGuardBleState(
    status: ShinGuardBleStatus.idle,
    message: 'No device connected',
  );

  ShinGuardBleState get currentState => _state;

  Future<ShinGuardBleConnection?> connectToFirstAvailable() async {
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
          .timeout(const Duration(seconds: 10));

      ScanResult? match;
      final subscription = FlutterBluePlus.onScanResults.listen((results) {
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
      FlutterBluePlus.cancelWhenScanComplete(subscription);

      await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        withNames: const ['ShinGuard'],
        timeout: const Duration(seconds: 12),
      );
      await FlutterBluePlus.isScanning.where((value) => value == false).first;

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

      return _connect(
        result.device,
        _displayName(result.device, result.advertisementData.advName),
      );
    } catch (error) {
      _emit(
        ShinGuardBleState(
          status: ShinGuardBleStatus.error,
          message: 'Unable to connect: $error',
        ),
      );
      return null;
    }
  }

  Future<ShinGuardBleConnection?> autoConnect(String remoteId) async {
    if (remoteId.isEmpty) {
      return null;
    }

    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.connecting,
        message: 'Waiting for saved ShinGuard...',
      ),
    );

    try {
      final device = BluetoothDevice.fromId(remoteId);
      await device.connect(
        license: License.nonprofit,
        autoConnect: true,
        mtu: null,
      );
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first;
      return _connect(device, _displayName(device, 'ShinGuard'));
    } catch (error) {
      _emit(
        ShinGuardBleState(
          status: ShinGuardBleStatus.error,
          message: 'Auto-connect failed: $error',
        ),
      );
      return null;
    }
  }

  Future<void> disconnect() async {
    await _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _device?.disconnect();
    _device = null;
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.idle,
        message: 'Device disconnected',
      ),
    );
  }

  Future<ShinGuardBleConnection?> _connect(
    BluetoothDevice device,
    String name,
  ) async {
    _device = device;
    _emit(
      const ShinGuardBleState(
        status: ShinGuardBleStatus.connecting,
        message: 'Connecting...',
      ),
    );

    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 15),
    );

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _emit(
          const ShinGuardBleState(
            status: ShinGuardBleStatus.idle,
            message: 'Device disconnected',
          ),
        );
      }
    });

    final services = await device.discoverServices();
    BluetoothCharacteristic? telemetryCharacteristic;
    for (final service in services) {
      if (service.uuid == serviceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == telemetryUuid) {
            telemetryCharacteristic = characteristic;
          }
        }
      }
    }

    if (telemetryCharacteristic != null) {
      await _telemetrySubscription?.cancel();
      _telemetrySubscription = telemetryCharacteristic.onValueReceived.listen(
        _handleTelemetry,
      );
      await telemetryCharacteristic.setNotifyValue(true);
    }

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

  void _handleTelemetry(List<int> value) {
    try {
      final decoded = utf8.decode(value);
      final parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) {
        _telemetryController.add(parsed);
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
