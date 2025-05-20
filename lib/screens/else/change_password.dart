// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color goldAccent = Color(0xFFC7A97F);

  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Правила пароля
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  
  // Сила пароля от 0 до 100
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_checkPasswordStrength);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Проверяет силу пароля и обновляет индикаторы в реальном времени
  void _checkPasswordStrength() {
    final password = _newPasswordController.text;
    
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasDigit = RegExp(r'\d').hasMatch(password);
      _hasSpecialChar = RegExp(r'[_!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
      
      // Вычисляем силу пароля
      int strength = 0;
      if (_hasMinLength) strength += 25;
      if (_hasUppercase) strength += 25;
      if (_hasDigit) strength += 25;
      if (_hasSpecialChar) strength += 25;
      
      _passwordStrength = strength.toDouble();
    });
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 25) return const Color.fromARGB(255, 206, 84, 75);
    if (strength <= 50) return const Color.fromARGB(255, 180, 124, 40);
    if (strength <= 75) return const Color.fromARGB(255, 208, 191, 35);
    return const Color.fromARGB(255, 66, 152, 69);
  }

  String _getStrengthText(double strength) {
    if (strength <= 25) return "Weak";
    if (strength <= 50) return "Average";
    if (strength <= 75) return "Good";
    return "Strong";
  }

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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Password changed successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text("Failed to change password. Please check your current password."),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFF);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Change Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF121212), Color(0xFF1E1E1E)]
                : [Color(0xFFF9F9F9), Color(0xFFF4F4F4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Вводная информация
                  Container(
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF252A36) : Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: goldAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: goldAccent,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your password must have at least 8 characters, one uppercase letter, one digit, and one special character.",
                            style: TextStyle(
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Форма в карточке
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordField(
                            "Current Password", 
                            _oldPasswordController, 
                            _isOldPasswordVisible, 
                            Icons.lock_outline_rounded,
                            () {
                              setState(() {
                                _isOldPasswordVisible = !_isOldPasswordVisible;
                              });
                            },
                            isDarkMode: isDarkMode,
                          ),
                          SizedBox(height: 20),
                          
                          _buildPasswordField(
                            "New Password", 
                            _newPasswordController, 
                            _isNewPasswordVisible, 
                            Icons.vpn_key_rounded,
                            () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                            isDarkMode: isDarkMode,
                          ),
                          
                          // Индикатор силы пароля
                          if (_newPasswordController.text.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Password Strength:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _getStrengthText(_passwordStrength),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStrengthColor(_passwordStrength),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength / 100,
                                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getStrengthColor(_passwordStrength),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                SizedBox(height: 12),
                                
                                // Требования к паролю
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF252A36) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildRequirementRow(
                                        "At least 8 characters", 
                                        _hasMinLength, 
                                        isDarkMode
                                      ),
                                      SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "At least one uppercase letter", 
                                        _hasUppercase, 
                                        isDarkMode
                                      ),
                                      SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "At least one digit", 
                                        _hasDigit, 
                                        isDarkMode
                                      ),
                                      SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "At least one special character", 
                                        _hasSpecialChar, 
                                        isDarkMode
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          
                          SizedBox(height: 20),
                          
                          _buildPasswordField(
                            "Confirm New Password", 
                            _confirmPasswordController, 
                            _isConfirmPasswordVisible, 
                            Icons.lock_rounded,
                            () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                            isConfirm: true,
                            isDarkMode: isDarkMode,
                          ),
                          
                          SizedBox(height: 36),
                          
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: goldAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _passwordStrength == 100 ? _changePassword : null,
                                    child: Text(
                                      "CHANGE PASSWORD",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    IconData prefixIcon,
    VoidCallback toggleVisibility, {
    bool isConfirm = false,
    required bool isDarkMode,
  }) {
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final focusedBorderColor = goldAccent;
    
    return TextFormField(
      controller: controller,
      cursorColor: goldAccent,
      obscureText: !isPasswordVisible,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
        ),
        floatingLabelStyle: TextStyle(color: goldAccent),
        prefixIcon: Icon(prefixIcon, color: goldAccent),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, 
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          onPressed: toggleVisibility,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.black12 : Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Password is required";
        }
        
        if (isConfirm) {
          if (value != _newPasswordController.text) return "Passwords do not match";
        } else if (label == "New Password") {
          return _validatePassword(value);
        }
        return null;
      },
    );
  }

  Widget _buildRequirementRow(String text, bool isMet, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline : Icons.highlight_off,
          color: isMet ? Colors.green : Colors.red[300],
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
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
