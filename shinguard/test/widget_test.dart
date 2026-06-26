import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/main.dart';

void main() {
  testWidgets('ShinPulse app shows dashboard and navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShinPulseApp());

    expect(find.text('Leo Martinez'), findsOneWidget);
    expect(find.text('ShinPulse'), findsNothing);
    expect(find.text('Timeline'), findsOneWidget);

    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();

    expect(find.text('Injury Care'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);
  });
}
