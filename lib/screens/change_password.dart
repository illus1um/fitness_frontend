import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    bool success = await ApiService.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password changed successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Вернуться назад
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to change password"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView( // Добавляем прокрутку
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordField("Old Password", _oldPasswordController, _isOldPasswordVisible, () {
                  setState(() {
                    _isOldPasswordVisible = !_isOldPasswordVisible;
                  });
                }),
                SizedBox(height: 12), // Уменьшен отступ
                _buildPasswordField("New Password", _newPasswordController, _isNewPasswordVisible, () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                }),
                SizedBox(height: 12), // Уменьшен отступ
                _buildPasswordField("Confirm New Password", _confirmPasswordController, _isConfirmPasswordVisible, () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                }, isConfirm: true),
                SizedBox(height: 24), // Уменьшен отступ
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 12), // Уменьшена высота кнопки
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), // Уменьшены углы
                          ),
                          onPressed: _changePassword,
                          child: Text("CHANGE", style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isPasswordVisible,
    VoidCallback toggleVisibility, {
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Уменьшена высота
        border: OutlineInputBorder(),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54), // Обычный цвет
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 199, 169, 127), width: 2.0), // Коричневый цвет при фокусе
        ),
        floatingLabelStyle: TextStyle(color: Color.fromARGB(255, 199, 169, 127)), // Коричневый label при фокусе
        suffixIcon: IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (isConfirm && value != _newPasswordController.text) return "Passwords do not match";
        return null;
      },
    );
  }
}
