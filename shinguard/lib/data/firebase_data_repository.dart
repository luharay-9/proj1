import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_data.dart';
import '../models/contact.dart';
import '../models/match_summary.dart';
import '../models/muscle_report.dart';
import '../models/training_session.dart';

class FirebaseDataRepository {
  FirebaseDataRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated Firebase user is available.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _firestore.collection('users').doc(_uid);
  }

  Stream<UserAppData> watchUserData() {
    return _userDoc.snapshots().map((snapshot) {
      return UserAppData.fromMap(snapshot.data() ?? const {});
    });
  }

  Stream<List<TrainingSession>> watchSessions() {
    return _orderedUserCollection('sessions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TrainingSession.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<MatchSummary>> watchMatches() {
    return _orderedUserCollection('matches').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchSummary.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<MuscleReport>> watchMuscleReports(String view) {
    return _orderedUserCollection(
      'muscleReports',
    ).where('view', isEqualTo: view).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MuscleReport.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<ContactSummary>> watchFriends() {
    return _userDoc.collection('friends').snapshots().map((snapshot) {
      final friends = snapshot.docs
          .map((doc) => ContactSummary.fromMap(doc.data(), fallbackUid: doc.id))
          .toList();
      friends.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return friends;
    });
  }

  Stream<List<FriendRequestData>> watchFriendRequests() {
    return _userDoc.collection('friendRequests').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => FriendRequestData.fromMap(doc.data(), fallbackUid: doc.id),
          )
          .toList();
    });
  }

  Future<void> saveRecordedSession({
    required DateTime startedAt,
    required Duration duration,
    required String position,
    required int sprints,
    required List<Duration> sprintEvents,
  }) async {
    final sessionId = _userDoc.collection('sessions').doc().id;
    final order = -startedAt.millisecondsSinceEpoch;
    final minutes = (duration.inSeconds / 60).ceil().clamp(1, 9999);
    final date = _dateLabel(startedAt);
    final shortName = '${startedAt.month}/${startedAt.day}';
    final events = <Map<String, dynamic>>[
      {
        'time': '0:00',
        'title': 'Session started',
        'detail': 'BNO085 motion recording began.',
        'value': 'START',
        'icon': 'schedule',
        'color': 'cyan',
      },
      for (var index = 0; index < sprintEvents.length; index++)
        {
          'time': _durationLabel(sprintEvents[index]),
          'title': 'Sprint detected',
          'detail': 'Acceleration crossed the configured BNO threshold.',
          'value': 'Sprint ${index + 1}',
          'icon': 'directions_run',
          'color': 'green',
        },
      {
        'time': _durationLabel(duration),
        'title': 'Session completed',
        'detail': '$sprints acceleration spikes recorded.',
        'value': '$minutes min',
        'icon': 'health_and_safety',
        'color': 'green',
      },
    ];

    final batch = _firestore.batch();
    batch.set(_userDoc.collection('matches').doc(sessionId), {
      'order': order,
      'sessionId': sessionId,
      'title': 'ShinGuard Session',
      'date': date,
      'minutes': minutes,
      'position': position,
      'result': 'COMPLETED',
      'score': '',
      'distance': '0.0 km',
      'speed': '0.0 km/h',
      'sprints': sprints,
      'scoreValue': 0,
      'color': 'green',
      'kicks': 0,
      'goals': 0,
      'assists': 0,
      'tackles': 0,
      'passAccuracy': 0,
      'clearances': 0,
      'saves': 0,
      'goalsConceded': 0,
      'startedAt': Timestamp.fromDate(startedAt),
      'durationSeconds': duration.inSeconds,
    });
    batch.set(_userDoc.collection('sessions').doc(sessionId), {
      'order': order,
      'sessionId': sessionId,
      'shortName': shortName,
      'title': 'ShinGuard Session',
      'date': date,
      'position': position,
      'durationLabel': '$minutes min',
      'durationSeconds': duration.inSeconds,
      'result': 'COMPLETED',
      'topSpeed': 0,
      'sprints': sprints,
      'kicks': 0,
      'typeIcon': 'soccer',
      'events': events,
      'startedAt': Timestamp.fromDate(startedAt),
    });
    batch.update(_userDoc, {
      'matches': FieldValue.increment(1),
      'performance.sprintTotal': FieldValue.increment(sprints),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': 'Player',
      'profileSubtitle': '',
      'usernameLower': '',
      'onboardingComplete': false,
      'friendUids': <String>[],
      'avatar': {'type': 'icon', 'value': 'person', 'revision': 0},
      'athleteProfile': {
        'dominantFoot': '',
        'position': '',
        'height': '',
        'weight': '',
        'club': '',
        'ageGroup': '',
      },
      'matches': 0,
      'goals': 0,
      'avgScore': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'readiness': {
        'label': 'READINESS TODAY',
        'score': 0,
        'progress': 0,
        'status': 'SYNCING',
        'detail': 'Waiting for synced data',
        'recoveryLabel': '',
      },
      'dashboardMetrics': <Map<String, dynamic>>[],
      'tips': <Map<String, dynamic>>[],
      'achievements': <Map<String, dynamic>>[],
      'device': {
        'name': '',
        'status': '',
        'firmware': '',
        'battery': 0,
        'batteryLabel': '',
        'timeRemaining': '',
        'remoteId': '',
        'connected': false,
        'lastSeen': '',
      },
      'performance': {
        'eyebrow': 'Performance',
        'distanceRun': '0',
        'distanceUnit': 'km',
        'distanceDelta': '',
        'trendPoints': <double>[],
        'sprintTotal': 0,
        'sprintZones': <Map<String, dynamic>>[],
      },
      'careRisk': {
        'score': 0,
        'progress': 0,
        'level': 'Syncing',
        'detail': 'Waiting for synced care data.',
      },
    }, SetOptions(merge: true));
  }

  Future<void> saveOnboardingAnswers(Map<String, String> answers) async {
    final athleteAnswers = Map<String, String>.from(answers)
      ..remove('username');
    final profileSubtitle = [
      athleteAnswers['ageGroup'],
      athleteAnswers['position'],
      athleteAnswers['club'],
    ].where((value) => value != null && value.isNotEmpty).join(' · ');

    final username = answers['username'] ?? 'Player';
    await _saveProfileWithUsername(
      username: username,
      profileData: {
        'onboardingComplete': true,
        'profileSubtitle': profileSubtitle,
        'athleteProfile': athleteAnswers,
      },
    );
  }

  Future<void> updateAthleteProfile(Map<String, String> answers) async {
    final athleteAnswers = Map<String, String>.from(answers)
      ..remove('username');
    final profileSubtitle = [
      athleteAnswers['ageGroup'],
      athleteAnswers['position'],
      athleteAnswers['club'],
    ].where((value) => value != null && value.isNotEmpty).join(' · ');

    final username = answers['username'] ?? '';
    if (username.isNotEmpty) {
      await _saveProfileWithUsername(
        username: username,
        profileData: {
          'profileSubtitle': profileSubtitle,
          'athleteProfile': athleteAnswers,
        },
      );
    } else {
      await _userDoc.set({
        'profileSubtitle': profileSubtitle,
        'athleteProfile': athleteAnswers,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> sendFriendRequest(String username) async {
    final normalized = normalizeUsername(username);
    if (!isValidUsername(normalized)) {
      throw const ContactException(
        'Enter a valid username using 3-24 letters, numbers, or underscores.',
      );
    }

    final directorySnapshot = await _firestore
        .collection('usernames')
        .doc(normalized)
        .get();
    final targetUid = directorySnapshot.data()?['uid'] as String?;

    if (targetUid == null || targetUid.isEmpty) {
      throw const ContactException('No user has that username.');
    }
    if (targetUid == _uid) {
      throw const ContactException('You cannot add yourself.');
    }

    final currentSnapshot = await _userDoc.get();
    final currentData = currentSnapshot.data() ?? const <String, dynamic>{};
    final friendUids = List<String>.from(
      (currentData['friendUids'] as Iterable?) ?? const <String>[],
    );
    if (friendUids.contains(targetUid)) {
      throw const ContactException('This user is already your friend.');
    }

    final incomingRequest = await _userDoc
        .collection('friendRequests')
        .doc(targetUid)
        .get();
    if (incomingRequest.exists) {
      throw const ContactException(
        'This user already sent you a request. Review it in Contacts.',
      );
    }

    final requestRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('friendRequests')
        .doc(_uid);
    if ((await requestRef.get()).exists) {
      throw const ContactException('Friend request already sent.');
    }

    final batch = _firestore.batch();
    batch.set(requestRef, {
      'fromUid': _uid,
      'fromUsername': currentData['displayName'] ?? 'Player',
      'profileSubtitle': currentData['profileSubtitle'] ?? '',
      'avatar': currentData['avatar'] ?? const <String, dynamic>{},
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.set(_userDoc.collection('sentFriendRequests').doc(targetUid), {
      'toUid': targetUid,
      'sentAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> acceptFriendRequest(FriendRequestData request) async {
    final currentSnapshot = await _userDoc.get();
    final senderRef = _firestore.collection('users').doc(request.fromUid);
    final senderSnapshot = await senderRef.get();
    if (!senderSnapshot.exists) {
      await ignoreFriendRequest(request.fromUid);
      throw const ContactException('This account is no longer available.');
    }

    final currentData = currentSnapshot.data() ?? const <String, dynamic>{};
    final senderData = senderSnapshot.data() ?? const <String, dynamic>{};
    final batch = _firestore.batch();
    batch.set(_userDoc, {
      'friendUids': FieldValue.arrayUnion([request.fromUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(senderRef, {
      'friendUids': FieldValue.arrayUnion([_uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _userDoc.collection('friends').doc(request.fromUid),
      _contactSummary(request.fromUid, senderData),
    );
    batch.set(
      senderRef.collection('friends').doc(_uid),
      _contactSummary(_uid, currentData),
    );
    batch.delete(_userDoc.collection('friendRequests').doc(request.fromUid));
    batch.delete(senderRef.collection('sentFriendRequests').doc(_uid));
    await batch.commit();
  }

  Future<void> ignoreFriendRequest(String fromUid) async {
    final batch = _firestore.batch();
    batch.delete(_userDoc.collection('friendRequests').doc(fromUid));
    batch.delete(
      _firestore
          .collection('users')
          .doc(fromUid)
          .collection('sentFriendRequests')
          .doc(_uid),
    );
    await batch.commit();
  }

  Future<FriendProfileData> getFriendProfile(String friendUid) async {
    final friendSnapshot = await _firestore
        .collection('users')
        .doc(friendUid)
        .get();
    if (!friendSnapshot.exists) {
      throw const ContactException('This account is no longer available.');
    }
    return FriendProfileData(
      uid: friendUid,
      data: UserAppData.fromMap(friendSnapshot.data()!),
    );
  }

  Future<void> removeFriend(String friendUid) async {
    final friendRef = _firestore.collection('users').doc(friendUid);
    final batch = _firestore.batch();
    batch.set(_userDoc, {
      'friendUids': FieldValue.arrayRemove([friendUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(friendRef, {
      'friendUids': FieldValue.arrayRemove([_uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.delete(_userDoc.collection('friends').doc(friendUid));
    batch.delete(friendRef.collection('friends').doc(_uid));
    await batch.commit();
  }

  Future<void> ensureCurrentUsernameDirectory() async {
    final snapshot = await _userDoc.get();
    final data = snapshot.data();
    final username = data?['displayName'] as String?;
    if (username == null ||
        username.isEmpty ||
        data?['onboardingComplete'] != true) {
      return;
    }
    final normalized = normalizeUsername(username);
    final directory = await _firestore
        .collection('usernames')
        .doc(normalized)
        .get();
    if (directory.data()?['uid'] == _uid &&
        data?['usernameLower'] == normalized) {
      return;
    }
    await _saveProfileWithUsername(username: username, profileData: const {});
  }

  Future<void> saveAvatarIcon(String iconKey) async {
    await _userDoc.set({
      'avatar': {
        'type': 'icon',
        'value': iconKey,
        'revision': DateTime.now().millisecondsSinceEpoch,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> uploadProfilePhoto(
    Uint8List bytes, {
    required String contentType,
  }) async {
    final reference = _storage.ref('users/$_uid/profile/avatar');
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    final downloadUrl = await reference.getDownloadURL();
    await _userDoc.set({
      'avatar': {
        'type': 'photo',
        'value': downloadUrl,
        'revision': DateTime.now().millisecondsSinceEpoch,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveDeviceConnection({
    required String remoteId,
    required String name,
    bool connected = true,
  }) async {
    await _userDoc.set({
      'device': {
        'name': name,
        'status': connected ? 'Connected' : 'Saved',
        'firmware': 'CircuitPython 10',
        'battery': 0,
        'batteryLabel': '',
        'timeRemaining': '',
        'remoteId': remoteId,
        'connected': connected,
        'lastSeen': DateTime.now().toIso8601String(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markDeviceDisconnected() async {
    await _userDoc.set({
      'device': {
        'connected': false,
        'status': 'Disconnected',
        'lastSeen': DateTime.now().toIso8601String(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeDevice() async {
    await _userDoc.set({
      'device': {
        'name': '',
        'status': '',
        'firmware': '',
        'battery': 0,
        'batteryLabel': '',
        'timeRemaining': '',
        'remoteId': '',
        'connected': false,
        'lastSeen': '',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCurrentUserData() async {
    final userSnapshot = await _userDoc.get();
    final usernameLower = userSnapshot.data()?['usernameLower'] as String?;
    final friendSnapshot = await _userDoc.collection('friends').get();
    for (final friend in friendSnapshot.docs) {
      await removeFriend(friend.id);
    }
    await _deleteFriendRequestsForAccount();
    for (final path in ['sessions', 'matches', 'muscleReports']) {
      await _deleteUserCollection(path);
    }
    await _deleteUserCollection('friendRequests');
    await _deleteUserCollection('sentFriendRequests');
    await _deleteUserCollection('friends');
    try {
      await _storage.ref('users/$_uid/profile/avatar').delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
    if (usernameLower != null && usernameLower.isNotEmpty) {
      await _firestore.collection('usernames').doc(usernameLower).delete();
    }
    await _userDoc.delete();
  }

  Future<void> _deleteFriendRequestsForAccount() async {
    final incoming = await _userDoc.collection('friendRequests').get();
    for (final request in incoming.docs) {
      await ignoreFriendRequest(request.id);
    }

    final outgoing = await _userDoc.collection('sentFriendRequests').get();
    for (final request in outgoing.docs) {
      final batch = _firestore.batch();
      batch.delete(
        _firestore
            .collection('users')
            .doc(request.id)
            .collection('friendRequests')
            .doc(_uid),
      );
      batch.delete(request.reference);
      await batch.commit();
    }
  }

  Future<void> _saveProfileWithUsername({
    required String username,
    required Map<String, dynamic> profileData,
  }) async {
    final normalized = normalizeUsername(username);
    if (!isValidUsername(normalized)) {
      throw const ContactException(
        'Use 3-24 letters, numbers, or underscores for your username.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(_userDoc);
      final previousUsername = userSnapshot.data()?['usernameLower'] as String?;
      final usernameRef = _firestore.collection('usernames').doc(normalized);
      final usernameSnapshot = await transaction.get(usernameRef);
      final ownerUid = usernameSnapshot.data()?['uid'] as String?;
      if (usernameSnapshot.exists && ownerUid != _uid) {
        throw const ContactException('That username is already taken.');
      }

      transaction.set(usernameRef, {
        'uid': _uid,
        'displayName': username.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(_userDoc, {
        ...profileData,
        'displayName': username.trim(),
        'usernameLower': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (previousUsername != null &&
          previousUsername.isNotEmpty &&
          previousUsername != normalized) {
        transaction.delete(
          _firestore.collection('usernames').doc(previousUsername),
        );
      }
    });
  }

  Map<String, dynamic> _contactSummary(
    String uid,
    Map<String, dynamic> userData,
  ) {
    return {
      'uid': uid,
      'displayName': userData['displayName'] ?? 'Player',
      'profileSubtitle': userData['profileSubtitle'] ?? '',
      'avatar': userData['avatar'] ?? const <String, dynamic>{},
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _deleteUserCollection(String path) async {
    while (true) {
      final snapshot = await _userDoc.collection(path).limit(450).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Query<Map<String, dynamic>> _orderedUserCollection(String path) {
    return _userDoc.collection(path).orderBy('order');
  }
}

String normalizeUsername(String value) => value.trim().toLowerCase();

bool isValidUsername(String value) {
  return RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(normalizeUsername(value));
}

class ContactException implements Exception {
  const ContactException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _dateLabel(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String _durationLabel(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
