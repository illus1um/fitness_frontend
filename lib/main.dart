import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'routes.dart';
import 'splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация часовых поясов
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Almaty'));

  // Создание канала (Android 8.0+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel',                // ID канала
    'Reminders',                       // Название канала
    description: 'Drink water notifications',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Инициализация плагина
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 249, 249),
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          bodyLarge:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black),
          bodyMedium:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
          titleLarge:
              TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        progressIndicatorTheme:
            ProgressIndicatorThemeData(color: Color.fromARGB(255, 199, 169, 127)),
      ),
      routes: appRoutes,
      home: SplashScreen(),
    );
  }
}
