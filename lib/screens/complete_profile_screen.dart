import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'training_program_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Ключ формы

  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  bool isLoading = false;

  void saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Если данные некорректны, не отправляем запрос
    }

    setState(() => isLoading = true);

    bool success = await ApiService.updateProfile(
      double.parse(weightController.text),
      double.parse(heightController.text),
      int.parse(ageController.text),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainingProgramScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error when saving the profile"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.from(alpha: 255, red: 255, green: 255, blue: 255),
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
                SizedBox(height: 0),
                Text(
                  "About Your Body",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                SizedBox(height: 100),
                _buildWeightField(),
                SizedBox(height: 30),
                _buildHeightField(),
                SizedBox(height: 30),
                _buildAgeField(),
                SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Поле для ввода веса
  Widget _buildWeightField() {
    return TextFormField(
      controller: weightController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration("Weight (kg)"),
      validator: _validateWeight,
    );
  }

  /// Поле для ввода роста
  Widget _buildHeightField() {
    return TextFormField(
      controller: heightController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration("Height (cm)"),
      validator: _validateHeight,
    );
  }

  /// Поле для ввода возраста
  Widget _buildAgeField() {
    return TextFormField(
      controller: ageController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration("Age"),
      validator: _validateAge,
    );
  }

  /// Кнопка сохранения профиля
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Save"),
    );
  }

  /// Валидация веса
  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter your weight";
    }
    final double? weight = double.tryParse(value);
    if (weight == null || weight < 30 || weight > 300) {
      return "Weight must be between 30 and 300 kg";
    }
    return null;
  }

  /// Валидация роста
  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter your height";
    }
    final double? height = double.tryParse(value);
    if (height == null || height < 100 || height > 250) {
      return "Height must be between 100 and 250 cm";
    }
    return null;
  }

  /// Валидация возраста
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter your age";
    }
    final int? age = int.tryParse(value);
    if (age == null || age < 12 || age > 100) {
      return "Age must be between 12 and 100 years";
    }
    return null;
  }

  /// Стилизация полей ввода
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(255, 156, 145, 141)), // Обычная граница
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color.fromARGB(198, 169, 127, 88), width: 2.0), // Цвет при фокусе
        ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      fillColor: Colors.white,
      filled: true,
    );
  }
}
