import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shinguard/data/firebase_data_repository.dart';
import 'package:shinguard/main.dart' as app;
import 'package:shinguard/screens/home_screen.dart';
import 'package:shinguard/screens/insights_screen.dart';
import 'package:shinguard/screens/profile_screen.dart';
import 'package:shinguard/screens/stats_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo mode populates Firebase-backed statistics and care data', (
    tester,
  ) async {
    await app.main();
    await _settle(tester);

    expect(
      FirebaseAuth.instance.currentUser,
      isNotNull,
      reason: 'The simulator must have a signed-in debug account.',
    );
    addTearDown(() => FirebaseDataRepository().disableDemoMode());

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    final settingsTile = find.widgetWithText(SettingsTile, 'Settings');
    await tester.scrollUntilVisible(
      settingsTile,
      350,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(settingsTile);
    await _settle(tester);

    final demoTile = find.widgetWithText(SettingsTile, 'Demo Mode (Debug)');
    await tester.scrollUntilVisible(
      demoTile,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(demoTile);
    await _settle(tester);

    await tester.tap(find.textContaining('Load Demo Data'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Load'));
    await _settle(tester, timeout: const Duration(seconds: 30));

    final errors = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .where((text) => text.startsWith('Unable to load demo data'))
        .toList();
    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(find.text('Update Demo Data'), findsOneWidget);

    Navigator.of(
      tester.element(find.byType(Scaffold).first),
    ).popUntil((route) => route.isFirst);
    await _settle(tester);

    await tester.tap(find.text('Stats').last);
    await _settle(tester);
    final demoMatchTitle = find.text('League Match vs Harbor FC');
    await tester.scrollUntilVisible(
      demoMatchTitle,
      300,
      scrollable: _verticalScrollable(),
    );
    expect(demoMatchTitle, findsWidgets);
    final demoHistoryCard = find.ancestor(
      of: demoMatchTitle.first,
      matching: find.byType(HistoryCard),
    );
    await tester.drag(_verticalScrollable(), const Offset(0, -220));
    await _settle(tester);
    await tester.tap(demoHistoryCard);
    await _settle(tester);
    expect(find.text('Match Overview'), findsOneWidget);
    expect(find.text('Pass Accuracy'), findsOneWidget);
    Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
    await _settle(tester);

    await tester.tap(find.text('Care').last);
    await _settle(tester);
    expect(find.text('Left Quadriceps'), findsOneWidget);
    expect(find.text('Right Calf'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await _settle(tester);
    final metricSizes = find
        .byType(MetricCard)
        .evaluate()
        .map((element) => tester.getSize(find.byWidget(element.widget)))
        .toList();
    expect(metricSizes.map((size) => size.height).toSet(), {150.0});
    final homeViewAll = find.widgetWithText(TextButton, 'View all');
    await _scrollDownUntilFound(tester, homeViewAll);
    await tester.tap(homeViewAll);
    await _settle(tester);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Home').last);
    await _settle(tester);
    final seeAllTips = find.widgetWithText(TextButton, 'See all');
    await _scrollDownUntilFound(tester, seeAllTips);
    await tester.tap(seeAllTips);
    await _settle(tester);
    expect(find.text("Today's Tips"), findsWidgets);
    Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    final achievementsAction = find.widgetWithText(TextButton, 'View all');
    await tester.scrollUntilVisible(
      achievementsAction,
      250,
      scrollable: _verticalScrollable(),
    );
    await tester.drag(_verticalScrollable(), const Offset(0, -120));
    await _settle(tester);
    await tester.tap(achievementsAction);
    await _settle(tester);
    expect(find.byType(AchievementsScreen), findsOneWidget);
  });
}

Finder _verticalScrollable() {
  return find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;
}

Future<void> _scrollDownUntilFound(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(_verticalScrollable(), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target, findsOneWidget);
}

Future<void> _settle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}
