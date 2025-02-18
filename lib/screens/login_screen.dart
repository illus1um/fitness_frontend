import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/profile_screen.dart';
import 'package:fitness_app/screens/register_screen.dart';
import 'package:fitness_app/screens/forgot_password_screen.dart';

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

    var response = await ApiService.login(
      usernameController.text,
      passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
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
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              ),
              child: Text("Нет аккаунта? Зарегистрироваться"),
            ),
          ],
        ),
      ),
    );
  }
}
