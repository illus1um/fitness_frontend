import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'home_screen.dart';

class TrainingExperienceScreen extends StatefulWidget {
  @override
  _TrainingExperienceScreenState createState() => _TrainingExperienceScreenState();
}

class _TrainingExperienceScreenState extends State<TrainingExperienceScreen> {
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
          content: Text("Error while maintaining the training level"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final List<Map<String, String>> experiences = [
    {"level": "1", "name": "No experience", "description": "Didn't do any fitness"},
    {"level": "2", "name": "Beginner", "description": "Started recently"},
    {"level": "3", "name": "Experienced", "description": "Have almost 1 year of experience"},
    {"level": "4", "name": "Pro", "description": "Have a lot of experience"},
  ];

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color(255),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 🔹 Центрируем весь Column
        children: [
          Center( // 🔹 Центрируем заголовок
            child: Text(
              "Difficulty level",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          SizedBox(height: 40),

          Expanded(
            child: ListView.separated(
              itemCount: experiences.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final experience = experiences[index];
                return _buildExperienceCard(experience["level"]!, experience["name"]!, experience["description"]!);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildExperienceCard(String level, String name, String description) {
    return GestureDetector(
      onTap: () => setTrainingExperience(name),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 219, 200, 173),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // 🔹 Круглая иконка с номером
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(255, 199, 169, 127),
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 12),

            // 🔹 Описание уровня
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Color.fromARGB(255, 219, 200, 173),
//Color.fromARGB(255, 199, 169, 127)