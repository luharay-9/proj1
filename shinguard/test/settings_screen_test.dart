import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/screens/profile_screen.dart';

void main() {
  testWidgets('help and support groups both legal documents', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
  });
}
