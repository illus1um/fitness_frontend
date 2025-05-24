import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_cache.dart';
import 'training_program_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const CompleteProfileScreen({Key? key, required this.registrationData}) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int selectedWeight = 70;
  int selectedHeight = 170;
  int selectedAge = 25;

  bool isLoading = false;

  void saveProfile() async {
    setState(() => isLoading = true);

    widget.registrationData.weight = selectedWeight;
    widget.registrationData.height = selectedHeight;
    widget.registrationData.age = selectedAge;

    // Ensure any existing workout plan is cleared for new users
    try {
      // Set flag to indicate user has NOT generated a workout plan yet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', false);
      
      // Clear any existing plans from server and cache
      await ApiService.clearProgress();
      await ApiService.clearPlan();
      await PlanCache.clearPlan();
    } catch (e) {
      print('Error clearing workout data: $e');
    }

    setState(() => isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingProgramScreen(registrationData: widget.registrationData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final primaryColor = Color.fromARGB(255, 199, 169, 127);
    final buttonColor = isDarkMode ? primaryColor : Colors.black;
    final buttonTextColor = isDarkMode ? Colors.black : Colors.white;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
              ? [Colors.black, Color(0xFF1A1A1A)]
              : [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Help us create your perfect fitness plan",
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildPickerWithIcon(
                          "Weight (kg)",
                          Icons.monitor_weight_outlined,
                          30, 300, selectedWeight,
                          (val) => setState(() => selectedWeight = val),
                          primaryColor,
                        ),
                        SizedBox(height: 20),
                        _buildPickerWithIcon(
                          "Height (cm)",
                          Icons.height_outlined,
                          100, 250, selectedHeight,
                          (val) => setState(() => selectedHeight = val),
                          primaryColor,
                        ),
                        SizedBox(height: 20),
                        _buildPickerWithIcon(
                          "Age",
                          Icons.cake_outlined,
                          12, 100, selectedAge,
                          (val) => setState(() => selectedAge = val),
                          primaryColor,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: buttonTextColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerWithIcon(
    String label,
    IconData icon,
    int min,
    int max,
    int selected,
    ValueChanged<int> onChanged,
    Color accentColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selected - min
            ),
            itemExtent: 40,
            diameterRatio: 1.2,
            backgroundColor: Colors.transparent,
            onSelectedItemChanged: (index) => onChanged(min + index),
            children: List<Widget>.generate(
              max - min + 1,
              (index) {
                final value = min + index;
                return Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
