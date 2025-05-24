// ignore_for_file: deprecated_member_use

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
  int? selectedIndex;

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
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    
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
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF1A1A1A)],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF5F5F5)],
              ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      "Choose Your",
                      style: TextStyle(
                        fontSize: 24,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Difficulty Level",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              Expanded(
                child: ListView.separated(
                  itemCount: experiences.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final experience = experiences[index];
                    return _buildExperienceCard(
                      experience["level"]!,
                      experience["name"]!,
                      experience["description"]!,
                      index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String level, String name, String description, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final isSelected = selectedIndex == index;
    
    final cardColor = isSelected
        ? (isDarkMode ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.2))
        : (isDarkMode ? Color(0xFF262626) : Colors.white);
    
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.black54;
    final circleColor = isSelected ? primaryColor : primaryColor.withOpacity(0.8);
    
    return GestureDetector(
      onTap: () {
        setState(() => selectedIndex = index);
        completeRegistration(name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black26
                : Colors.black.withOpacity(0.08),
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: isSelected 
              ? primaryColor
              : isDarkMode ? Colors.transparent : Colors.grey.withOpacity(0.1),
            width: 2,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                boxShadow: [
                  BoxShadow(
                    color: circleColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isSelected ? primaryColor : Colors.grey.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
