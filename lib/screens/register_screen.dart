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
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool gender = true; // true = Мужской, false = Женский
  bool isLoading = false;
  bool isPasswordVisible = false;

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

    if (response != null) {
      // Автоматический вход в аккаунт после регистрации
      bool loginSuccess = await ApiService.login(usernameController.text, passwordController.text);

      if (loginSuccess) {
        bool profileCompleted = await ApiService.checkProfileStatus();

        // Если профиль уже заполнен, переходим в HomeScreen
        if (profileCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Если профиль не заполнен, переходим в CompleteProfileScreen
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
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleButtons(context, false), // false = активен "Registration"

            SizedBox(height: 32),
            _buildInputField("Username", usernameController),
            _buildInputField("Email", emailController),
            _buildPasswordField(),
            _buildInputField("Name", firstNameController),
            _buildInputField("Last Name", lastNameController),
            _buildGenderSwitch(),
            SizedBox(height: 20),
            _buildRegisterButton(),
          ],
        ),
      ),
        ],
      )
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
                  color: !isLogin ? Color.fromARGB(198, 169, 127, 100) : Colors.transparent,
                ),
                child: Text(
                  "Registration",
                  style: TextStyle(
                    color: !isLogin ? Colors.white : Colors.brown[700],
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
                  color: isLogin ? Colors.brown[300] : Colors.transparent,
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: isLogin ? Colors.white : Colors.brown[700],
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



  Widget _buildInputField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0), // Уменьшаем общий отступ
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Уменьшаем внутренний отступ
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
      ),
      style: TextStyle(fontSize: 16), // Уменьшаем размер шрифта для компактности
    ),
  );
}


  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
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
      ),
    );
  }

  Widget _buildGenderSwitch() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0), // Уменьшенный внешний отступ
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6), // Меньший отступ
        Container(
          height: 40, // Уменьшаем высоту контейнера
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Меньший радиус
            border: Border.all(color: Colors.brown),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => gender = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8), // Уменьшенный внутренний отступ
                    decoration: BoxDecoration(
                      color: gender ? Color.fromARGB(198, 169, 127, 100) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Male",
                        style: TextStyle(
                          fontSize: 14, // Уменьшаем размер шрифта
                          color: gender ? Colors.white :Color.fromRGBO(0, 0, 0, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => gender = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8), // Уменьшенный внутренний отступ
                    decoration: BoxDecoration(
                      color: !gender ? Color.fromARGB(198, 169, 127, 100) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Female",
                        style: TextStyle(
                          fontSize: 14, // Уменьшаем размер шрифта
                          color: !gender ? Colors.white : const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
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
