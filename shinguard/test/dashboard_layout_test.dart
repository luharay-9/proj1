import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/app_data.dart';
import 'package:shinguard/models/match_summary.dart';
import 'package:shinguard/screens/home_screen.dart';
import 'package:shinguard/screens/stats_screen.dart';
import 'package:shinguard/shared/shared_widgets.dart';

void main() {
  testWidgets('readiness details fit on a narrow phone', (tester) async {
    await tester.pumpWidget(
      _testApp(
        ReadinessCard(
          readiness: ReadinessData.fromMap({
            'label': 'READINESS TODAY',
            'score': 84,
            'progress': .84,
            'status': 'READY',
            'detail': 'Movement load is within your target recovery range',
            'recoveryLabel': '8h recovery',
          }),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard metric cards keep the same height', (tester) async {
    final metrics = [
      _metric('DISTANCE', '8.7 km'),
      _metric('TOP SPEED', '28.4 km/h'),
      _metric('SPRINTS', '31'),
    ];

    await tester.pumpWidget(_testApp(DashboardMetricRow(metrics: metrics)));

    expect(tester.takeException(), isNull);
    final sizes = tester
        .widgetList<MetricCard>(find.byType(MetricCard))
        .map((card) => tester.getSize(find.byWidget(card)))
        .toList();
    expect(sizes, hasLength(3));
    expect(sizes.map((size) => size.height).toSet(), {150.0});
  });

  testWidgets('match speed stays on one line and card opens', (tester) async {
    var opened = false;
    final match = MatchSummary.fromMap({
      'title': 'Training Match',
      'date': 'August 6, 2026',
      'minutes': 68,
      'position': 'Left wing',
      'result': 'WIN',
      'score': '2-0',
      'distance': '6.9 km',
      'speed': '26.8 km/h',
      'sprints': 28,
      'color': 'cyan',
    });

    await tester.pumpWidget(
      _testApp(
        HistoryCard(
          match: match,
          selectedPosition: 'Forward',
          onTap: () => opened = true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final speedValue = find.descendant(
      of: find.widgetWithText(HistoryMetric, 'Top Speed'),
      matching: find.byType(FittedBox),
    );
    expect(speedValue, findsOneWidget);
    await tester.tap(find.byType(HistoryCard));
    expect(opened, isTrue);
  });

  testWidgets('section action is a working button', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _testApp(
        SectionHeader(
          title: 'Last Match',
          action: 'View all',
          onAction: () => opened = true,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'View all'));
    expect(opened, isTrue);
  });
}

DashboardMetric _metric(String label, String value) {
  return DashboardMetric.fromMap({
    'icon': 'speed',
    'label': label,
    'value': value,
    'color': 'green',
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}
