import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'training_program_screen.dart.dart';

class CompleteProfileScreen extends StatefulWidget {
  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool isLoading = false;

  void saveProfile() async {
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
        SnackBar(content: Text("Ошибка при сохранении профиля"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Заполните профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: "Вес (кг)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: heightController,
              decoration: InputDecoration(labelText: "Рост (см)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: "Возраст"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveProfile,
                    child: Text("Сохранить"),
                  ),
          ],
        ),
      ),
    );
  }
}
