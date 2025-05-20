import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'training_program_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // We no longer need to set is_new_user flag
    // as we're using has_generated_plan instead

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
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "About Your Body",
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildPicker("Weight (kg)", 30, 300, selectedWeight, (val) {
                    setState(() => selectedWeight = val);
                  }),
                ),
                Expanded(
                  child: _buildPicker("Height (cm)", 100, 250, selectedHeight, (val) {
                    setState(() => selectedHeight = val);
                  }),
                ),
                Expanded(
                  child: _buildPicker("Age", 12, 100, selectedAge, (val) {
                    setState(() => selectedAge = val);
                  }),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: buttonTextColor)
                  : Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(String label, int min, int max, int selected, ValueChanged<int> onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    final items = List<Widget>.generate(max - min + 1, (index) {
      final value = min + index;
      return Center(
        child: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            color: textColor,
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        SizedBox(
          height: 120,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: selected - min),
            itemExtent: 32,
            diameterRatio: 1.1,
            backgroundColor: Colors.transparent,
            onSelectedItemChanged: (index) => onChanged(min + index),
            children: items,
          ),
        ),
      ],
    );
  }
}
