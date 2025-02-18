import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;

  void verifyCodeAndResetPassword() async {
    setState(() {
      isLoading = true;
    });

    bool codeValid = await ApiService.verifyResetCode(widget.email, codeController.text);

    if (!codeValid) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Неверный код! Попробуйте снова."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool passwordChanged = await ApiService.resetPassword(
      widget.email,
      codeController.text,
      newPasswordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (passwordChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Пароль успешно изменён!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка! Попробуйте снова."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Сброс пароля")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "Введите код из email"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: "Новый пароль"),
              obscureText: true,
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: verifyCodeAndResetPassword,
                    child: Text("Сбросить пароль"),
                  ),
          ],
        ),
      ),
    );
  }
}
