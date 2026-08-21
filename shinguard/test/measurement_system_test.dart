import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/app_data.dart';
import 'package:shinguard/models/measurement_system.dart';

void main() {
  group('MeasurementFormatter', () {
    test('converts metric distance and speed to imperial', () {
      expect(
        MeasurementFormatter.distance('8.7 km', MeasurementSystem.imperial),
        '5.4 mi',
      );
      expect(
        MeasurementFormatter.speed('28.4 km/h', MeasurementSystem.imperial),
        '17.6 mph',
      );
    });

    test('converts imperial values back to metric', () {
      expect(
        MeasurementFormatter.distance('5.4 mi', MeasurementSystem.metric),
        '8.7 km',
      );
      expect(
        MeasurementFormatter.speed('17.6 mph', MeasurementSystem.metric),
        '28.3 km/h',
      );
    });

    test('formats distance-run value and unit together', () {
      expect(
        MeasurementFormatter.distanceParts(
          '24.6',
          'km',
          MeasurementSystem.imperial,
        ),
        '15.3 mi',
      );
    });
  });

  test('athlete profile reads the persisted unit preference', () {
    final user = UserAppData.fromMap({
      'athleteProfile': {'unitSystem': 'imperial'},
    });

    expect(user.athleteProfile.measurementSystem, MeasurementSystem.imperial);
  });

  test('legacy profiles retain the existing metric display default', () {
    final user = UserAppData.fromMap(const {});

    expect(user.athleteProfile.measurementSystem, MeasurementSystem.metric);
  });

  test('legacy imperial profiles infer units from height and weight', () {
    final user = UserAppData.fromMap({
      'athleteProfile': {'height': '5 ft 8 in', 'weight': '145 lb'},
    });

    expect(user.athleteProfile.measurementSystem, MeasurementSystem.imperial);
  });
}
