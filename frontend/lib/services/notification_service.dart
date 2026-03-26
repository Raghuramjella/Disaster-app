import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'claim_channel',
    'Claim Updates',
    description: 'Notifications for claim submissions and status updates',
    importance: Importance.high,
  );

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showClaimVerified({
    required String disasterType,
    required double compensation,
  }) async {
    final formatted = '₹${compensation.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'),
          (m) => '${m[1]},',
        )}';

    await _plugin.show(
      1,
      'Claim Verified ✓',
      '$disasterType claim processed. Estimated compensation: $formatted',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
