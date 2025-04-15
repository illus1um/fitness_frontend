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
            final isActive = guide["route"] == "exercises";
            return GestureDetector(
              onTap: isActive
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExercisesScreen()),
                      );
                    }
                  : null,
              child: _buildGuideCard(guide["title"]!, guide["image"]!, isActive),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard(String title, String imagePath, bool isActive) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.5, // Неактивные кнопки становятся полупрозрачными
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(0, 4),
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
                    color: Colors.black,
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
      ),
    );
  }
}
