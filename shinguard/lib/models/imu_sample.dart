class ImuVector3 {
  const ImuVector3(this.x, this.y, this.z);

  static const zero = ImuVector3(0, 0, 0);

  final double x;
  final double y;
  final double z;

  factory ImuVector3.fromValue(Object? value) {
    final values = _numbers(value, 3);
    return ImuVector3(values[0], values[1], values[2]);
  }
}

class ImuQuaternion {
  const ImuQuaternion(this.i, this.j, this.k, this.real);

  static const identity = ImuQuaternion(0, 0, 0, 1);

  final double i;
  final double j;
  final double k;
  final double real;

  factory ImuQuaternion.fromValue(Object? value) {
    final values = _numbers(value, 4, fallback: const [0, 0, 0, 1]);
    return ImuQuaternion(values[0], values[1], values[2], values[3]);
  }
}

class ImuSample {
  const ImuSample({
    required this.sequence,
    required this.sensorTimeSeconds,
    required this.acceleration,
    required this.linearAcceleration,
    required this.angularVelocity,
    required this.magneticField,
    required this.orientation,
    required this.accelerationG,
    required this.sprintCount,
    required this.sprintEvent,
    required this.kickEvent,
  });

  final int sequence;
  final double sensorTimeSeconds;

  /// Acceleration including gravity, in meters per second squared.
  final ImuVector3 acceleration;

  /// Gravity-free acceleration in the sensor/body frame, in m/s^2.
  final ImuVector3 linearAcceleration;

  /// Angular velocity in radians per second.
  final ImuVector3 angularVelocity;

  /// Calibrated magnetic field in microteslas.
  final ImuVector3 magneticField;

  /// Magnetometer-corrected rotation vector as (i, j, k, real).
  final ImuQuaternion orientation;

  final double accelerationG;
  final int sprintCount;
  final bool sprintEvent;
  final bool kickEvent;
}

class ImuFrameAccumulator {
  Map<String, dynamic>? _motionFrame;
  Map<String, dynamic>? _orientationFrame;

  ImuSample? add(Map<String, dynamic> frame) {
    final frameType = _integer(frame['f']);
    if (frameType == 0) {
      _motionFrame = Map<String, dynamic>.from(frame);
    } else if (frameType == 1) {
      _orientationFrame = Map<String, dynamic>.from(frame);
    } else {
      return null;
    }

    final motion = _motionFrame;
    final orientation = _orientationFrame;
    if (motion == null || orientation == null) return null;

    return ImuSample(
      sequence: _integer(frame['n']).clamp(0, 1 << 31),
      sensorTimeSeconds: _decimal(frame['t']),
      acceleration: ImuVector3.fromValue(motion['a']),
      linearAcceleration: ImuVector3.fromValue(motion['l']),
      angularVelocity: ImuVector3.fromValue(motion['w']),
      magneticField: ImuVector3.fromValue(orientation['m']),
      orientation: ImuQuaternion.fromValue(orientation['q']),
      accelerationG: _decimal(orientation['g']),
      sprintCount: _integer(frame['sc']).clamp(0, 1 << 31),
      sprintEvent: _flag(frame['sp']),
      kickEvent: _flag(frame['k']),
    );
  }

  void reset() {
    _motionFrame = null;
    _orientationFrame = null;
  }
}

List<double> _numbers(Object? value, int length, {List<double>? fallback}) {
  final defaults = fallback ?? List<double>.filled(length, 0);
  if (value is! Iterable) return List<double>.from(defaults);
  final values = value.map(_decimal).toList();
  if (values.length < length) return List<double>.from(defaults);
  return values.take(length).toList();
}

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

bool _flag(Object? value) {
  return value == true || (value is num && value != 0) || value == '1';
}
