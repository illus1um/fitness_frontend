import 'package:flutter/material.dart';
import 'exercises/exercises_screen.dart';
import 'nutrition/sports_nutrition_screen.dart';
import 'calories/calories_screen.dart';

class GuideScreen extends StatelessWidget {
  final List<Map<String, String>> guides = [
    {
      "title": "Exercises",
      "subtitle": "Explore exercises by muscle groups",
      "image": "assets/images/exercises.jpg",
      "route": "exercises",
    },
    {
      "title": "Sports Nutrition",
      "subtitle": "Supplements and tips",
      "image": "assets/images/nutrition.jpg",
      "route": "nutrition",
    },
    {
      "title": "Nutritional value of products",
      "subtitle": "Check calories and nutrients",
      "image": "assets/images/calories.jpg",
      "route": "calories",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guide"),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: guides.length,
        itemBuilder: (context, index) {
          final guide = guides[index];
          return _buildGuideCard(
            context,
            guide["title"] ?? "",
            guide["subtitle"] ?? "",
            guide["image"] ?? "",
            guide["route"] ?? "",
          );
        },
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, String title, String subtitle, String imagePath, String route) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          if (route == "exercises") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisesScreen()));
          } else if (route == "nutrition") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SportsNutritionScreen()));
          } else if (route == "calories") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CaloriesScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Page not available yet")),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700]),
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
