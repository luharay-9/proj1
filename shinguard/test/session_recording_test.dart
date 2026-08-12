import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/imu_sample.dart';
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
    final accumulator = BnoSessionAccumulator();
    accumulator.add(_sample(accelerationG: 1.2));
    accumulator.add(_sample(accelerationG: 3.4));

    expect(accumulator.sampleCount, 2);
    expect(accumulator.peakAccelerationG, 3.4);

    accumulator.reset();
    expect(accumulator.sampleCount, 0);
    expect(accumulator.peakAccelerationG, 0);
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
