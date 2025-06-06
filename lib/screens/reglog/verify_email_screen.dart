import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'complete_profile_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final RegistrationData registrationData;

  VerifyEmailScreen({required this.registrationData});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  Future<void> _sendVerificationCode() async {
    try {
      await ApiService.sendEmailVerificationCode(widget.registrationData.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code has been sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _sendVerificationCode,
            ),
          ),
        );
      }
    }
  }

  void _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      bool isVerified = await ApiService.verifyEmailCode(
        widget.registrationData.email!,
        codeController.text,
      );

      if (isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(
              registrationData: widget.registrationData,
            ),
          ),
        );
      } else {
        throw Exception('Incorrect verification code. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: e.toString().contains('Too many attempts')
                ? null
                : SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      codeController.clear();
                      _verifyCode();
                    },
                  ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          "Verify Email",
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
                  "Please enter the verification code sent to your email:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.registrationData.email!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildCodeField(),
                SizedBox(height: 20),
                _buildVerifyButton(),
                SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : _sendVerificationCode,
                  child: Text(
                    "Resend Code",
                    style: TextStyle(
                      color: isDarkMode
                          ? Color.fromARGB(255, 199, 169, 127)
                          : Colors.black,
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: "Enter verification code",
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

  Widget _buildVerifyButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final buttonColor = isDarkMode ? primaryColor : Colors.black;
    final textColor = isDarkMode ? Colors.black : Colors.white;
    
    return ElevatedButton(
      onPressed: isLoading ? null : _verifyCode,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? CircularProgressIndicator(color: textColor)
          : Text("Verify Email"),
    );
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter the verification code";
    } else if (value.length < 4 || value.length > 6) {
      return "Code must be 4-6 digits long";
    }
    return null;
  }
} 