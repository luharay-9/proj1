class PlayerPosition {
  const PlayerPosition({
    required this.latitude,
    required this.longitude,
    required this.sensorTimeSeconds,
    required this.satellites,
    this.altitudeMeters,
  });

  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final double sensorTimeSeconds;
  final int satellites;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
    'sensorTimeSeconds': sensorTimeSeconds,
    'satellites': satellites,
  };

  static PlayerPosition? fromTelemetry(Map<String, dynamic> telemetry) {
    if (_integer(telemetry['f']) != 2) return null;
    final value = telemetry['p'];
    if (value is! Iterable) return null;
    final coordinates = value.toList();
    if (coordinates.length < 2) return null;
    final latitude = _nullableDecimal(coordinates[0]);
    final longitude = _nullableDecimal(coordinates[1]);
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;

    return PlayerPosition(
      latitude: latitude,
      longitude: longitude,
      altitudeMeters: coordinates.length > 2
          ? _nullableDecimal(coordinates[2])
          : null,
      sensorTimeSeconds: _nullableDecimal(telemetry['t']) ?? 0,
      satellites: _integer(telemetry['sat']).clamp(0, 99),
    );
  }
}

double? _nullableDecimal(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
