import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  void sendResetCode() async {
    setState(() {
      isLoading = true;
    });

    bool success = await ApiService.forgotPassword(emailController.text);
    
    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: emailController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка! Проверьте email."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Забыли пароль?")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Введите email"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: sendResetCode,
                    child: Text("Получить код сброса"),
                  ),
          ],
        ),
      ),
    );
  }
}
