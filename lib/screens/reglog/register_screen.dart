import 'package:flutter/material.dart';
import 'complete_profile_screen.dart'; // Страница для заполнения возраста, роста и веса
import 'login_screen.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'package:fitness_app/services/api_service.dart';

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
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isConfirmPasswordVisible = false;


  String? usernameErrorText;
  String? emailErrorText;
  String? confirmPasswordErrorText;
  
  bool gender = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_.-]+$');

 @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: Text(
                  "STRENVY",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildToggleButtons(context, false),
              SizedBox(height: 20),

              // 🔳 Рамка с формой
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F2), // светло-серый фон
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.brown.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField("Username", usernameController,validator: _validateUsername,errorText: usernameErrorText),
                      _buildInputField("Email", emailController,validator: _validateEmail,errorText: emailErrorText),
                      _buildPasswordFields(),
                      _buildInputField("Name", firstNameController, validator: _validateName),
                      _buildInputField("Last Name", lastNameController, validator: _validateName),
                      _buildGenderSwitch(),
                      SizedBox(height: 20),
                      _buildRegisterButton(),
                    ],
                  ),
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
  return Align(
    alignment: Alignment.topCenter,
    child: Container(
      width: double.infinity,
      height: 50,
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
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  color: !isLogin
                      ? Color.fromARGB(255, 199, 169, 127)
                      : const Color.fromARGB(248, 0, 0, 0),
                  border: Border.all(
                    color: !isLogin ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  "Registration",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
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
                  color: isLogin
                      ? Colors.brown[300]
                      : Color.fromARGB(255, 219, 200, 173),
                  border: Border.all(
                    color: isLogin ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: isLogin
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 0, 0),
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




  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        cursorColor: Color.fromARGB(255, 199, 169, 127),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)),
          errorText: errorText, // ⬅ Показываем ошибку
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color.fromARGB(198, 169, 127, 88), width: 2.0),
          ),
          floatingLabelStyle: TextStyle(color: Color.fromARGB(255, 199, 169, 127)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator,
      ),
    );
  }



Widget _buildPasswordFields() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: TextFormField(
          controller: passwordController,
          cursorColor: Color.fromARGB(255, 199, 169, 127),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0),
            ),
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
          ),
          validator: _validatePassword,
        ),
      ),

      // Confirm Password field
      Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: TextFormField(
          controller: confirmPasswordController,
          cursorColor: Color.fromARGB(255, 199, 169, 127),
          obscureText: !isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            labelStyle: TextStyle(color: const Color.fromARGB(255, 116, 112, 112)),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0),
            ),
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ),
    ],
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

                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => gender = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: gender ? Color.fromARGB(255, 199, 169, 127) : Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (gender)
                              Icon(Icons.check, size: 16, color: Theme.of(context).iconTheme.color),
                            SizedBox(width: gender ? 6 : 0),
                            Text(
                              "Male",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => gender = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !gender ? Color.fromARGB(255, 199, 169, 127) : Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!gender)
                              Icon(Icons.check, size: 16, color: Theme.of(context).iconTheme.color),
                            SizedBox(width: !gender ? 6 : 0),
                            Text(
                              "Female",
                              style: TextStyle(
                                fontSize: 14,
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
    onPressed: isLoading
    ? null
    : () async {
        if (!_formKey.currentState!.validate()) return;

        setState(() {
          isLoading = true;
          usernameErrorText = null;
          emailErrorText = null;
          confirmPasswordErrorText = null;
        });

        final email = emailController.text.trim();
        final username = usernameController.text.trim();
        final password = passwordController.text;
        final confirmPassword = confirmPasswordController.text;

        if (password != confirmPassword) {
          setState(() {
            isLoading = false;
            confirmPasswordErrorText = 'Passwords do not match.';
          });
          return;
        }
        bool emailTaken = false;
        bool usernameTaken = false;

        try {
            // Проверка email
            try {
              final emailAvailable = await ApiService.isEmailAvailable(email);
              if (!emailAvailable) emailTaken = true;
            } catch (_) {
              emailTaken = true; // Считаем email занят при ошибке
            }

            // Проверка username
            try {
              final usernameAvailable = await ApiService.isUsernameAvailable(username);
              if (!usernameAvailable) usernameTaken = true;
            } catch (_) {
              usernameTaken = true; // Считаем username занят при ошибке
            }

            if (emailTaken || usernameTaken) {
              setState(() {
                isLoading = false;
                emailErrorText = emailTaken ? "This email is already registered." : null;
                usernameErrorText = usernameTaken ? "This username is already taken." : null;
              });
              return;
            }

          final registrationData = RegistrationData(
            username: username,
            email: email,
            password: passwordController.text,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            gender: gender,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                registrationData: registrationData,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        } finally {
          setState(() => isLoading = false);
        }
      },


    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: isLoading
        ? CircularProgressIndicator(color: Colors.white)
        : Text("Continue", style: TextStyle(fontSize: 16)),
  );
}

}
