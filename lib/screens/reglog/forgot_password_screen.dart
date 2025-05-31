import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  void sendResetCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    bool success = await ApiService.forgotPassword(emailController.text);

    setState(() => isLoading = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: emailController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка! Проверьте email."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          "Forgot Password?",
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: textColor),
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
                  "Enter your email to receive a password reset code.",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildEmailField(),
                SizedBox(height: 20),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final borderColor = isDarkMode ? Colors.grey[600] : const Color.fromARGB(255, 156, 145, 141);
    final labelColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    final fieldBgColor = isDarkMode ? Color(0xFF333333) : Colors.white;
    
    return TextFormField(
      controller: emailController,
      cursorColor: primaryColor,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: "Email",
        labelStyle: TextStyle(color: labelColor),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        floatingLabelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: fieldBgColor,
      ),  
      validator: _validateEmail,
    );
  }

  Widget _buildResetButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final buttonColor = isDarkMode ? primaryColor : Colors.black;
    final textColor = isDarkMode ? Colors.black : Colors.white;
    
    return ElevatedButton(
      onPressed: isLoading ? null : sendResetCode,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? CircularProgressIndicator(color: textColor) : Text("Send Reset Code"),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }
}
