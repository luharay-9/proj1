import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/app_data.dart';
import 'package:shinguard/screens/avatar_picker_screen.dart';

void main() {
  testWidgets('built-in avatar icons use a separate aligned grid', (
    tester,
  ) async {
    const avatar = AvatarData(type: 'icon', value: 'person', revision: 0);

    await tester.pumpWidget(
      const MaterialApp(home: BuiltInIconPickerScreen(currentAvatar: avatar)),
    );

    expect(find.text('Built-in Icons'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
  });
}
