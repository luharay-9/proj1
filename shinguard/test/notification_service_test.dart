import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/services/notification_service.dart';

void main() {
  test('friend request notifications open contacts', () {
    expect(
      notificationDestinationFromPayload({'type': 'friend_request'}),
      NotificationDestination.contacts,
    );
  });

  test('processed session notifications open stats', () {
    expect(
      notificationDestinationFromPayload({'type': 'session_ready'}),
      NotificationDestination.stats,
    );
  });

  test('unknown notification payloads do not navigate', () {
    expect(notificationDestinationFromPayload({'type': 'unknown'}), isNull);
  });
}
