import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'forgot_password_screen.dart';
import 'complete_profile_screen.dart';
import '../home_screen.dart';
import 'register_screen.dart';
import 'package:fitness_app/models/registration_data.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;
  bool isPasswordVisible = false;

  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_.-]+$');

  void login() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => isLoading = true);

  bool success = await ApiService.login(
    usernameController.text,
    passwordController.text,
  );

  setState(() => isLoading = false);

  if (success) {
    bool profileCompleted = await ApiService.checkProfileStatus();

    if (profileCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // создаём пустой RegistrationData для передачи
      RegistrationData regData = RegistrationData(
        username: usernameController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CompleteProfileScreen(registrationData: regData),
        ),
      );
    }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleTextColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    final containerBgColor = isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF4F4F4);
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Text(
                    "STRENVY",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildToggleButtons(context, true),
                SizedBox(height: 40),

                /// Обёртка для полей и кнопки логина
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerBgColor, 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor!),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black26 : Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
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
                            style: TextStyle(
                              color: subtleTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildToggleButtons(BuildContext context, bool isLogin) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inactiveColor = isDarkMode ? Color(0xFF3D3D3D) : Colors.brown[100];
  final activeColor = isDarkMode ? Color(0xFF614F36) : Color.fromARGB(255, 199, 169, 127);
  final inactiveTextColor = isDarkMode ? Colors.grey[400] : Colors.brown[700];
  final activeTextColor = isDarkMode ? Colors.white : Colors.black;
  final borderColor = isDarkMode ? Colors.grey[600] : Colors.black;
  
  return Align(
    alignment: Alignment.topCenter,
    child: Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: inactiveColor,
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
                  color: !isLogin ? activeColor : inactiveColor,
                  border: Border.all(
                    color: !isLogin ? borderColor! : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  "Registration",
                  style: TextStyle(
                    color: !isLogin ? activeTextColor : inactiveTextColor,
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
                  color: isLogin ? activeColor : inactiveColor,
                  border: Border.all(
                    color: isLogin ? borderColor! : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: isLogin ? activeTextColor : inactiveTextColor,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final borderColor = isDarkMode ? Colors.grey[600] : const Color.fromARGB(255, 156, 145, 141);
    final labelColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: TextFormField(
        controller: controller,
        cursorColor: primaryColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
        ),
        validator: validator,
      ),

    );
  }

  Widget _buildPasswordField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final borderColor = isDarkMode ? Colors.grey[600] : const Color.fromARGB(255, 156, 145, 141);
    final labelColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 116, 112, 112);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: passwordController,
        cursorColor: primaryColor,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: TextStyle(color: labelColor),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
          suffixIcon: IconButton(
            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                 color: isDarkMode ? Colors.grey[300] : Colors.grey[600]),
            onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
          ),
        ),
        validator: _validatePassword,
      ),

    );
  }

    Widget _buildLoginButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final buttonColor = isDarkMode ? primaryColor : Colors.black;
    final textColor = isDarkMode ? Colors.black : Colors.white;
    
    return ElevatedButton(
      onPressed: isLoading ? null : login,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        minimumSize: Size(double.infinity, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading 
        ? CircularProgressIndicator(color: textColor) 
        : Text("Login"),
    );
  }

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    } else if (value.length < 6 || value.length > 32) {
      return "Password must be between 6 and 32 characters";
    }
    return null;
  }
}
