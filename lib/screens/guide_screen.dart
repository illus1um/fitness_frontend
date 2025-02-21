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
      height: 120,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 219, 200, 173),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black)),
            ),
          ),
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
