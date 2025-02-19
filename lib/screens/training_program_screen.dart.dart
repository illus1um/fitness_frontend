import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'training_location_screen.dart';

class TrainingProgramScreen extends StatefulWidget {
  @override
  _TrainingProgramScreenState createState() => _TrainingProgramScreenState();
}

class _TrainingProgramScreenState extends State<TrainingProgramScreen> {
  void setTrainingProgram(String program) async {
    bool success = await ApiService.setTrainingProgram(program);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainingLocationScreen()), // 🔹 Переход к выбору локации
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка при сохранении программы тренировок"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выберите программу тренировок")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => setTrainingProgram("Weight Loss"),
              child: Text("🔥 Потеря веса"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Endurance"),
              child: Text("🏃‍♂️ Выносливость"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Full Body"),
              child: Text("💪 Полное тело"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Gain Muscle Mass"),
              child: Text("🦾 Набор массы"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Legs"),
              child: Text("🦵 Ноги"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Wide Back"),
              child: Text("🏋️‍♂️ Широкая спина"),
            ),
          ],
        ),
      ),
    );
  }
}
