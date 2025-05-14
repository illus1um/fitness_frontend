import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
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

  void saveProfile() {
    setState(() => isLoading = true);

    widget.registrationData.weight = selectedWeight;
    widget.registrationData.height = selectedHeight;
    widget.registrationData.age = selectedAge;

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "About Your Body",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildPicker(String label, int min, int max, int selected, ValueChanged<int> onChanged) {
    final items = List<Widget>.generate(max - min + 1, (index) {
      final value = min + index;
      return Center(
        child: Text(
          value.toString(),
          style: TextStyle(fontSize: 20),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(
          height: 120,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: selected - min),
            itemExtent: 32,
            diameterRatio: 1.1,
            onSelectedItemChanged: (index) => onChanged(min + index),
            children: items,
          ),
        ),
      ],
    );
  }

}
