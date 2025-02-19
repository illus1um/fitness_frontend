import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'training_experience_screen.dart';

class TrainingLocationScreen extends StatefulWidget {
  @override
  _TrainingLocationScreenState createState() => _TrainingLocationScreenState();
}

class _TrainingLocationScreenState extends State<TrainingLocationScreen> {
  String selectedLocation = "";

  void setTrainingLocation(String location) async {
    bool success = await ApiService.setTrainingLocation(location);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainingExperienceScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка при сохранении места тренировки"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выберите место тренировки")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => setTrainingLocation("Home"),
              child: Text("🏠 Home"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setTrainingLocation("Gym"),
              child: Text("🏋️ Gym"),
            ),
          ],
        ),
      ),
    );
  }
}
