import 'package:flutter/material.dart';

class ThemeConstants {
  // Primary colors
  static const Color primaryGold = Color(0xFFC7A97F);
  static const Color primaryDarkGold = Color(0xFFB2996E);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF9F9F9);
  static const Color lightCardBackground = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF212121);
  static const Color lightSubtext = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightShadow = Color(0x1A000000);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252525);
  static const Color darkText = Color(0xFFEEEEEE);
  static const Color darkSubtext = Color(0xFFAAAAAA);
  static const Color darkDivider = Color(0xFF3A3A3A);
  static const Color darkShadow = Color(0x4D000000);
  
  // Common colors
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  
  // Styling constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  
  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 250);
  
  // Elevation
  static const List<BoxShadow> lightElevation = [
    BoxShadow(
      color: lightShadow,
      blurRadius: 6.0,
      spreadRadius: 2.0,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> darkElevation = [
    BoxShadow(
      color: darkShadow,
      blurRadius: 6.0,
      spreadRadius: 2.0,
      offset: Offset(0, 2),
    ),
  ];
  
  // Text styles
  static TextStyle headlineStyle(BuildContext context) => TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).brightness == Brightness.light ? lightText : darkText,
  );
  
  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: primaryGold,
  );
  
  static TextStyle subtitleStyle(BuildContext context) => TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).brightness == Brightness.light ? lightText : darkText,
  );
  
  static TextStyle bodyStyle(BuildContext context) => TextStyle(
    fontSize: 14.0,
    color: Theme.of(context).brightness == Brightness.light ? lightText : darkText,
  );
  
  static TextStyle captionStyle(BuildContext context) => TextStyle(
    fontSize: 12.0,
    color: Theme.of(context).brightness == Brightness.light ? lightSubtext : darkSubtext,
  );
  
  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGold,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
  );
  
  static ButtonStyle secondaryButtonStyle(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: primaryGold,
    side: const BorderSide(color: primaryGold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
  );
  
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryGold,
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  );
} 