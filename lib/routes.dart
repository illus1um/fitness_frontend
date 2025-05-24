import 'package:flutter/material.dart';
import 'screens/reglog/login_screen.dart';
import 'screens/reglog/register_screen.dart';
import 'screens/reglog/forgot_password_screen.dart';
import 'screens/reglog/reset_password_screen.dart';
import 'screens/settings/settings_screen.dart';


final Map<String, WidgetBuilder> appRoutes = {
  "/login": (context) => LoginScreen(),
  "/register": (context) => RegisterScreen(),
  "/forgot-password": (context) => ForgotPasswordScreen(),
  "/reset-password": (context) => ResetPasswordScreen(email: ''),
  "/settings": (context) => SettingsScreen(),
};
