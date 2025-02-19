import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'home_screen.dart';

class TrainingExperienceScreen extends StatefulWidget {
  @override
  _TrainingExperienceScreenState createState() => _TrainingExperienceScreenState();
}

class _TrainingExperienceScreenState extends State<TrainingExperienceScreen> {
  String selectedExperience = "";

  void setTrainingExperience(String experience) async {
    bool success = await ApiService.setTrainingExperience(experience);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка при сохранении уровня подготовки"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выберите уровень подготовки")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => setTrainingExperience("Нету опыта"),
              child: Text("🥉 Нету опыта"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingExperience("Новичок"),
              child: Text("🥈 Новичок"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingExperience("Опытный"),
              child: Text("🥇 Опытный"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingExperience("Pro"),
              child: Text("🏆 Pro"),
            ),
          ],
        ),
      ),
    );
  }
}
