import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../../main.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String username;

  NotificationSettingsScreen({required this.username});

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool notificationsEnabled = false;
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 20, minute: 0);
  int intervalHours = 2;
  int intervalMinutes = 0;
  
  // Gold accent color used throughout the app
  final Color goldAccent = Color(0xFFC7A97F);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled =
          prefs.getBool('notifications_enabled_${widget.username}') ?? false;
      startTime = TimeOfDay(
        hour: prefs.getInt('start_hour_${widget.username}') ?? 9,
        minute: prefs.getInt('start_minute_${widget.username}') ?? 0,
      );
      endTime = TimeOfDay(
        hour: prefs.getInt('end_hour_${widget.username}') ?? 20,
        minute: prefs.getInt('end_minute_${widget.username}') ?? 0,
      );
      intervalHours = prefs.getInt('interval_hours_${widget.username}') ?? 2;
      intervalMinutes =
          prefs.getInt('interval_minutes_${widget.username}') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'notifications_enabled_${widget.username}', notificationsEnabled);
    await prefs.setInt('start_hour_${widget.username}', startTime.hour);
    await prefs.setInt('start_minute_${widget.username}', startTime.minute);
    await prefs.setInt('end_hour_${widget.username}', endTime.hour);
    await prefs.setInt('end_minute_${widget.username}', endTime.minute);
    await prefs.setInt('interval_hours_${widget.username}', intervalHours);
    await prefs.setInt('interval_minutes_${widget.username}', intervalMinutes);

    if (notificationsEnabled) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        await _scheduleNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification permission denied.'),
              ],
            ),
            action: SnackBarAction(
              label: 'SETTINGS',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() {
          notificationsEnabled = false;
        });
      }
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  Future<void> _scheduleNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final Duration interval =
        Duration(hours: intervalHours, minutes: intervalMinutes);

    final tz.TZDateTime windowStart = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, startTime.hour, startTime.minute);
    final tz.TZDateTime windowEnd = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, endTime.hour, endTime.minute);

    tz.TZDateTime firstNotificationTime;
    if (now.isBefore(windowStart)) {
      firstNotificationTime = windowStart;
    } else if (now.isBefore(windowEnd)) {
      final tz.TZDateTime next = now.add(interval);
      firstNotificationTime = tz.TZDateTime.from(next, tz.local);
    } else {
      final tz.TZDateTime tomorrow = windowStart.add(Duration(days: 1));
      firstNotificationTime = tomorrow;
    }

    int id = 0;
    while (firstNotificationTime.isBefore(windowEnd) ||
        firstNotificationTime.isAtSameMomentAs(windowEnd)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id++,
        'Time to drink water!',
        'Stay hydrated 💧',
        firstNotificationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Drink water notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      final tz.TZDateTime next = firstNotificationTime.add(interval);
      firstNotificationTime = tz.TZDateTime.from(next, tz.local);
    }

    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('Pending notifications: $pending');
  }

  Future<void> _pickStartTime() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            dialBackgroundColor: Colors.white,
            dayPeriodBorderSide: BorderSide(color: goldAccent, width: 2),
            dayPeriodColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return goldAccent; // Выбранный период будет золотым
              }
              return Colors.transparent;
            }),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white; // Текст на выбранном периоде будет белым
              }
              return goldAccent; // Невыбранный период будет золотым текстом
            }),
            dayPeriodTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            dialHandColor: goldAccent,
            dialTextColor: Colors.black87, // Всегда черные цифры на циферблате, так как фон белый
            dialTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            hourMinuteColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return goldAccent; // Выбранное поле будет золотым
              }
              return isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
            }),
            hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white; // Текст на выбранном поле будет белым
              }
              return isDarkMode ? Colors.white : Colors.black87; // Цвет зависит от темы
            }),
            hourMinuteTextStyle: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            entryModeIconColor: goldAccent,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: goldAccent),
          ),
          colorScheme: ColorScheme(
            primary: goldAccent,
            primaryContainer: goldAccent,
            secondary: goldAccent,
            secondaryContainer: goldAccent.withOpacity(0.5),
            surface: Theme.of(context).cardColor,
            background: Theme.of(context).scaffoldBackgroundColor,
            error: Colors.red,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: isDarkMode ? Colors.white : Colors.black,
            onBackground: isDarkMode ? Colors.white : Colors.black,
            onError: Colors.white,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => startTime = picked);
      _saveSettings();
    }
  }

  Future<void> _pickEndTime() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            dialBackgroundColor: Colors.white,
            dayPeriodBorderSide: BorderSide(color: goldAccent, width: 2),
            dayPeriodColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return goldAccent; // Выбранный период будет золотым
              }
              return Colors.transparent;
            }),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white; // Текст на выбранном периоде будет белым
              }
              return goldAccent; // Невыбранный период будет золотым текстом
            }),
            dayPeriodTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            dialHandColor: goldAccent,
            dialTextColor: Colors.black87, // Всегда черные цифры на циферблате, так как фон белый
            dialTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            hourMinuteColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return goldAccent; // Выбранное поле будет золотым
              }
              return isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
            }),
            hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white; // Текст на выбранном поле будет белым
              }
              return isDarkMode ? Colors.white : Colors.black87; // Цвет зависит от темы
            }),
            hourMinuteTextStyle: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            entryModeIconColor: goldAccent,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: goldAccent),
          ),
          colorScheme: ColorScheme(
            primary: goldAccent,
            primaryContainer: goldAccent,
            secondary: goldAccent,
            secondaryContainer: goldAccent.withOpacity(0.5),
            surface: Theme.of(context).cardColor,
            background: Theme.of(context).scaffoldBackgroundColor,
            error: Colors.red,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: isDarkMode ? Colors.white : Colors.black,
            onBackground: isDarkMode ? Colors.white : Colors.black,
            onError: Colors.white,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => endTime = picked);
      _saveSettings();
    }
  }

  void _pickInterval() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    // Текущий выбранный интервал в минутах
    int _currentMinutes = intervalHours * 60 + intervalMinutes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Список предустановленных интервалов в минутах
            final List<int> presetIntervals = [30, 60, 90, 120, 150, 180, 240];
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Заголовок
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: goldAccent,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Text(
                        "Select Interval",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Визуальный слайдер интервала
                          Text(
                            "Interval duration:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Текущее значение с большим отображением
                          Container(
                            margin: EdgeInsets.only(bottom: 30),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: goldAccent.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                )
                              ],
                              border: Border.all(
                                color: goldAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 32,
                                      color: goldAccent,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      _formatIntervalDisplay(_currentMinutes),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "between reminders",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Простой слайдер
                          Column(
                            children: [
                              Slider(
                                min: 15,
                                max: 240,
                                divisions: 15, // 15 минутные интервалы
                                value: _currentMinutes.toDouble(),
                                activeColor: goldAccent,
                                inactiveColor: goldAccent.withOpacity(0.2),
                                onChanged: (double value) {
                                  setModalState(() {
                                    _currentMinutes = value.round();
                                  });
                                },
                              ),
                              // Метки интервалов под слайдером
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "15m", 
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "1h", 
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "2h", 
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "4h", 
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Секция быстрого выбора
                          Text(
                            "Quick select:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Бейджи быстрого выбора
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: presetIntervals.map((minutes) {
                              final bool isSelected = _currentMinutes == minutes;
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    _currentMinutes = minutes;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14, 
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? goldAccent 
                                        : isDarkMode 
                                            ? Colors.grey[800] 
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: goldAccent.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 16,
                                        color: isSelected 
                                            ? Colors.white 
                                            : goldAccent,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _formatIntervalDisplay(minutes),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected 
                                              ? Colors.white 
                                              : isDarkMode 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Кнопки действий
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Устанавливаем новый интервал
                            setState(() {
                              intervalHours = _currentMinutes ~/ 60;
                              intervalMinutes = _currentMinutes % 60;
                            });
                            _saveSettings();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Apply",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Форматирование отображения интервала
  String _formatIntervalDisplay(int minutes) {
    if (minutes < 60) {
      return "$minutes min";
    } else if (minutes % 60 == 0) {
      return "${minutes ~/ 60} h";
    } else {
      return "${minutes ~/ 60} h ${minutes % 60} min";
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardBackground = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Settings"),
        centerTitle: true,
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with illustration
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? goldAccent.withOpacity(0.2) 
                              : goldAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.water_drop_rounded,
                          size: 50,
                          color: goldAccent,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Keep yourself hydrated",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Set up reminders to drink water throughout the day",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                
                // Enable/Disable Switch
                Card(
                  elevation: 3,
                  shadowColor: isDarkMode 
                      ? Colors.black.withOpacity(0.3) 
                      : Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? goldAccent.withOpacity(0.2) 
                                    : goldAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: notificationsEnabled ? goldAccent : Colors.grey,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Reminders",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: notificationsEnabled,
                          activeColor: goldAccent,
                          activeTrackColor: goldAccent.withOpacity(0.4),
                          inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[300],
                          inactiveTrackColor: isDarkMode 
                              ? Colors.grey.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.2),
                          onChanged: (value) {
                            setState(() => notificationsEnabled = value);
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Settings Section
                AbsorbPointer(
                  absorbing: !notificationsEnabled,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: notificationsEnabled ? 1 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingsCard(
                          context: context,
                          textColor: textColor,
                          cardBackground: cardBackground,
                        ),
                        SizedBox(height: 24),
                        _buildSummaryCard(context, cardBackground),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context, 
    required Color textColor,
    required Color cardBackground,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 3,
      shadowColor: isDarkMode 
          ? Colors.black.withOpacity(0.3) 
          : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? goldAccent.withOpacity(0.2) 
                        : goldAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings, color: goldAccent, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  "Reminder Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSettingItem(
              title: "Start Time",
              value: _formatTime(startTime),
              icon: Icons.access_time,
              onTap: _pickStartTime,
              textColor: textColor,
              isDarkMode: isDarkMode,
            ),
            Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            _buildSettingItem(
              title: "End Time",
              value: _formatTime(endTime),
              icon: Icons.access_alarm,
              onTap: _pickEndTime,
              textColor: textColor,
              isDarkMode: isDarkMode,
            ),
            Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            _buildSettingItem(
              title: "Interval",
              value: "$intervalHours h $intervalMinutes min",
              icon: Icons.timelapse,
              onTap: _pickInterval,
              textColor: textColor,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? goldAccent.withOpacity(0.2) 
                    : goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: goldAccent, size: 20),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? goldAccent.withOpacity(0.2)
                    : goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: goldAccent,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Color cardBackground) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shadowColor: isDarkMode 
          ? Colors.black.withOpacity(0.2) 
          : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: cardBackground,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: goldAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? goldAccent.withOpacity(0.2) 
                        : goldAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: goldAccent, size: 18),
                ),
                SizedBox(width: 8),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Notifications will be sent from ${_formatTime(startTime)} "
              "to ${_formatTime(endTime)} every ${intervalHours}h ${intervalMinutes}m.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
