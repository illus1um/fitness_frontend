import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'training_experience_screen.dart';

class TrainingLocationScreen extends StatefulWidget {
  @override
  _TrainingLocationScreenState createState() => _TrainingLocationScreenState();
}

class _TrainingLocationScreenState extends State<TrainingLocationScreen> {
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
          content: Text("Error saving the training location"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final List<Map<String, String>> locations = [
    {"name": "At home", "image": "assets/images/home.jpg"},
    {"name": "In the gym", "image": "assets/images/gym.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 🔹 Центрируем весь Column
          children: [
            Center( // 🔹 Центрируем заголовок
              child: Text(
                "Where to train?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 40),

            Expanded(
              child: ListView.separated(
                itemCount: locations.length,
                separatorBuilder: (context, index) => SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return _buildLocationCard(location["name"]!, location["image"]!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLocationCard(String name, String imagePath) {
  return GestureDetector(
    onTap: () => setTrainingLocation(name),
    child: Container(
      height: 60, // 🔹 Фиксируем высоту карточки
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 219, 200, 173),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 Текстовое описание
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              width: 100,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    ),
  );
}

}
