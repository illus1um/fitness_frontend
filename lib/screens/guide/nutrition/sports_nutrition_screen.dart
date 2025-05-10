import 'package:flutter/material.dart';

class SportsNutritionScreen extends StatelessWidget {
  final List<Map<String, String>> supplements = [
    {
      "title": "Protein",
      "image": "assets/supplements/protein.jpg",
      "details": "What it is:\n"
          "Protein supplements are concentrated sources of dietary protein from animal or plant origins.\n\n"
          "Purpose:\n"
          "Support muscle repair, growth, and recovery. Essential for athletes and active individuals.\n\n"
          "How to take:\n"
          "1.6–2.2 g per kg of body weight daily. Ideal post-workout or between meals.\n\n"
          "Who should avoid it:\n"
          "People with kidney disease (consult a doctor first).\n\n"
          "Additional facts:\n"
          "Whey absorbs fast (great after workouts), casein digests slowly (ideal before bed)."
    },
    {
      "title": "Creatine",
      "image": "assets/supplements/creatine.jpg",
      "details": "What it is:\n"
          "Creatine is a naturally occurring compound in muscles that helps regenerate ATP for explosive activities.\n\n"
          "Purpose:\n"
          "Increase strength, power, and muscle mass. Ideal for high-intensity training.\n\n"
          "How to take:\n"
          "3–5 g daily. Optional loading phase: 20 g/day for 5–7 days, then maintain.\n\n"
          "Who should avoid it:\n"
          "Individuals with kidney issues or dehydration risk.\n\n"
          "Additional facts:\n"
          "Best taken post-workout with carbs. Monohydrate is the safest and most effective form."
    },
    {
      "title": "BCAA",
      "image": "assets/supplements/bcaas.jpg",
      "details": "What it is:\n"
          "BCAAs (leucine, isoleucine, valine) are essential amino acids that support muscle metabolism.\n\n"
          "Purpose:\n"
          "Stimulate muscle protein synthesis, reduce soreness, and prevent muscle breakdown.\n\n"
          "How to take:\n"
          "5–10 g before, during, or after workouts. Especially useful when training fasted.\n\n"
          "Who should avoid it:\n"
          "Individuals with ALS or maple syrup urine disease.\n\n"
          "Additional facts:\n"
          "Helpful during cutting or intense training. Found naturally in protein-rich foods."
    },
    {
      "title": "Vitamins",
      "image": "assets/supplements/vitamins.jpg",
      "details": "What it is:\n"
          "Organic compounds required for energy, immunity, and cellular function. Often taken as multivitamins.\n\n"
          "Purpose:\n"
          "Cover nutritional gaps, boost immunity, and support metabolism.\n\n"
          "How to take:\n"
          "Take daily with meals. Follow dosage instructions carefully.\n\n"
          "Who should avoid it:\n"
          "Avoid mega-doses, especially fat-soluble vitamins (A, D, E, K) to prevent toxicity.\n\n"
          "Additional facts:\n"
          "Athletes may need more due to stress and nutrient loss from sweat. Consider testing vitamin D levels."
    },
    {
      "title": "Omega-3",
      "image": "assets/supplements/omega3.jpg",
      "details": "What it is:\n"
          "Omega-3 fatty acids (EPA and DHA) are essential fats found mainly in fish oil.\n\n"
          "Purpose:\n"
          "Support heart health, reduce inflammation, improve brain function, and promote joint health.\n\n"
          "How to take:\n"
          "1–3 g of combined EPA and DHA daily, preferably with meals that contain fat.\n\n"
          "Who should avoid it:\n"
          "Individuals on blood-thinning medications should consult a doctor first.\n\n"
          "Additional facts:\n"
          "Helps with recovery and reduces muscle soreness. Choose supplements with high EPA/DHA ratio and certified purity."
    },
    {
      "title": "Pre-Workout",
      "image": "assets/supplements/preworkout.jpg",
      "details": "What it is:\n"
          "Pre-workout supplements usually contain caffeine, beta-alanine, citrulline, and other performance enhancers.\n\n"
          "Purpose:\n"
          "Increase energy, focus, blood flow, and endurance during training.\n\n"
          "How to take:\n"
          "1 scoop (based on label) 20–30 minutes before exercise. Start with a half dose to assess tolerance.\n\n"
          "Who should avoid it:\n"
          "Those with heart conditions, high blood pressure, or caffeine sensitivity.\n\n"
          "ℹAdditional facts:\n"
          "Avoid taking late in the evening to prevent sleep issues. Stay hydrated and avoid stacking with other stimulants."
    },
    {
      "title": "Gainer",
      "image": "assets/supplements/gainer.jpg",
      "details": "What it is:\n"
          "Mass gainers are high-calorie supplements containing protein, carbs, and fats to promote weight and muscle gain.\n\n"
          "Purpose:\n"
          "Support muscle growth in hard gainers or during bulking phases.\n\n"
          "How to take:\n"
          "1–2 servings per day between meals or post-workout. Mix with milk for extra calories.\n\n"
          "Who should avoid it:\n"
          "Those with insulin resistance, diabetes, or who gain fat easily.\n\n"
          "Additional facts:\n"
          "Choose products with quality ingredients (complex carbs, whey protein). Combine with resistance training for best results."
    },
    {
      "title": "Collagen",
      "image": "assets/supplements/collagen.jpg",
      "details": "What it is:\n"
          "Collagen is the most abundant protein in the body, supporting skin, joints, hair, and connective tissues.\n\n"
          "Purpose:\n"
          "Promotes joint health, skin elasticity, and injury recovery. Popular among athletes and older adults.\n\n"
          "How to take:\n"
          "5–10 g daily, often mixed in coffee, smoothies, or water. Best taken with vitamin C for absorption.\n\n"
          "Who should avoid it:\n"
          "People with specific allergies (e.g. marine collagen) or on strict vegetarian/vegan diets.\n\n"
          "Additional facts:\n"
          "Hydrolyzed (peptides) form is easier to absorb. May reduce joint pain and support tendon recovery over time."
    },
    {
      "title": "ZMA",
      "image": "assets/supplements/zma.jpg",
      "details": "What it is:\n"
          "ZMA combines zinc, magnesium aspartate, and vitamin B6. Supports recovery and sleep.\n\n"
          "Purpose:\n"
          "Improve sleep quality, support testosterone levels, and enhance muscle recovery.\n\n"
          "How to take:\n"
          "1 dose 30–60 min before bed on an empty stomach. Avoid calcium with it.\n\n"
          "Who should avoid it:\n"
          "Anyone taking other zinc/magnesium supplements or with stomach sensitivity.\n\n"
          "Additional facts:\n"
          "May cause vivid dreams. Helps athletes under intense training stress recover better."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodyLarge!
        .copyWith(fontSize: 20, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sports Nutrition'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: supplements.length,
        itemBuilder: (context, index) {
          final supplement = supplements[index];
          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SupplementDetailScreen(supplement: supplement),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        supplement['image']!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        supplement['title']!,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
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

  const SupplementDetailScreen({Key? key, required this.supplement})
      : super(key: key);

  List<TextSpan> _buildFormattedText(
      BuildContext context, String details) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium!;
    final headingStyle =
        bodyStyle.copyWith(fontWeight: FontWeight.bold);

    final lines = details.split('\n');
    return lines.map<TextSpan>((line) {
      if (line.trim().isEmpty) {
        return const TextSpan(text: '\n');
      }
      final headingPattern = RegExp(
          r'^(What it is:|Purpose:|How to take:|Who should avoid it:|Additional facts:|ℹAdditional facts:)');
      if (headingPattern.hasMatch(line)) {
        return TextSpan(text: '$line\n', style: headingStyle);
      } else {
        return TextSpan(text: '$line\n', style: bodyStyle);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplement['title']!),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                supplement['image']!,
                width: screenWidth - 32,
                height: screenWidth - 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: _buildFormattedText(
                    context, supplement['details']!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
