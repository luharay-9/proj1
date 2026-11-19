import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/imu_sample.dart';
import 'package:shinguard/models/session_route.dart';
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

  test('healthy BNO acceleration samples are accumulated', () {
    final accumulator = SessionTelemetryAccumulator();
    final sample = _sample(accelerationG: 1.2);
    for (var index = 0; index < 600; index++) {
      accumulator.addImuSample(sample);
    }
    accumulator.addImuSample(_sample(accelerationG: 3.4));

    expect(accumulator.sampleCount, 601);
    expect(accumulator.peakAccelerationG, 3.4);

    accumulator.reset();
    expect(accumulator.sampleCount, 0);
    expect(accumulator.peakAccelerationG, 0);
  });

  test('records firmware peak speed, sprint totals, and shot estimates', () {
    final accumulator = SessionTelemetryAccumulator();
    const start = Duration.zero;
    const later = Duration(seconds: 9);
    accumulator.addTelemetry({
      'f': 0,
      'sc': 0,
      'ts': 18,
      'kc': 0,
      'sh': 0,
    }, start);
    expect(accumulator.topSpeed, 18);
    expect(accumulator.sprints, 0);
    expect(accumulator.estimatedShots, 0);
    accumulator.addTelemetry({
      'f': 0,
      'sc': 3,
      'ts': 28,
      'kc': 4,
      'sh': 2,
    }, later);
    accumulator.addTelemetry({
      'f': 1,
      'sc': 3,
      'ts': 28,
      'kc': 4,
      'sh': 2,
    }, later);
    accumulator.addTelemetry({
      'f': 1,
      'sc': 2,
      'ts': 100,
      'kc': 3,
      'sh': 1,
    }, later);

    expect(accumulator.topSpeed, 28);
    expect(accumulator.sprints, 3);
    expect(accumulator.sprintEvents, {3: later});
    expect(accumulator.kicks, 4);
    expect(accumulator.estimatedShots, 2);

    accumulator.reset();
    expect(accumulator.topSpeed, 0);
    expect(accumulator.sprints, 0);
    expect(accumulator.sprintEvents, isEmpty);
    expect(accumulator.kicks, 0);
    expect(accumulator.estimatedShots, isNull);
  });

  test('fresh GPS positions form the route used by the heatmap', () {
    final accumulator = SessionTelemetryAccumulator();
    void point(int second, double east, double speed) {
      accumulator.addTelemetry({
        'f': 2,
        't': second,
        'p': [0, east / 111320],
        'sat': 9,
        'v': speed,
      }, Duration(seconds: second));
    }

    point(1, 0, 12);
    point(2, 1, 14);
    point(2, 20, 59);
    point(3, 7, 15);
    point(4, 1, 13);

    final heatmap = SessionRoute(accumulator.route);
    expect(accumulator.topSpeed, 15);
    expect(accumulator.estimatedShots, isNull);
    expect(heatmap.points, hasLength(4));
    expect(heatmap.cells[(0, 0)]!.visits, 2);
    expect(heatmap.cells[(0, 0)]!.samples, 3);
    expect(heatmap.cells[(1, 0)]!.visits, 1);
  });
}

ImuSample _sample({required double accelerationG}) {
  return ImuSample(
    sequence: 1,
    sensorTimeSeconds: 0,
    acceleration: ImuVector3.zero,
    linearAcceleration: ImuVector3.zero,
    angularVelocity: ImuVector3.zero,
    magneticField: ImuVector3.zero,
    orientation: ImuQuaternion.identity,
    accelerationG: accelerationG,
    sprintCount: 0,
    sprintEvent: false,
    kickEvent: false,
    sensorHealthy: true,
  );
}
