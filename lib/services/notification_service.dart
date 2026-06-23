import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows simple LOCAL notifications (created on the device itself, e.g. when an
/// order's status changes while the user is watching it).
///
/// Note: this is NOT Firebase push. Real push from the server would use the
/// firebase_messaging package; the backend already has the FCM service for that.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
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
