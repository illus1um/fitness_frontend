import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'routes.dart';
import 'splash_screen.dart';
import 'screens/else/settings.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === notifications setup ===
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Almaty'));

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
  // ===========================

  // ==== load saved theme ====
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme') ?? 'Light';
  runApp(MyApp(initialTheme: saved));
}

class MyApp extends StatefulWidget {
  final String initialTheme;
  const MyApp({Key? key, required this.initialTheme}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _stringToThemeMode(widget.initialTheme);
  }

  ThemeMode _stringToThemeMode(String s) {
    switch (s) {
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
        return ThemeMode.system;
      case 'Light':
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
      default:
        return 'Light';
    }
  }

  void _updateTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeModeToString(mode));
  }

  @override
  Widget build(BuildContext context) {
    // Light theme
    final light = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color.fromARGB(255, 255, 255, 255),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      cardColor: Colors.white,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color.fromARGB(255, 244, 241, 237),
        selectedItemColor: Color.fromARGB(255, 199, 169, 127),
        unselectedItemColor: Colors.grey,   // цвет невыбранных
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        showUnselectedLabels: true,
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black),
        bodyMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
        titleLarge:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Color(0xFFC7A97F)),
    );

    // Dark theme
    final dark = ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color.fromARGB(255, 12, 12, 12),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: const Color.fromARGB(255, 12, 12, 12),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      cardColor: const Color.fromARGB(255, 12, 12, 12),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color.fromARGB(255, 199, 169, 127),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        titleLarge:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Color(0xFFB2996E)),
    );

    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      routes: {
        ...appRoutes,
        '/settings': (_) => SettingsScreen(onThemeChanged: _updateTheme),
      },
      home: SplashScreen(),
    );
  }
}

