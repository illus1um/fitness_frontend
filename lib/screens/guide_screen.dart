import 'package:flutter/material.dart';
import 'exercises_screen.dart';

class GuideScreen extends StatelessWidget {
  final List<Map<String, String>> guides = [
    {"title": "Exercises", "image": "assets/images/exercises.jpg", "route": "exercises"},
    {"title": "Sports Nutrition", "image": "assets/images/nutrition.jpg", "route": "nutrition"},
    {"title": "Caloric Content of Products", "image": "assets/images/calories.jpg", "route": "calories"},
    {"title": "Encyclopedia", "image": "assets/images/encyclopedia.jpg", "route": "encyclopedia"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guide"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: guides.length,
          separatorBuilder: (context, index) => SizedBox(height: 20),
          itemBuilder: (context, index) {
            final guide = guides[index];
            return GestureDetector(
              onTap: () {
                if (guide["route"] == "exercises") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExercisesScreen()),
                  );
                }
              },
              child: _buildGuideCard(guide["title"]!, guide["image"]!),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard(String title, String imagePath) {
  return Container(
    width: double.infinity,
    height: 110,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1), // Цвет тени с прозрачностью
          blurRadius: 6, // Размытие тени
          spreadRadius: 2, // Распределение тени
          offset: Offset(0, 4), // Смещение тени вниз
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ],
    ),
  );
}

}
