import 'package:flutter/material.dart';
import 'exercises/exercises_screen.dart';
import 'nutrition/sports_nutrition_screen.dart';
import 'calories/calories_screen.dart';

class GuideScreen extends StatelessWidget {
  final List<Map<String, dynamic>> guides = [
    {
      "title": "Exercises",
      "subtitle": "Explore exercises by muscle groups",
      "image": "assets/images/exercises.jpg",
      "route": "exercises",
      "icon": Icons.fitness_center,
    },
    {
      "title": "Sports Nutrition",
      "subtitle": "Supplements and tips",
      "image": "assets/images/nutrition.jpg",
      "route": "nutrition",
      "icon": Icons.spa,
    },
    {
      "title": "Nutritional value of products",
      "subtitle": "Check calories and nutrients",
      "image": "assets/images/calories.jpg",
      "route": "calories",
      "icon": Icons.restaurant_menu,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Guide",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [Color(0xFF121212), Color(0xFF1E1E1E)]
                : [Color(0xFFF9F9F9), Color(0xFFF4F4F4)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: guides.length,
          itemBuilder: (context, index) {
            final guide = guides[index];
            return _buildGuideCard(
              context,
              guide["title"] ?? "",
              guide["subtitle"] ?? "",
              guide["image"] ?? "",
              guide["route"] ?? "",
              guide["icon"] ?? Icons.info_outline,
              isDarkMode,
              goldColor,
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    String imagePath, 
    String route, 
    IconData icon,
    bool isDarkMode,
    Color goldColor,
  ) {
    final borderRadius = BorderRadius.circular(16);
    final topRadius = BorderRadius.vertical(top: Radius.circular(16));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: isDarkMode ? 0 : 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: borderRadius,
        elevation: 0,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            if (route == "exercises") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisesScreen()));
            } else if (route == "nutrition") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SportsNutritionScreen()));
            } else if (route == "calories") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CaloriesScreen()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Page not available yet"),
                  backgroundColor: isDarkMode ? Color(0xFF333333) : goldColor,
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: topRadius,
                child: Stack(
                  children: [
                    // Image with slight darkening
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        imagePath,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: [0.5, 0.95],
                        ),
                      ),
                    ),
                    
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Color(0xFF3A3225)
                            : goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: goldColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Color(0xFF3A3225)
                            : goldColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: goldColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
