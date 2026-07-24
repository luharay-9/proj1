import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

const _friendRequestsChannel = AndroidNotificationChannel(
  'friend_requests',
  'Friend requests',
  description: 'Notifications when another ShinPulse athlete adds you.',
  importance: Importance.high,
);

const _sessionReadyChannel = AndroidNotificationChannel(
  'session_ready',
  'Session results',
  description: 'Notifications when ShinGuard session stats are ready.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

enum NotificationDestination { contacts, stats }

NotificationDestination? notificationDestinationFromPayload(
  Map<String, dynamic> payload,
) {
  return switch (payload['type']) {
    'friend_request' => NotificationDestination.contacts,
    'session_ready' => NotificationDestination.stats,
    _ => null,
  };
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationDestination> _destinationController =
      StreamController<NotificationDestination>.broadcast();

  NotificationDestination? _pendingDestination;
  String? _registeredToken;
  String? _registeredUid;
  bool _initialized = false;

  Stream<NotificationDestination> get destinations =>
      _destinationController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_shinpulse'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(
      _friendRequestsChannel,
    );
    await androidNotifications?.createNotificationChannel(_sessionReadyChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteNotificationTap);
    _messaging.onTokenRefresh.listen(
      (token) => unawaited(
        _handleTokenRefresh(token).catchError((_) {
          // The next app start or token refresh will retry registration.
        }),
      ),
    );
    _initialized = true;

    try {
      final localLaunch = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp ?? false) {
        _handlePayload(localLaunch?.notificationResponse?.payload);
      }
    } catch (_) {
      // A launch payload is optional; registration can continue without it.
    }

    try {
      final remoteLaunch = await _messaging.getInitialMessage();
      if (remoteLaunch != null) {
        _handleRemoteNotificationTap(remoteLaunch);
      }
    } catch (_) {
      // A launch payload is optional; registration can continue without it.
    }
  }

  Future<bool> activateForCurrentUser() async {
    if (!_initialized) await initialize();
    final user = _auth.currentUser;
    if (user == null) return false;

    var settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (!_canNotify(settings.authorizationStatus)) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _waitForApplePushToken();
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _storeToken(user.uid, token);
    }
    return true;
  }

  Future<bool> notificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return _canNotify(settings.authorizationStatus);
  }

  Future<void> unregisterCurrentDevice() async {
    final user = _auth.currentUser;
    String? token = _registeredToken;
    try {
      token ??= await _messaging.getToken();
    } catch (_) {
      token = _registeredToken;
    }

    if (user != null && token != null && token.isNotEmpty) {
      try {
        await _tokenDocument(user.uid, token).delete();
      } catch (_) {
        // Invalidating the local token still prevents delivery to this device.
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Signing out must remain possible while notification services are down.
    }
    _registeredToken = null;
    _registeredUid = null;
  }

  Future<void> showSessionReady({
    required String sessionId,
    required int sprints,
  }) async {
    final sprintLabel = sprints == 1 ? '1 sprint' : '$sprints sprints';
    await _showLocalNotification(
      id: _notificationId(sessionId),
      title: 'Session stats ready',
      body: '$sprintLabel processed. Tap to view your performance stats.',
      channel: _sessionReadyChannel,
      threadIdentifier: 'session-results',
      payload: {'type': 'session_ready', 'sessionId': sessionId},
    );
  }

  NotificationDestination? takePendingDestination() {
    final destination = _pendingDestination;
    _pendingDestination = null;
    return destination;
  }

  void clearPendingDestination() {
    _pendingDestination = null;
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;
    final type = data['type'];
    final channel = type == 'friend_request'
        ? _friendRequestsChannel
        : _sessionReadyChannel;
    await _showLocalNotification(
      id: _notificationId(message.messageId ?? jsonEncode(data)),
      title: notification?.title ?? data['title'] ?? 'ShinPulse update',
      body: notification?.body ?? data['body'] ?? 'Open ShinPulse for details.',
      channel: channel,
      threadIdentifier: type == 'friend_request'
          ? 'friend-requests'
          : 'shinpulse-updates',
      payload: data,
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    required String threadIdentifier,
    required Map<String, dynamic> payload,
  }) {
    return _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_shinpulse',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: threadIdentifier,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    final previousToken = _registeredToken;
    final previousUid = _registeredUid;
    await _storeToken(user.uid, token);
    if (previousToken != null &&
        previousToken != token &&
        previousUid == user.uid) {
      try {
        await _tokenDocument(user.uid, previousToken).delete();
      } catch (_) {
        // Invalid registrations are also pruned by the sending function.
      }
    }
  }

  Future<void> _storeToken(String uid, String token) async {
    await _tokenDocument(uid, token).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _registeredUid = uid;
    _registeredToken = token;
  }

  DocumentReference<Map<String, dynamic>> _tokenDocument(
    String uid,
    String token,
  ) {
    final tokenId = base64UrlEncode(utf8.encode(token)).replaceAll('=', '');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(tokenId);
  }

  Future<void> _waitForApplePushToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await _messaging.getAPNSToken() != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  bool _canNotify(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  void _handleRemoteNotificationTap(RemoteMessage message) {
    _queueDestination(notificationDestinationFromPayload(message.data));
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      _queueDestination(notificationDestinationFromPayload(data));
    } catch (_) {
      // Ignore malformed notification payloads rather than blocking startup.
    }
  }

  void _queueDestination(NotificationDestination? destination) {
    if (destination == null) return;
    _pendingDestination = destination;
    _destinationController.add(destination);
  }

  int _notificationId(String seed) => seed.hashCode & 0x7fffffff;
}
