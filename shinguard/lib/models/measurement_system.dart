enum MeasurementSystem {
  imperial,
  metric;

  static MeasurementSystem fromValue(String? value) {
    return value?.trim().toLowerCase() == 'imperial'
        ? MeasurementSystem.imperial
        : MeasurementSystem.metric;
  }

  String get displayName => switch (this) {
    MeasurementSystem.imperial => 'Imperial',
    MeasurementSystem.metric => 'Metric',
  };

  String get distanceUnit => switch (this) {
    MeasurementSystem.imperial => 'mi',
    MeasurementSystem.metric => 'km',
  };

  String get speedUnit => switch (this) {
    MeasurementSystem.imperial => 'mph',
    MeasurementSystem.metric => 'km/h',
  };
}

class MeasurementFormatter {
  const MeasurementFormatter._();

  static const _kilometersToMiles = 0.6213711922;

  static String distance(String value, MeasurementSystem system) {
    final parsed = _parse(value);
    if (parsed == null) return value;

    final unit = parsed.unit;
    final kilometers = switch (unit) {
      'mi' || 'mile' || 'miles' => parsed.value / _kilometersToMiles,
      'm' || 'meter' || 'meters' => parsed.value / 1000,
      _ => parsed.value,
    };
    final converted = system == MeasurementSystem.imperial
        ? kilometers * _kilometersToMiles
        : kilometers;
    return '${_oneDecimal(converted)} ${system.distanceUnit}';
  }

  static String speed(String value, MeasurementSystem system) {
    final parsed = _parse(value);
    if (parsed == null) return value;

    final unit = parsed.unit;
    final kilometersPerHour = switch (unit) {
      'mph' || 'mi/h' => parsed.value / _kilometersToMiles,
      'm/s' => parsed.value * 3.6,
      _ => parsed.value,
    };
    final converted = system == MeasurementSystem.imperial
        ? kilometersPerHour * _kilometersToMiles
        : kilometersPerHour;
    return '${_oneDecimal(converted)} ${system.speedUnit}';
  }

  static String distanceParts(
    String value,
    String unit,
    MeasurementSystem system,
  ) {
    return distance('$value $unit', system);
  }

  static String speedFromKilometersPerHour(
    double value,
    MeasurementSystem system,
  ) {
    return speed('$value km/h', system);
  }

  static String dashboardMetric({
    required String label,
    required String value,
    required MeasurementSystem system,
  }) {
    final normalizedLabel = label.trim().toLowerCase();
    if (normalizedLabel.contains('top speed') || normalizedLabel == 'speed') {
      return speed(value, system);
    }
    if (normalizedLabel.contains('distance')) {
      return distance(value, system);
    }
    return value;
  }

  static _ParsedMeasurement? _parse(String value) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    if (match == null) return null;
    final number = double.tryParse(match.group(0)!);
    if (number == null) return null;
    final unit = value.substring(match.end).trim().toLowerCase();
    return _ParsedMeasurement(number, unit);
  }

  static String _oneDecimal(double value) => value.toStringAsFixed(1);
}

class _ParsedMeasurement {
  const _ParsedMeasurement(this.value, this.unit);

  final double value;
  final String unit;
}
