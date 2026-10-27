import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/data/demo_data.dart';
import 'package:shinguard/models/app_data.dart';
import 'package:shinguard/models/match_summary.dart';
import 'package:shinguard/models/muscle_report.dart';
import 'package:shinguard/models/player_position.dart';
import 'package:shinguard/models/session_route.dart';
import 'package:shinguard/models/training_session.dart';

void main() {
  test('demo sections only populate their owned profile fields', () {
    final home = demoRootFields({DemoDataSection.home});
    final statistics = demoRootFields({DemoDataSection.statistics});
    final care = demoRootFields({DemoDataSection.care});

    expect(home.keys, containsAll(['readiness', 'dashboardMetrics', 'tips']));
    expect(home, isNot(contains('performance')));
    expect(statistics.keys, ['performance']);
    expect(care.keys, ['careRisk']);
  });

  test('demo payloads parse through the production models', () {
    final root = demoRootFields(DemoDataSection.values.toSet());
    final user = UserAppData.fromMap(root);
    final matches = demoMatchDocuments(DateTime(2026, 8, 20));
    final sessions = demoSessionDocuments(DateTime(2026, 8, 20));
    final reports = demoMuscleReportDocuments();

    expect(user.readiness.score, 84);
    expect(user.metrics, hasLength(3));
    expect(user.performance.trendPoints, hasLength(7));
    expect(user.care.score, 6);
    expect(matches.map(MatchSummary.fromMap), hasLength(4));
    expect(sessions.map(TrainingSession.fromMap), hasLength(4));
    expect(reports.map(MuscleReport.fromMap), hasLength(6));
    expect(
      reports
          .map(MuscleReport.fromMap)
          .every((report) => report.polygons.isNotEmpty),
      isTrue,
    );
    expect(
      reports.every(
        (report) => (report['polygons'] as List).every(
          (polygon) => polygon is Map && polygon['points'] is List,
        ),
      ),
      isTrue,
      reason: 'Firestore rejects arrays nested directly inside arrays.',
    );
  });

  test('soccer demo training stays asymmetric in one attacking half', () {
    final matches = demoMatchDocuments(DateTime(2026, 8, 20));
    final training = matches.singleWhere(
      (match) => match['id'] == demoTrainingSessionId,
    );
    expect(training['title'], 'Soccer Demo Training');
    expect(training['sprints'], greaterThan(40));
    expect(training['shots'], greaterThan(20));

    final positions = demoSoccerTrainingRoutePoints()
        .map(PlayerPosition.fromMap)
        .toList();
    final route = SessionRoute(positions);
    final attackingHalfSamples = route.points.where((point) {
      return point.dy + demoTrainingStartYMeters >= 52.5;
    }).length;
    final leftSideSamples = route.points
        .where((point) => point.dx + demoTrainingStartXMeters < 0)
        .length;
    final rightSideSamples = route.points.length - leftSideSamples;
    final penaltyBoxSamples = route.points
        .where((point) => point.dy + demoTrainingStartYMeters >= 88)
        .length;
    final startLineSamples = route.points
        .where(
          (point) =>
              point.dy + demoTrainingStartYMeters >= 80 &&
              point.dy + demoTrainingStartYMeters <= 84,
        )
        .length;
    final checkInSamples = route.points
        .where((point) => point.dy + demoTrainingStartYMeters <= 79)
        .length;
    final wideLaneSamples = route.points.where((point) {
      final fieldX = point.dx + demoTrainingStartXMeters;
      final fieldY = point.dy + demoTrainingStartYMeters;
      return fieldX.abs() >= 24 && fieldY >= 87;
    }).length;
    final cornerSamples = route.points.where((point) {
      final fieldX = point.dx + demoTrainingStartXMeters;
      final fieldY = point.dy + demoTrainingStartYMeters;
      final nearTouchline = fieldX <= -29 || fieldX >= 26;
      final nearGoalLine = fieldY >= 99;
      return nearTouchline && nearGoalLine;
    }).length;
    expect(route.points.first, Offset.zero);
    expect((105 - demoTrainingStartYMeters) / .9144, closeTo(25, .2));
    expect(attackingHalfSamples, route.points.length);
    expect((leftSideSamples - rightSideSamples).abs(), greaterThan(10));
    expect(penaltyBoxSamples, greaterThan(70));
    expect(startLineSamples, greaterThan(30));
    expect(checkInSamples, greaterThanOrEqualTo(10));
    expect(wideLaneSamples, greaterThanOrEqualTo(10));
    expect(cornerSamples, greaterThanOrEqualTo(5));
    expect(route.maxVisits, greaterThan(1));
  });

  test('demo document ids are reserved and unique', () {
    final allIds = {...demoDocumentIds, ...demoMuscleReportIds};

    expect(
      allIds,
      hasLength(demoDocumentIds.length + demoMuscleReportIds.length),
    );
    expect(allIds.every((id) => id.startsWith('debug_demo_')), isTrue);
  });
}
