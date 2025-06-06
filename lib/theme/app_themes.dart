import 'package:flutter/material.dart';

class AppThemes {
  
  static const Color goldAccent = Color(0xFFC7A97F);
  
  static const Color darkGoldAccent = Color(0xFFB2996E);
  
  static ThemeData get light => ThemeData(
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
      selectedItemColor: goldAccent,
      unselectedItemColor: Colors.grey,
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
        const ProgressIndicatorThemeData(color: goldAccent),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 12, 12, 12),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 12, 12, 12),
      foregroundColor: Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
    ),
    cardColor: const Color.fromARGB(255, 12, 12, 12),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: goldAccent,
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
        const ProgressIndicatorThemeData(color: darkGoldAccent),
  );
  
  static ThemeMode stringToThemeMode(String s) {
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

  static String themeModeToString(ThemeMode m) {
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
} 