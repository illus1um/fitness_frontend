import 'package:flutter/material.dart';
import 'exercises_screen.dart';
import 'sports_nutrition_screen.dart';
import 'calories_screen.dart';

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
    "title": "Caloric Content of Products",
    "subtitle": "Check calories and nutrients",
    "image": "assets/images/calories.jpg", // не забудь добавить изображение
    "route": "calories",
  },
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
            final title = guide["title"] ?? "";
            final image = guide["image"] ?? "";
            final route = guide["route"] ?? "";

            return GestureDetector(
              onTap: () {
                if (route == "exercises") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExercisesScreen()),
                  );
                } else if (route == "nutrition") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SportsNutritionScreen()),
                  );
                } else if (route == "calories") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CaloriesScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Page not available yet")),
                  );
                }
              },

              child: _buildGuideCard(title, image),
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
    );
  }
}
