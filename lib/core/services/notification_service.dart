import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService
{
  static final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

  static Future<void> init() async
  {
    // Use the name of the file in the drawable folder (without .png)
    const androidSettings = AndroidInitializationSettings('notification_icon');
    // iOS settings can be added here
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: settings);
  }

  static Future<void> showProgress(
    int id, int progress, int max, String title, String body) async
  {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'export_channel',
      'Data Exports',
      channelDescription: 'Notifications for data export progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: max,
      progress: progress,
      onlyAlertOnce: true,
      icon: 'notification_icon', // ✅ REQUIRED
    );


    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidPlatformChannelSpecifics),
    );
  }

  static Future<void> showCompletion(int id, String title, String body, String? payload) async
  {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'export_channel',
      'Data Exports',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'notification_icon', // ✅ REQUIRED
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidPlatformChannelSpecifics),
      payload: payload,
    );
  }
}
