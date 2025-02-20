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
        MaterialPageRoute(builder: (context) => TrainingLocationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving the training program"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final List<Map<String, String>> programs = [
    {"abbr": "WL", "name": "Weight loss", "image": "assets/images/weight_loss.jpg"},
    {"abbr": "E", "name": "Endurance", "image": "assets/images/endurance.jpg"},
    {"abbr": "FB", "name": "Full body", "image": "assets/images/full_body.jpg"},
    {"abbr": "GM", "name": "Gain Muscle mass", "image": "assets/images/gain_muscle.jpg"},
    {"abbr": "L", "name": "Legs", "image": "assets/images/legs.jpg"},
    {"abbr": "WB", "name": "Wide back", "image": "assets/images/wide_back.jpg"},
  ];

  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 🔹 Меняем с start на center
        children: [
          Align( // 🔹 Центрируем текст вручную
            alignment: Alignment.center,
            child: Text(
              "Choose training program",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          SizedBox(height: 40), 

          Expanded(
            child: ListView.separated(
              itemCount: programs.length,
              separatorBuilder: (context, index) => SizedBox(height: 20),
              itemBuilder: (context, index) {
                final program = programs[index];
                return _buildProgramCard(program["abbr"]!, program["name"]!, program["image"]!);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProgramCard(String abbr, String name, String imagePath) {
    return GestureDetector(
      onTap: () => setTrainingProgram(name),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 200, 173),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(255, 199, 169, 127),
              ),
              child: Center(
                child: Text(
                  abbr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                width: 80,
                height: 72,
                fit: BoxFit.cover,
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