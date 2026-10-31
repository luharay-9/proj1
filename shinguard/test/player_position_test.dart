import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/player_position.dart';

void main() {
  test('parses the PA1010D initial-position telemetry frame', () {
    final position = PlayerPosition.fromTelemetry({
      'f': 2,
      't': 12.5,
      'p': [37.421999, -122.084057, 14.2],
      'sat': 9,
    });

    expect(position, isNotNull);
    expect(position!.latitude, closeTo(37.421999, 0.000001));
    expect(position.longitude, closeTo(-122.084057, 0.000001));
    expect(position.altitudeMeters, 14.2);
    expect(position.satellites, 9);
  });

  test('ignores malformed and non-GPS telemetry', () {
    expect(
      PlayerPosition.fromTelemetry({
        'f': 0,
        'p': [1, 2],
      }),
      isNull,
    );
    expect(
      PlayerPosition.fromTelemetry({
        'f': 2,
        'p': [91, 2],
      }),
      isNull,
    );
    expect(
      PlayerPosition.fromTelemetry({
        'f': 2,
        'p': [1],
      }),
      isNull,
    );
  });

  test('safely rejects malformed stored route points', () {
    expect(PlayerPosition.tryFromMap(null), isNull);
    expect(PlayerPosition.tryFromMap({'latitude': 'invalid'}), isNull);
    expect(
      PlayerPosition.tryFromMap({
        'latitude': 37.4,
        'longitude': -122.1,
        'sensorTimeSeconds': 1,
        'speedKmh': -1,
      }),
      isNull,
    );
  });

  test('calculates route distance and ignores impossible GPS jumps', () {
    const route = [
      PlayerPosition(
        latitude: 0,
        longitude: 0,
        sensorTimeSeconds: 0,
        satellites: 8,
      ),
      PlayerPosition(
        latitude: 0,
        longitude: 0.0009,
        sensorTimeSeconds: 10,
        satellites: 8,
      ),
      PlayerPosition(
        latitude: 0,
        longitude: 0.0018,
        sensorTimeSeconds: 20,
        satellites: 8,
      ),
      PlayerPosition(
        latitude: 1,
        longitude: 1,
        sensorTimeSeconds: 21,
        satellites: 8,
      ),
    ];

    expect(routeDistanceKilometers(route), closeTo(.2, .01));
  });
}
