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
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                SizedBox(height: 12),
                _buildPasswordField("New Password", _newPasswordController, _isNewPasswordVisible, () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                }),
                SizedBox(height: 12),
                _buildPasswordField("Confirm New Password", _confirmPasswordController, _isConfirmPasswordVisible, () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                }, isConfirm: true),
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _changePassword,
                          child: Text("CHANGE", style: TextStyle(color: Colors.white, fontSize: 15, height: 2)),
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
      cursorColor: Color.fromARGB(255, 199, 169, 127),
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Уменьшена высота
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelText: label,
        labelStyle: TextStyle(color: Color.fromARGB(255, 174, 174, 174)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0),
        ),
        floatingLabelStyle: TextStyle(color: Color.fromARGB(255, 199, 169, 127)),
        suffixIcon: IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).iconTheme.color),
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
