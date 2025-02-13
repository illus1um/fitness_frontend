import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/profile_screen.dart';
import 'package:fitness_app/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() async {
    var response = await ApiService.login(usernameController.text, passwordController.text);
    if (response != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка входа")));
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
            TextField(controller: usernameController, decoration: InputDecoration(labelText: "Логин")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Пароль"), obscureText: true),
            ElevatedButton(onPressed: login, child: Text("Войти")),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
              child: Text("Регистрация"),
            ),
          ],
        ),
      ),
    );
  }
}
