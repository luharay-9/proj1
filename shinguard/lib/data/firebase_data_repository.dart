import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_data.dart';
import '../models/match_summary.dart';
import '../models/muscle_report.dart';
import '../models/training_session.dart';

class FirebaseDataRepository {
  FirebaseDataRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  Future<void> createUserProfile({
    required String uid,
    required String email,
  }) async {
    final displayName = email.split('@').first.trim();
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName.isEmpty ? 'Player' : displayName,
      'profileSubtitle': '',
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

  Future<void> deleteCurrentUserData() async {
    for (final path in ['sessions', 'matches', 'muscleReports']) {
      await _deleteUserCollection(path);
    }
    await _userDoc.delete();
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
