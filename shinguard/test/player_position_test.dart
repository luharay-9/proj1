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
}
