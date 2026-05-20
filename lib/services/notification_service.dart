import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  static Future<void> showPunchSuccess(String type) async {
    await _plugin.show(
      0,
      type == 'in' ? '✅ Punched In Successfully' : '✅ Punched Out Successfully',
      'Your attendance has been recorded at ${DateTime.now().toLocal()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'punch_channel',
          'Attendance Punches',
          channelDescription: 'Notifications for punch in/out',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00C2FF),
        ),
      ),
    );
  }

  static Future<void> showPunchFailed(String reason) async {
    await _plugin.show(
      1,
      '❌ Punch Failed',
      reason,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'punch_channel',
          'Attendance Punches',
          channelDescription: 'Notifications for punch in/out',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  static Future<void> showSecurityAlert(String message) async {
    await _plugin.show(
      2,
      '🔐 Security Alert',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'security_channel',
          'Security Alerts',
          channelDescription: 'Security and fraud detection alerts',
          importance: Importance.max,
          priority: Priority.max,
          color: Color(0xFFF59E0B),
        ),
      ),
    );
  }
}
