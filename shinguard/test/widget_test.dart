import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shinguard/screens/login_screen.dart';

void main() {
  testWidgets('login screen collects email and password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
