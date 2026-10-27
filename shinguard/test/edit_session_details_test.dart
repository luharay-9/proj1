import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/screens/edit_session_details_sheet.dart';

void main() {
  testWidgets('session editor only saves editable metadata', (tester) async {
    String? savedTitle;
    String? savedPosition;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<SessionMetadataUpdate>(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditSessionDetailsSheet(
                  initialTitle: 'Original session',
                  initialPosition: 'Midfield',
                  onSave: (title, position) async {
                    savedTitle = title;
                    savedPosition = position;
                  },
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.text('Recorded stats are locked and cannot be changed.'),
      findsOneWidget,
    );
    expect(find.text('Sprints'), findsNothing);
    expect(find.text('Top Speed'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Session name'),
      'Evening finishing practice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Position played'),
      'Striker',
    );
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();

    expect(savedTitle, 'Evening finishing practice');
    expect(savedPosition, 'Striker');
    expect(find.text('Edit session details'), findsNothing);
  });
}
