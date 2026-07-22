import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/services/session_recording_service.dart';

void main() {
  test('cumulative hardware sprint count is authoritative', () {
    var count = sprintCountFromTelemetry({'sc': 1, 'sp': true}, 0);
    expect(count, 1);

    count = sprintCountFromTelemetry({'sc': 1, 'sp': false}, count);
    expect(count, 1);

    count = sprintCountFromTelemetry({'sc': 3, 'sp': true}, count);
    expect(count, 3);
  });

  test('event-only telemetry remains compatible', () {
    expect(sprintCountFromTelemetry({'sprint': true}, 4), 5);
    expect(sprintCountFromTelemetry({'sp': 1}, 5), 6);
    expect(sprintCountFromTelemetry({'sprint': false}, 5), 5);
  });
}
