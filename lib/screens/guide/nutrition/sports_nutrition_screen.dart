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

  List<Widget> _buildFormattedSections(BuildContext context, String details) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Define colors based on theme
    final accentColor = isDarkMode ? const Color(0xFFB2996E) : const Color(0xFFC7A97F);
    final bodyTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];
    
    // Parse the details into sections
    final sections = details.split('\n\n');
    final result = <Widget>[];
    
    for (final section in sections) {
      final parts = section.split(':\n');
      if (parts.length == 2) {
        final heading = parts[0].trim();
        final content = parts[1].trim();
        
        // Add the section heading
        result.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  _getIconForHeading(heading),
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        );
        
        // Add the section content
        result.add(
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: bodyTextColor,
              ),
            ),
          ),
        );
        
        // Add a divider except after the last section
        if (section != sections.last) {
          result.add(
            Divider(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              thickness: 1,
              height: 32,
            ),
          );
        }
      }
    }
    
    return result;
  }
  
  IconData _getIconForHeading(String heading) {
    switch (heading) {
      case 'What it is':
        return Icons.info_outline;
      case 'Purpose':
        return Icons.lightbulb_outline;
      case 'How to take':
        return Icons.schedule;
      case 'Who should avoid it':
        return Icons.warning_amber_outlined;
      case 'Additional facts':
      case 'ℹAdditional facts':
        return Icons.tips_and_updates_outlined;
      default:
        return Icons.article_outlined;
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final accentColor = isDarkMode ? const Color(0xFFB2996E) : const Color(0xFFC7A97F);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          supplement['title']!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with enhanced styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                      ? Colors.black.withOpacity(0.3) 
                      : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                supplement['image']!,
                width: screenWidth - 32,
                height: screenWidth - 32,
                fit: BoxFit.cover,
              ),
            ),
            ),
            
            // Title with accent underline
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: accentColor,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                supplement['title']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            
            // Content sections
            ..._buildFormattedSections(context, supplement['details']!),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
