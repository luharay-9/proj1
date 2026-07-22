import 'app_data.dart';
import '../data/firestore_mapping.dart';

class ContactSummary {
  const ContactSummary({
    required this.uid,
    required this.displayName,
    required this.profileSubtitle,
    required this.avatar,
  });

  final String uid;
  final String displayName;
  final String profileSubtitle;
  final AvatarData avatar;

  factory ContactSummary.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUid,
  }) {
    return ContactSummary(
      uid: stringFromMap(map, 'uid', fallbackUid),
      displayName: stringFromMap(map, 'displayName', 'Player'),
      profileSubtitle: stringFromMap(map, 'profileSubtitle', ''),
      avatar: AvatarData.fromMap(_nestedMap(map['avatar'])),
    );
  }
}

class FriendRequestData {
  const FriendRequestData({
    required this.fromUid,
    required this.fromUsername,
    required this.profileSubtitle,
    required this.avatar,
  });

  final String fromUid;
  final String fromUsername;
  final String profileSubtitle;
  final AvatarData avatar;

  factory FriendRequestData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUid,
  }) {
    return FriendRequestData(
      fromUid: stringFromMap(map, 'fromUid', fallbackUid),
      fromUsername: stringFromMap(map, 'fromUsername', 'Player'),
      profileSubtitle: stringFromMap(map, 'profileSubtitle', ''),
      avatar: AvatarData.fromMap(_nestedMap(map['avatar'])),
    );
  }
}

class FriendProfileData {
  const FriendProfileData({required this.uid, required this.data});

  final String uid;
  final UserAppData data;
}

Map<String, dynamic> _nestedMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
