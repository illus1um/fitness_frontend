import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/day_info.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'workout_reminder_channel';
  static const String _channelName = 'Workout Reminders';
  static const String _channelDescription = 'Notifications for workout days';
  
  // Ключ для сохранения ID запланированных уведомлений
  static const String _scheduledNotificationsKey = 'scheduled_workout_notifications';

  // Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notifications.initialize(
      initializationSettings,
    );
    
    // Создаем канал для Android
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Отмена всех запланированных уведомлений
  static Future<void> cancelAllWorkoutNotifications() async {
    // Получаем сохраненные ID
    final prefs = await SharedPreferences.getInstance();
    final scheduledIds = prefs.getStringList(_scheduledNotificationsKey) ?? [];
    
    // Отменяем каждое уведомление
    for (final idStr in scheduledIds) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await _notifications.cancel(id);
      }
    }
    
    // Очищаем список ID
    await prefs.setStringList(_scheduledNotificationsKey, []);
  }
  
  // Планирование уведомлений для тренировочных дней
  static Future<void> scheduleWorkoutNotifications(List<DateTime> workoutDays, List<DayInfo> plan) async {
    // Сначала отменяем существующие уведомления
    await cancelAllWorkoutNotifications();
    
    // Текущая дата (без времени)
    final now = _stripTime(DateTime.now());
    
    // Список сохраняемых ID уведомлений
    final List<String> scheduledIds = [];
    
    // Добавляем уведомления для каждого будущего дня тренировки
    for (int i = 0; i < workoutDays.length; i++) {
      final workoutDay = workoutDays[i];
      
      // Пропускаем прошедшие дни
      if (workoutDay.isBefore(now)) {
        continue;
      }
      
      // Находим информацию о дне тренировки
      DayInfo? dayInfo;
      if (i < plan.length) {
        dayInfo = plan[i];
      }
      
      // Создаем уникальный ID для уведомления
      final notificationId = _generateNotificationId();
      
      // Сохраняем ID
      scheduledIds.add(notificationId.toString());
      
      // Создаем время уведомления (8:00 утра в день тренировки)
      final scheduledDate = tz.TZDateTime(
        tz.local,
        workoutDay.year,
        workoutDay.month,
        workoutDay.day,
        8,  // 8 часов утра
        0,  // 0 минут
      );
      
      // Создаем содержимое уведомления
      String title = 'День тренировки!';
      String body = 'Сегодня день вашей тренировки.';
      
      if (dayInfo != null) {
        body = 'Сегодня день тренировки: ${dayInfo.part}';
      }
      
      // Планируем уведомление
      await _scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    }
    
    // Сохраняем список ID запланированных уведомлений
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scheduledNotificationsKey, scheduledIds);
  }
  
  // Метод для генерации уникального ID уведомления
  static int _generateNotificationId() {
    return Random().nextInt(1000000);
  }
  
  // Планирование отдельного уведомления
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFC7A97F),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // Удаляет время из даты
  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
} 