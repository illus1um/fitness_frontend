import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

/// Глобальная переменная для работы с уведомлениями
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Класс для настройки системы уведомлений приложения
class NotificationSetup {
  
  /// Инициализирует все службы уведомлений
  static Future<void> initialize() async {
    // Инициализируем сервис уведомлений
    await NotificationService.initialize();

    // Создаем канал для питьевой воды
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

    // Базовые настройки для локальных уведомлений
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings =
        InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }
} 