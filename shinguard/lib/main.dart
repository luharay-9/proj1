import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // Notification registration retries after an authenticated user enters.
  }
  runApp(const ShinPulseApp());
}
