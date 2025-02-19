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
              onPressed: () => setTrainingProgram("Потеря веса"),
              child: Text("🔥 Потеря веса"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Выносливость"),
              child: Text("🏃‍♂️ Выносливость"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Полное тело"),
              child: Text("💪 Полное тело"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Набор мышечной массы"),
              child: Text("🦾 Набор массы"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Ноги"),
              child: Text("🦵 Ноги"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingProgram("Широкая спина"),
              child: Text("🏋️‍♂️ Широкая спина"),
            ),
          ],
        ),
      ),
    );
  }
}
