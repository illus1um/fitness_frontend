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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  
  bool isLoading = false;
  bool isPasswordVisible = false;

  void verifyCodeAndResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          "Reset Password",
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
                  "Enter the reset code sent to your email and set a new password.",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
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

  Widget _buildCodeField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final borderColor = isDarkMode ? Colors.grey[600] : const Color.fromARGB(255, 156, 145, 141);
    final labelColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    final fieldBgColor = isDarkMode ? Color(0xFF333333) : Colors.white;
    
    return TextFormField(
      controller: codeController,
      cursorColor: primaryColor,
      keyboardType: TextInputType.number,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: "Enter the code",
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
      validator: _validateCode,
    );
  }

  Widget _buildPasswordField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final borderColor = isDarkMode ? Colors.grey[600] : const Color.fromARGB(255, 156, 145, 141);
    final labelColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    final fieldBgColor = isDarkMode ? Color(0xFF333333) : Colors.white;
    
    return TextFormField(
      controller: newPasswordController,
      cursorColor: primaryColor,
      obscureText: !isPasswordVisible,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: "New Password",
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
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        floatingLabelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: fieldBgColor,
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildResetButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final buttonColor = isDarkMode ? primaryColor : Colors.black;
    final textColor = isDarkMode ? Colors.black : Colors.white;
    
    return ElevatedButton(
      onPressed: isLoading ? null : verifyCodeAndResetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? CircularProgressIndicator(color: textColor) : Text("Reset Password"),
    );
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter the reset code";
    } else if (value.length < 4 || value.length > 6) {
      return "Code must be 4-6 digits long";
    }
    return null;
  }

  String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return "Password is required";
  } else if (value.length < 8 || value.length > 32) {
    return "Password must be between 8 and 32 characters";
  }

  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
  final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
  final hasDigit = RegExp(r'\d').hasMatch(value);
  final hasSpecialChar = RegExp(r'[_!@#\$%^&*(),.?":{}|<>]').hasMatch(value);

  if (!hasLetter) {
    return "Password must contain at least one letter";
  } else if (!hasUppercase) {
    return "Password must contain at least one uppercase letter";
  } else if (!hasDigit) {
    return "Password must contain at least one digit";
  } else if (!hasSpecialChar) {
    return "Password must contain at least one special character";
  }

  return null;
}

}
