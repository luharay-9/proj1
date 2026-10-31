import 'dart:math' as math;

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

  factory PlayerPosition.fromMap(Map<String, dynamic> map) {
    final position = tryFromMap(map);
    if (position == null) {
      throw const FormatException('Invalid player position data.');
    }
    return position;
  }

  static PlayerPosition? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final latitude = _nullableDecimal(map['latitude']);
    final longitude = _nullableDecimal(map['longitude']);
    final sensorTimeSeconds = _nullableDecimal(map['sensorTimeSeconds']);
    final altitudeMeters = _nullableDecimal(map['altitudeMeters']);
    final speedKmh = _nullableDecimal(map['speedKmh']);
    if (latitude == null ||
        longitude == null ||
        sensorTimeSeconds == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        !sensorTimeSeconds.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (altitudeMeters != null && !altitudeMeters.isFinite) ||
        (speedKmh != null && (!speedKmh.isFinite || speedKmh < 0))) {
      return null;
    }
    return PlayerPosition(
      latitude: latitude,
      longitude: longitude,
      sensorTimeSeconds: sensorTimeSeconds,
      satellites: _integer(map['satellites']).clamp(0, 99),
      altitudeMeters: altitudeMeters,
      speedKmh: speedKmh,
    );
  }
}

double routeDistanceKilometers(Iterable<PlayerPosition> positions) {
  final points = positions.toList(growable: false);
  if (points.length < 2) return 0;
  var distanceKilometers = 0.0;
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final elapsedSeconds =
        current.sensorTimeSeconds - previous.sensorTimeSeconds;
    if (elapsedSeconds <= 0) continue;
    final segmentKilometers = _distanceKilometers(previous, current);
    final impliedSpeedKmh = segmentKilometers * 3600 / elapsedSeconds;
    if (impliedSpeedKmh <= 50) {
      distanceKilometers += segmentKilometers;
    }
  }
  return distanceKilometers;
}

double _distanceKilometers(PlayerPosition start, PlayerPosition end) {
  const earthRadiusKilometers = 6371.0;
  final startLatitude = start.latitude * math.pi / 180;
  final endLatitude = end.latitude * math.pi / 180;
  final latitudeDelta = endLatitude - startLatitude;
  final longitudeDelta = (end.longitude - start.longitude) * math.pi / 180;
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(startLatitude) *
          math.cos(endLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final angularDistance =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusKilometers * angularDistance;
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
