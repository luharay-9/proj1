class PlayerPosition {
  const PlayerPosition({
    required this.latitude,
    required this.longitude,
    required this.sensorTimeSeconds,
    required this.satellites,
    this.altitudeMeters,
    this.speedKmh,
  });

  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final double sensorTimeSeconds;
  final int satellites;
  final double? speedKmh;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
    'sensorTimeSeconds': sensorTimeSeconds,
    'satellites': satellites,
    if (speedKmh != null) 'speedKmh': speedKmh,
  };

  static PlayerPosition? fromTelemetry(Map<String, dynamic> telemetry) {
    if (_integer(telemetry['f']) != 2) return null;
    final value = telemetry['p'];
    if (value is! Iterable) return null;
    final coordinates = value.toList();
    if (coordinates.length < 2) return null;
    final latitude = _nullableDecimal(coordinates[0]);
    final longitude = _nullableDecimal(coordinates[1]);
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite) {
      return null;
    }
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
      speedKmh: _nullableDecimal(telemetry['v']),
    );
  }

  factory PlayerPosition.fromMap(Map<String, dynamic> map) => PlayerPosition(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    sensorTimeSeconds: (map['sensorTimeSeconds'] as num).toDouble(),
    satellites: _integer(map['satellites']),
    altitudeMeters: _nullableDecimal(map['altitudeMeters']),
    speedKmh: _nullableDecimal(map['speedKmh']),
  );
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
