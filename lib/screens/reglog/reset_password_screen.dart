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
  final _formKey = GlobalKey<FormState>(); // Ключ формы

  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  
  bool isLoading = false;
  bool isPasswordVisible = false; // Для скрытия пароля

  void verifyCodeAndResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return; // Если данные некорректны, не отправляем запрос
    }

    setState(() => isLoading = true);

    bool codeValid = await ApiService.verifyResetCode(widget.email, codeController.text);

    if (!codeValid) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect code! Try again."), backgroundColor: Colors.red),
      );
      return;
    }

    bool passwordChanged = await ApiService.resetPassword(
      widget.email,
      codeController.text,
      newPasswordController.text,
    );

    setState(() => isLoading = false);

    if (passwordChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("The password has been successfully changed!"), backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong! Try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Text(
                  "Enter the reset code sent to your email and set a new password.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildCodeField(),
                SizedBox(height: 15),
                _buildPasswordField(),
                SizedBox(height: 20),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Поле для ввода кода сброса пароля
  Widget _buildCodeField() {
    return TextFormField(
      controller: codeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "Enter the code",
        labelStyle: TextStyle(color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)), // Обычная граница
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0), // Цвет при фокусе
        ),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: _validateCode,
    );
  }

  /// Поле для ввода нового пароля
  Widget _buildPasswordField() {
    return TextFormField(
      controller: newPasswordController,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: "New Password",
        labelStyle: TextStyle(color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)), // Обычная граница
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0), // Цвет при фокусе
        ),
        suffixIcon: IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: _validatePassword,
    );
  }

  /// Кнопка сброса пароля
  Widget _buildResetButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : verifyCodeAndResetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Reset Password"),
    );
  }

  /// Валидация кода
  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter the reset code";
    } else if (value.length < 4 || value.length > 6) {
      return "Code must be 4-6 digits long";
    }
    return null;
  }

  /// Валидация пароля
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter a new password";
    } else if (value.length < 6 || value.length > 32) {
      return "Password must be between 6 and 32 characters";
    }
    return null;
  }
}
