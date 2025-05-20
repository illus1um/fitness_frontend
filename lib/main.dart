import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes.dart';
import 'splash_screen.dart';
import 'screens/else/settings.dart';
import 'theme/app_themes.dart';
import 'utils/notification_setup.dart';

/// Точка входа в приложение
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Инициализация часовых поясов
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Almaty'));

  // Инициализация уведомлений
  await NotificationSetup.initialize();

  // Загрузка сохраненных настроек темы
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'Light';
  
  runApp(MyApp(initialTheme: savedTheme));
}

/// Основной класс приложения
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
    _themeMode = AppThemes.stringToThemeMode(widget.initialTheme);
  }

  void _updateTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', AppThemes.themeModeToString(mode));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: _themeMode,
      routes: {
        ...appRoutes,
        '/settings': (_) => SettingsScreen(onThemeChanged: _updateTheme),
      },
      home: SplashScreen(),
    );
  }
}

