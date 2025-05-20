import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'package:fitness_app/services/api_service.dart';
import '../home_screen.dart';

class TrainingExperienceScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const TrainingExperienceScreen({Key? key, required this.registrationData}) : super(key: key);

  @override
  _TrainingExperienceScreenState createState() => _TrainingExperienceScreenState();
}

class _TrainingExperienceScreenState extends State<TrainingExperienceScreen> {
  bool isLoading = false;

  final List<Map<String, String>> experiences = [
    {"level": "1", "name": "No experience", "description": "Didn't do any fitness"},
    {"level": "2", "name": "Beginner", "description": "Started recently"},
    {"level": "3", "name": "Experienced", "description": "Have almost 1 year of experience"},
    {"level": "4", "name": "Pro", "description": "Have a lot of experience"},
  ];

  void completeRegistration(String experience) async {
    setState(() => isLoading = true);

    widget.registrationData.difficulty = experience;

    // 1. Регистрируем пользователя
    final registerSuccess = await ApiService.register(
      widget.registrationData.username,
      widget.registrationData.email!,
      widget.registrationData.password,
      widget.registrationData.firstName!,
      widget.registrationData.lastName!,
      widget.registrationData.gender!,
    );

    if (registerSuccess) {
      bool loginSuccess = await ApiService.login(widget.registrationData.username, widget.registrationData.password);
      if (loginSuccess) {
        bool profileCompleted = await ApiService.checkProfileStatus();
        if (profileCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          print("error");
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registration error. Check the data."),
        backgroundColor: Colors.red,
      ));
    }

    if (!registerSuccess) {
      showError("Registration failed");
      return;
    }

    final profileSuccess = await ApiService.updateProfile(
      widget.registrationData.weight!.toDouble(),
      widget.registrationData.height!.toDouble(),
      widget.registrationData.age!,
    );

    if (!profileSuccess) {
      showError("Failed to update profile");
      return;
    }

    // 3. Устанавливаем программу
    final programSuccess = await ApiService.setTrainingProgram(widget.registrationData.trainingProgram!);
    if (!programSuccess) {
      showError("Failed to set training program");
      return;
    }

    // 4. Устанавливаем локацию
    final locationSuccess = await ApiService.setTrainingLocation(widget.registrationData.location!);
    if (!locationSuccess) {
      showError("Failed to set training location");
      return;
    }

    // 5. Устанавливаем опыт
    final experienceSuccess = await ApiService.setTrainingExperience(widget.registrationData.difficulty!);
    if (!experienceSuccess) {
      showError("Failed to set training experience");
      return;
    }

    setState(() => isLoading = false);

    // Всё успешно — переходим на домашний экран
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }

  void showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                "Difficulty level",
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
                itemCount: experiences.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final experience = experiences[index];
                  return _buildExperienceCard(experience["level"]!, experience["name"]!, experience["description"]!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String level, String name, String description) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final cardColor = isDarkMode ? Color(0xFF333333) : Color.fromARGB(255, 219, 200, 173);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.black54;
    final circleColor = isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor;
    
    return GestureDetector(
      onTap: () => completeRegistration(name),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w500, 
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14, 
                      color: subtitleColor,
                    ),
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
