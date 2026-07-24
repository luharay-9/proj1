import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/screens/session_setup_screen.dart';

void main() {
  test('every supported formation contains the selected team size', () {
    for (final teamSize in supportedTeamSizes) {
      final formations = sessionFormationsFor(teamSize);

      expect(formations, hasLength(3));
      for (final formation in formations) {
        expect(formation.teamSize, teamSize);
        expect(formation.spots, hasLength(teamSize));
        expect(formation.spots.first.role, 'Goalkeeper');
      }
    }
  });

  testWidgets('session setup confirms team, formation, and position', (
    tester,
  ) async {
    SessionSetupSelection? confirmedSelection;
    await tester.pumpWidget(
      MaterialApp(
        home: SessionSetupScreen(
          onConfirm: (selection) async {
            confirmedSelection = selection;
          },
        ),
      ),
    );

    await tester.tap(find.text('5v5'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1-2-1'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('formation-spot-goalkeeper')));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(confirmedSelection?.teamSize, 5);
    expect(confirmedSelection?.formation, '1-2-1');
    expect(confirmedSelection?.spot.label, 'Goalkeeper');
  });
}
