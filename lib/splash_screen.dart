import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // путь поправь на свой
import 'screens/home_screen.dart';
import 'screens/reglog/login_screen.dart'; // ваш экран логина

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    String? token = await AuthService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Токен есть => кидаем на HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Токена нет => кидаем на LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Крутилка пока проверяем токен
    );
  }
}
