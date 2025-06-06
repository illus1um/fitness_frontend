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
  
  static const String _scheduledNotificationsKey = 'scheduled_workout_notifications';

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notifications.initialize(
      initializationSettings,
    );
    
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
  
  static Future<void> cancelAllWorkoutNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledIds = prefs.getStringList(_scheduledNotificationsKey) ?? [];
    
    for (final idStr in scheduledIds) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await _notifications.cancel(id);
      }
    }
    
    await prefs.setStringList(_scheduledNotificationsKey, []);
  }
  
  static Future<void> scheduleWorkoutNotifications(List<DateTime> workoutDays, List<DayInfo> plan) async {
    await cancelAllWorkoutNotifications();
    
    final now = _stripTime(DateTime.now());
    
    final List<String> scheduledIds = [];
    
    for (int i = 0; i < workoutDays.length; i++) {
      final workoutDay = workoutDays[i];
      
      if (workoutDay.isBefore(now)) {
        continue;
      }
      
      DayInfo? dayInfo;
      if (i < plan.length) {
        dayInfo = plan[i];
      }
      
      final notificationId = _generateNotificationId();
      
      scheduledIds.add(notificationId.toString());
      
      final scheduledDate = tz.TZDateTime(
        tz.local,
        workoutDay.year,
        workoutDay.month,
        workoutDay.day,
        8,  
        0, 
      );
      
      String title = 'Workout Day!';
      String body = 'Today is your workout day.';
      
      if (dayInfo != null) {
        body = 'Today\'s workout: ${dayInfo.part}';
      }
      
      await _scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scheduledNotificationsKey, scheduledIds);
  }
  
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
  
  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
} 