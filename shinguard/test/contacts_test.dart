import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/data/firebase_data_repository.dart';
import 'package:shinguard/models/contact.dart';

void main() {
  test('usernames are normalized for exact Firebase lookup', () {
    expect(normalizeUsername('  Midfield_10  '), 'midfield_10');
    expect(isValidUsername('Midfield_10'), isTrue);
    expect(isValidUsername('bad username'), isFalse);
    expect(isValidUsername('ab'), isFalse);
  });

  test('friend records preserve the connecting uid and profile summary', () {
    final friend = ContactSummary.fromMap({
      'uid': 'friend-uid',
      'displayName': 'Alex7',
      'profileSubtitle': 'U16 · Midfield',
      'avatar': {'type': 'icon', 'value': 'soccer', 'revision': 2},
    }, fallbackUid: 'fallback-uid');

    expect(friend.uid, 'friend-uid');
    expect(friend.displayName, 'Alex7');
    expect(friend.profileSubtitle, 'U16 · Midfield');
    expect(friend.avatar.value, 'soccer');
  });
}
