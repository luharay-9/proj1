import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/screens/change_password_screen.dart';

void main() {
  testWidgets('offers email reset and current-password change', (tester) async {
    var resetSent = false;
    String? currentPassword;
    String? newPassword;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          sendResetEmail: () async => resetSent = true,
          changePassword: (current, next) async {
            currentPassword = current;
            newPassword = next;
          },
        ),
      ),
    );

    expect(find.text('Verify through email'), findsOneWidget);
    expect(find.text('Change with current password'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send-password-reset')));
    await tester.pump();
    expect(resetSent, isTrue);
    expect(find.text('Password reset email sent.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('current-password')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('new-password')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-new-password')),
      'new-password',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('change-password')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-password')));
    await tester.pump();

    expect(currentPassword, 'old-password');
    expect(newPassword, 'new-password');
    expect(find.text('Password changed successfully.'), findsOneWidget);
  });

  testWidgets('requires matching new passwords', (tester) async {
    var changed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          sendResetEmail: () async {},
          changePassword: (_, _) async => changed = true,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('current-password')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('new-password')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-new-password')),
      'different-password',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('change-password')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-password')));
    await tester.pump();

    expect(find.text('Passwords must match.'), findsOneWidget);
    expect(changed, isFalse);
  });
}
