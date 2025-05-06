import 'package:flutter/material.dart';

class SportsNutritionScreen extends StatelessWidget {
  final List<Map<String, String>> supplements = [
    {
      "title": "Protein",
      "image": "assets/supplements/protein.jpg",
      "details": "Protein supplements help support muscle repair and growth. "
          "Recommended intake: 1.6–2.2 g/kg of body weight per day. "
          "Take post-workout or as a meal supplement. "
          "Not recommended for individuals with kidney disease without doctor supervision."
    },
    {
      "title": "Creatine",
      "image": "assets/supplements/creatine.jpg",
      "details": "Creatine increases strength and muscle mass. "
          "Standard dose: 5g per day, can start with a loading phase (20g/day for 5-7 days). "
          "Drink with plenty of water. Not suitable for people with kidney issues or high blood pressure without consulting a doctor."
    },
    {
      "title": "BCAA",
      "image": "assets/supplements/bcaa.jpg",
      "details": "BCAAs help reduce muscle soreness and fatigue. "
          "Dosage: 5–10g before or after a workout. "
          "Not necessary if you get enough protein from food."
    },
    {
      "title": "Vitamins",
      "image": "assets/supplements/vitamins.jpg",
      "details": "Multivitamins fill dietary gaps. "
          "Take once daily with food. "
          "Consult a doctor if you’re on medication or pregnant."
    },
    {
      "title": "Omega-3",
      "image": "assets/supplements/omega3.jpg",
      "details": "Supports heart and joint health. "
          "Dose: 250–500mg of EPA and DHA per day. "
          "Avoid high doses if you’re on blood thinners."
    },
    {
      "title": "Pre-Workout",
      "image": "assets/supplements/preworkout.jpg",
      "details": "Boosts energy and focus for workouts. "
          "Take 20-30 minutes before training. "
          "Not for those sensitive to caffeine or with heart conditions."
    },
    {
      "title": "Gainer",
      "image": "assets/supplements/gainer.jpg",
      "details": "High-calorie supplement for gaining mass. "
          "Use post-workout or between meals. "
          "May cause fat gain if calorie surplus is too high."
    },
    {
      "title": "Collagen",
      "image": "assets/supplements/collagen.jpg",
      "details": "Supports skin, joints, and bones. "
          "Take 5–10g daily. "
          "Combine with vitamin C for better absorption."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sports Nutrition")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: supplements.length,
        itemBuilder: (context, index) {
          final supplement = supplements[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplementDetailScreen(supplement: supplement),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      supplement["image"]!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      supplement["title"]!,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SupplementDetailScreen extends StatelessWidget {
  final Map<String, String> supplement;

  const SupplementDetailScreen({Key? key, required this.supplement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(supplement["title"]!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              supplement["image"]!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              supplement["details"]!,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
