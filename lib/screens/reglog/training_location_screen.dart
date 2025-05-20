import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'training_experience_screen.dart';

class TrainingLocationScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const TrainingLocationScreen({Key? key, required this.registrationData}) : super(key: key);

  @override
  _TrainingLocationScreenState createState() => _TrainingLocationScreenState();
}

class _TrainingLocationScreenState extends State<TrainingLocationScreen> {
  final List<Map<String, String>> locations = [
    {"name": "At home", "image": "assets/images/home.jpg"},
    {"name": "In the gym", "image": "assets/images/gym.jpg"},
  ];

  void setTrainingLocation(String location) {
    widget.registrationData.location = location;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingExperienceScreen(registrationData: widget.registrationData),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "Where to train?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Color(0xFF333333) : Color.fromARGB(255, 219, 200, 173);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    return GestureDetector(
      onTap: () => setTrainingLocation(name),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w500, 
                    color: textColor,
                  ),
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
