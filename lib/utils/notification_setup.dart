import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationSetup {
  
  static Future<void> initialize() async {
    await NotificationService.initialize();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Drink water notifications',
      importance: Importance.max,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings =
        InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }
} 