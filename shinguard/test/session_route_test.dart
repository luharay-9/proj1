import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/player_position.dart';
import 'package:shinguard/models/session_route.dart';

PlayerPosition point(double east, double time) => PlayerPosition(
  latitude: 0,
  longitude: east / 111320,
  sensorTimeSeconds: time,
  satellites: 8,
);

void main() {
  test('stationary samples count as one visit; returning counts again', () {
    final route = SessionRoute([
      point(0, 0),
      point(1, 1),
      point(6, 2),
      point(1, 3),
    ]);
    expect(route.points.length, 4);
    expect(route.cells[(0, 0)]!.visits, 2);
    expect(route.cells[(0, 0)]!.samples, 3);
    expect(route.cells[(1, 0)]!.visits, 1);
    expect(route.cells[(2, 0)], isNull);
    expect(route.colorFor(route.cells[(0, 0)]!).toARGB32(), 0xffef5350);
    expect(route.colorFor(route.cells[(1, 0)]!).toARGB32(), 0xff70d883);
  });

  test('GPS gaps break visits and single visits stay green', () {
    final route = SessionRoute([point(0, 0), point(0, 5)]);
    expect(route.cells[(0, 0)]!.visits, 2);
    final single = SessionRoute([point(0, 0)]);
    expect(single.colorFor(single.cells.values.single).toARGB32(), 0xff70d883);
    expect(SessionRoute([]).maxVisits, 0);
  });

  test('medium repetitions are yellow', () {
    final route = SessionRoute([
      point(0, 0),
      point(6, 1),
      point(11, 2),
      point(6, 3),
      point(11, 4),
      point(0, 5),
      point(11, 6),
    ]);
    expect(route.colorFor(route.cells[(0, 0)]!).toARGB32(), 0xffffcb45);
  });
}
