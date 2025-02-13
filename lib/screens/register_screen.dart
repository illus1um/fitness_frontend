import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void register() async {
    var response = await ApiService.register(
      usernameController.text,
      emailController.text,
      passwordController.text,
    );

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Регистрация успешна! Теперь войдите в систему."),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context); // Вернуться на экран логина
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Ошибка регистрации. Проверьте данные."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Регистрация")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Логин"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: register,
              child: Text("Зарегистрироваться"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Вернуться на экран логина
              child: Text("Уже есть аккаунт? Войти"),
            ),
          ],
        ),
      ),
    );
  }
}
