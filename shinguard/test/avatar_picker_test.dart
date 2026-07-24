import 'dart:convert';

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

  testWidgets('profile photo crop screen requires an explicit decision', (
    tester,
  ) async {
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(home: ProfilePhotoCropScreen(imageBytes: imageBytes)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('Crop Photo'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
  });
}
