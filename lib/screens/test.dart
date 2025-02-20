import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'forgot_password_screen.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Ключ для формы

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;
  bool isPasswordVisible = false;

  // Регулярное выражение для username (разрешены буквы, цифры, _, -, .)
  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_.-]+$');

  void login() async {
    if (!_formKey.currentState!.validate()) {
      return; // Если валидация не пройдена, отменяем вход
    }

    setState(() => isLoading = true);

    bool success = await ApiService.login(
      usernameController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (success) {
      bool profileCompleted = await ApiService.checkProfileStatus();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => profileCompleted ? HomeScreen() : CompleteProfileScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login error. Check your username and password."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Добавляем скроллинг
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // Закрываем клавиатуру при скролле
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Связываем форму с ключом
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButtons(context, true), // true = активен "Login"
                SizedBox(height: 100),
                _buildInputField("Username", usernameController, validator: _validateUsername),
                _buildPasswordField(),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                    ),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Кнопка переключения между "Login" и "Registration"
  Widget _buildToggleButtons(BuildContext context, bool isLogin) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        height: 40,
        margin: EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.brown[100],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isLogin) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  }
                },
                child: Center(child: Text("Registration")),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isLogin) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
                child: Center(child: Text("Login")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Поле для ввода текста с валидацией
  Widget _buildInputField(String label, TextEditingController controller, {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator, // Проверка данных
      ),
    );
  }

  /// Поле для ввода пароля с валидацией
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
          ),
        ),
        validator: _validatePassword, // Проверка пароля
      ),
    );
  }

  /// Кнопка входа
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Login"),
    );
  }

  /// Валидация username
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Username is required";
    } else if (value.length < 3 || value.length > 20) {
      return "Username must be between 3 and 20 characters";
    } else if (!usernameRegExp.hasMatch(value)) {
      return "Only letters, numbers, '_', '-', and '.' allowed";
    }
    return null;
  }

  /// Валидация пароля
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    } else if (value.length < 6 || value.length > 32) {
      return "Password must be between 6 and 32 characters";
    }
    return null;
  }
}
