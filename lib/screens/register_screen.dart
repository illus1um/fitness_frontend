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
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool gender = true; // true = Мужской, false = Женский
  bool isLoading = false;

  void register() async {
    setState(() => isLoading = true);

    var response = await ApiService.register(
      usernameController.text,
      emailController.text,
      passwordController.text,
      firstNameController.text,
      lastNameController.text,
      gender,
    );

    setState(() => isLoading = false);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Регистрация успешна! Теперь войдите в систему."),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
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
            TextField(controller: usernameController, decoration: InputDecoration(labelText: "Логин")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Пароль"), obscureText: true),
            TextField(controller: firstNameController, decoration: InputDecoration(labelText: "Имя")),
            TextField(controller: lastNameController, decoration: InputDecoration(labelText: "Фамилия")),
            Row(
              children: [
                Text("Пол: "),
                DropdownButton<bool>(
                  value: gender,
                  onChanged: (bool? newValue) {
                    setState(() {
                      gender = newValue!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: true, child: Text("Мужской")),
                    DropdownMenuItem(value: false, child: Text("Женский")),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            isLoading ? CircularProgressIndicator() : ElevatedButton(onPressed: register, child: Text("Зарегистрироваться")),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Уже есть аккаунт? Войти")),
          ],
        ),
      ),
    );
  }
}
