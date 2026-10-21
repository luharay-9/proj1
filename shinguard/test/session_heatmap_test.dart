import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/player_position.dart';
import 'package:shinguard/shared/session_heatmap.dart';

void main() {
  testWidgets('route toggles and tapped cells display visit counts on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionHeatmap(
            sessionId: 'test',
            routeStream: Stream.value(const [
              PlayerPosition(
                latitude: 0,
                longitude: 0,
                sensorTimeSeconds: 1,
                satellites: 8,
              ),
              PlayerPosition(
                latitude: 0,
                longitude: 0,
                sensorTimeSeconds: 2,
                satellites: 8,
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 GPS samples · 1 visited areas'), findsOneWidget);
    await tester.tapAt(const Offset(187.5, 178));
    await tester.pump();
    expect(find.text('1 visits · 2 GPS samples'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
