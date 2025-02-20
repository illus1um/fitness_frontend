import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'complete_profile_screen.dart'; // Страница для заполнения возраста, роста и веса
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool gender = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_.-]+$');

  void register() async {
    if (!_formKey.currentState!.validate()) {
      return; // Если валидация не прошла, не отправляем запрос
    }

    setState(() => isLoading = true);

    var response = await ApiService.register(
      usernameController.text,
      emailController.text,
      passwordController.text,
      firstNameController.text,
      lastNameController.text,
      gender,
    );

    if (response != null) {
      bool loginSuccess = await ApiService.login(usernameController.text, passwordController.text);
      if (loginSuccess) {
        bool profileCompleted = await ApiService.checkProfileStatus();
        if (profileCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registration error. Check the data."),
        backgroundColor: Colors.red,
      ));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Добавляем скроллинг
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButtons(context, false),
                SizedBox(height: 100),
                _buildInputField("Username", usernameController, validator: _validateUsername),
                _buildInputField("Email", emailController, validator: _validateEmail),
                _buildPasswordField(),
                _buildInputField("Name", firstNameController, validator: _validateName),
                _buildInputField("Last Name", lastNameController, validator: _validateName),
                _buildGenderSwitch(),
                SizedBox(height: 20),
                _buildRegisterButton(),
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
                  color: !isLogin ? Color.fromARGB(255, 199, 169, 127)  : const Color.fromARGB(248, 0, 0, 0),
                ),
                child: Text(
                  "Registration",
                  style: TextStyle(
                    color: !isLogin ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
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
                  color: isLogin ? Colors.brown[300] : Color.fromARGB(255, 219, 200, 173),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: isLogin ? Colors.white : const Color.fromARGB(255, 0, 0, 0),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color.fromARGB(198, 169, 127, 88), width: 2.0),
          ),
          fillColor: Colors.white,
          filled: true,
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
          labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)),
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

  Widget _buildGenderSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6),
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // Делаем закругление больше
              border: Border.all(color: Colors.brown),
            ),
            child: Row(
              children: [
                // 🔹 Кнопка "Male"
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => gender = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: gender ? Color.fromARGB(255, 199, 169, 127) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (gender) // 🔹 Галочка только если выбран "Male"
                              Icon(Icons.check, size: 16, color: Colors.black),
                            SizedBox(width: gender ? 6 : 0), // 🔹 Отступ между галочкой и текстом
                            Text(
                              "Male",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔹 Кнопка "Female"
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => gender = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !gender ? Color.fromARGB(255, 199, 169, 127) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!gender) // 🔹 Галочка только если выбран "Female"
                              Icon(Icons.check, size: 16, color: Colors.black),
                            SizedBox(width: !gender ? 6 : 0), // 🔹 Отступ между галочкой и текстом
                            Text(
                              "Female",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  /// Валидация email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return "Enter a valid email";
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

  /// Валидация имени и фамилии
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "This field is required";
    } else if (value.length < 1 || value.length > 30) {
      return "Must be between 1 and 30 characters";
    }
    return null;
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : register,
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
        : Text("Registration"),
    );
  }

}
