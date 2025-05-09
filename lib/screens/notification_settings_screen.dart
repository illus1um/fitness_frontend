import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart';

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
            content: Text('Notification permission denied.'),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          timePickerTheme: TimePickerThemeData(
            dialHandColor: Color.fromARGB(255, 199, 169, 127),
            backgroundColor: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          timePickerTheme: TimePickerThemeData(
            dialHandColor: Color.fromARGB(255, 199, 169, 127),
            backgroundColor: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
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
    final presets = <Map<String, Duration>>[
      {'30 min': Duration(minutes: 30)},
      {'1 h': Duration(hours: 1)},
      {'1 h 30 min': Duration(hours: 1, minutes: 30)},
      {'2 h': Duration(hours: 2)},
      {'2 h 30 min': Duration(hours: 2, minutes: 30)},
      {'3 h': Duration(hours: 3)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: presets.map((preset) {
          final label = preset.keys.first;
          final duration = preset.values.first;
          return ListTile(
            title: Text(label),
            onTap: () {
              setState(() {
                intervalHours = duration.inHours;
                intervalMinutes = duration.inMinutes.remainder(60);
              });
              _saveSettings();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Settings"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reminders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: notificationsEnabled,
                  activeColor: Color.fromARGB(255, 199, 169, 127),
                  inactiveThumbColor: Color.fromARGB(0, 141, 141, 141),
                  inactiveTrackColor:
                      const Color.fromARGB(255, 203, 203, 203),
                  onChanged: (value) {
                    setState(() => notificationsEnabled = value);
                    _saveSettings();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            AbsorbPointer(
              absorbing: !notificationsEnabled,
              child: Opacity(
                opacity: notificationsEnabled ? 1 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      title: "Settings",
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Start Time"),
                          trailing: Text(
                            _formatTime(startTime),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          onTap: _pickStartTime,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("End Time"),
                          trailing: Text(
                            _formatTime(endTime),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          onTap: _pickEndTime,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Interval"),
                          trailing: Text(
                            "$intervalHours h $intervalMinutes min",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          onTap: _pickInterval,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: Text(
                        "Notifications will be sent from ${_formatTime(startTime)} "
                        "to ${_formatTime(endTime)} every ${intervalHours}h ${intervalMinutes}m.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 199, 169, 127),
            ),
          ),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
