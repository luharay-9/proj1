import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'player_position.dart';

class RouteCell {
  RouteCell(this.x, this.y);
  final int x;
  final int y;
  int visits = 0;
  int samples = 0;
}

class SessionRoute {
  SessionRoute(List<PlayerPosition> route) {
    if (route.isEmpty) return;
    final origin = route.first;
    (int, int)? previous;
    double? previousTime;
    for (final point in route) {
      final longitudeDelta =
          (point.longitude - origin.longitude + 180) % 360 - 180;
      final x =
          longitudeDelta * 111320 * math.cos(origin.latitude * math.pi / 180);
      final y = -(point.latitude - origin.latitude) * 111320;
      points.add(Offset(x, y));
      times.add(point.sensorTimeSeconds);
      final key = ((x / cellMeters).floor(), (y / cellMeters).floor());
      final cell = cells.putIfAbsent(key, () => RouteCell(key.$1, key.$2));
      cell.samples++;
      if (previous != key ||
          previousTime == null ||
          point.sensorTimeSeconds - previousTime > maxSampleGapSeconds) {
        cell.visits++;
        _maxVisits = math.max(_maxVisits, cell.visits);
      }
      previous = key;
      previousTime = point.sensorTimeSeconds;
    }
    final xs = cells.values.map((cell) => cell.x);
    final ys = cells.values.map((cell) => cell.y);
    bounds = Rect.fromLTRB(
      xs.reduce(math.min) * cellMeters - cellMeters,
      ys.reduce(math.min) * cellMeters - cellMeters,
      (xs.reduce(math.max) + 2) * cellMeters,
      (ys.reduce(math.max) + 2) * cellMeters,
    );
  }

  static const cellMeters = 5.0;
  static const maxSampleGapSeconds = 3;
  static const lowActivity = Color(0xff70d883);
  static const mediumActivity = Color(0xffffcb45);
  static const highActivity = Color(0xffef5350);
  final List<Offset> points = [];
  final List<double> times = [];
  final Map<(int, int), RouteCell> cells = {};
  Rect bounds = const Rect.fromLTWH(0, 0, 15, 15);
  int _maxVisits = 0;
  int get maxVisits => _maxVisits;

  Color colorFor(RouteCell cell) {
    final level = maxVisits <= 1 ? 0.0 : (cell.visits - 1) / (maxVisits - 1);
    return level <= .5
        ? Color.lerp(lowActivity, mediumActivity, level * 2)!
        : Color.lerp(mediumActivity, highActivity, (level - .5) * 2)!;
  }
}
