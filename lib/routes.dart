import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';


final Map<String, WidgetBuilder> appRoutes = {
  "/login": (context) => LoginScreen(),
  "/register": (context) => RegisterScreen(),
  "/forgot-password": (context) => ForgotPasswordScreen(),
  "/reset-password": (context) => ResetPasswordScreen(email: ''),
};
