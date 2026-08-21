import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/data/demo_data.dart';
import 'package:shinguard/models/app_data.dart';
import 'package:shinguard/models/match_summary.dart';
import 'package:shinguard/models/muscle_report.dart';
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
    expect(matches.map(MatchSummary.fromMap), hasLength(3));
    expect(sessions.map(TrainingSession.fromMap), hasLength(3));
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

  test('demo document ids are reserved and unique', () {
    final allIds = {...demoDocumentIds, ...demoMuscleReportIds};

    expect(
      allIds,
      hasLength(demoDocumentIds.length + demoMuscleReportIds.length),
    );
    expect(allIds.every((id) => id.startsWith('debug_demo_')), isTrue);
  });
}
