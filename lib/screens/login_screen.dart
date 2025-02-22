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
                      style: TextStyle(color: const Color.fromARGB(255, 199, 169, 127), fontWeight: FontWeight.w900),
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


  Widget _buildToggleButtons(BuildContext context, bool isLogin) {
    return Align(
    alignment: Alignment.topCenter, // Фиксируем сверху
    child: Container(
      width: double.infinity, // Растягиваем на всю ширину
      height: 40,
      margin: EdgeInsets.only(top: 40), // Отступ сверху
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
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  color: !isLogin ? Color.fromARGB(255, 199, 127, 127) : Color.fromARGB(255, 219, 200, 173),
                ),
                child: Text(
                  "Registration",
                  style: TextStyle(
                    color: !isLogin ? Colors.white : const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
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
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: isLogin ? Color.fromARGB(255, 199, 169, 127) : const Color.fromARGB(0, 227, 212, 212),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: isLogin ? const Color.fromARGB(255, 0, 0, 0) : Colors.brown[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildInputField(String label, TextEditingController controller, {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)), // Цвет текста метки
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)), // Обычная граница
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88)!, width: 2.0), // Цвет при фокусе
        ),
        fillColor: const Color.fromARGB(255, 255, 255, 255), // Цвет фона при активации
        filled: true, // Включаем заливку
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
            labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)), // Цвет текста метки
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)), // Обычная граница
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88)!, width: 2.0), // Цвет при фокусе
          ),
          fillColor: const Color.fromARGB(255, 255, 255, 255), // Цвет фона при активации
          filled: true, // Включаем заливку
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
          ),
        ),
        validator: _validatePassword,
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 40),
        shape: RoundedRectangleBorder( // Устанавливаем закругление углов
          borderRadius: BorderRadius.circular(12), // Радиус закругления
        ),
      ),
      child: isLoading 
        ? CircularProgressIndicator(color: Colors.white) 
        : Text("Login"),
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

//Color.fromARGB(255, 219, 200, 173), light
//Color.fromARGB(255, 199, 169, 127) dark