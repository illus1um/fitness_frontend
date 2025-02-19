import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'home_screen.dart';

class FitnessGoalScreen extends StatefulWidget {
  @override
  _FitnessGoalScreenState createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  List<String> goals = [
    "Weight Loss",
    "Endurance",
    "Full Body",
    "Gain Muscle Mass",
    "Legs",
    "Wide Back"
  ];
  
  void selectGoal(String goal) async {
    bool success = await ApiService.setFitnessGoal(goal);
    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при сохранении цели"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выберите вашу цель")),
      body: ListView.builder(
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(goals[index]),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => selectGoal(goals[index]),
          );
        },
      ),
    );
  }
}
