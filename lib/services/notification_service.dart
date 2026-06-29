import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Shows simple LOCAL notifications (created on the device itself, e.g. when an
/// order's status changes while the user is watching it).
///
/// Handles Firebase FCM push notification listeners and credentials.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request push notification permissions
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Set up foreground notification handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          show(notification.title ?? '', notification.body ?? '');
        }
      });

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      // Firebase might fail on non-supported platforms or without proper configs
      print('FCM Init Error: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  static Future<String?> getFCMToken() async {
    try {
      await init();
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> show(String title, String body) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'order_updates',
        'Order updates',
        channelDescription: 'Notifications about your order status',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    // Using id 0 means a new update replaces the old one — fine for a demo.
    await _plugin.show(0, title, body, details);
  }
}
