import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/imu_sample.dart';

void main() {
  test('merges compact motion and orientation frames into a 9-axis sample', () {
    final accumulator = ImuFrameAccumulator();

    final first = accumulator.add({
      'f': 0,
      'n': 10,
      't': 2.5,
      'a': [1.0, 2.0, 3.0],
      'l': [0.1, 0.2, 0.3],
      'w': [0.4, 0.5, 0.6],
      'sp': 0,
      'sc': 2,
    });
    expect(first, isNull);

    final sample = accumulator.add({
      'f': 1,
      'n': 11,
      't': 2.55,
      'm': [11.0, 12.0, 13.0],
      'q': [0.0, 0.0, 0.7071, 0.7071],
      'g': 1.03,
      'sp': 1,
      'sc': 3,
      'k': 0,
    });

    expect(sample, isNotNull);
    expect(sample!.sequence, 11);
    expect(sample.acceleration.x, 1.0);
    expect(sample.linearAcceleration.z, 0.3);
    expect(sample.angularVelocity.y, 0.5);
    expect(sample.magneticField.z, 13.0);
    expect(sample.orientation.k, closeTo(0.7071, 0.0001));
    expect(sample.orientation.real, closeTo(0.7071, 0.0001));
    expect(sample.sprintCount, 3);
    expect(sample.sprintEvent, isTrue);
    expect(sample.kickEvent, isFalse);
  });

  test('reset requires both frame types again', () {
    final accumulator = ImuFrameAccumulator();
    accumulator.add({
      'f': 0,
      'a': [0, 0, 0],
      'l': [0, 0, 0],
      'w': [0, 0, 0],
    });
    accumulator.add({
      'f': 1,
      'm': [0, 0, 0],
      'q': [0, 0, 0, 1],
    });
    accumulator.reset();

    expect(
      accumulator.add({
        'f': 1,
        'm': [1, 2, 3],
        'q': [0, 0, 0, 1],
      }),
      isNull,
    );
  });
}
