import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'profile_screen.dart';
import 'forgot_password_screen.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';
import 'register_screen.dart'; // Импортируем экран регистрации

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
  setState(() {
    isLoading = true;
  });

  bool success = await ApiService.login(
    usernameController.text,
    passwordController.text,
  );

  setState(() {
    isLoading = false;
  });

  if (success) {
    bool profileCompleted = await ApiService.checkProfileStatus();
    
    if (profileCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ошибка входа. Проверьте логин и пароль."),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Логин"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: Text("Войти"),
                  ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
              ),
              child: Text("Забыли пароль?"),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()), // Переход на экран регистрации
              ),
              child: Text("Нет аккаунта? Зарегистрироваться"),
            ),
          ],
        ),
      ),
    );
  }
}
