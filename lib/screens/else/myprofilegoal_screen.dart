import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';

class MyProfileGoalScreen extends StatefulWidget {
  @override
  _MyProfileGoalScreenState createState() => _MyProfileGoalScreenState();
}

class _MyProfileGoalScreenState extends State<MyProfileGoalScreen> {
  Map<String, dynamic>? userData;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadUserData();
  }

  Future<void> _loadUnits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightUnit = prefs.getString('weight_unit') ?? 'kg';
      _heightUnit = prefs.getString('height_unit') ?? 'cm';
    });
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();
    setState(() {
      userData = data;
    });
  }

  void _updateField(String field, dynamic newValue) async {
    setState(() {
      userData![field] = newValue;
    });

    bool success = await ApiService.updateUserProfile({field: newValue});
    if (success) {
      print("$field успешно обновлено на сервере");
    } else {
      print("Ошибка при обновлении $field на сервере");
    }
  }

  // Added from the second file - unit conversion helpers
  double get _displayWeight {
    if (userData == null) return 0;
    final kg = (userData!['weight'] ?? 0.0) as double;
    return _weightUnit == 'lb' ? kg * 2.20462 : kg;
  }

  String get _displayHeight {
    if (userData == null) return '';
    final cm = (userData!['height'] ?? 0.0) as double;
    if (_heightUnit == 'inch') {
      final totalInches = (cm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet ft $inches in";
    }
    return "${cm.toStringAsFixed(0)} cm";
  }

  void _confirmDeleteAccount() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure you want to delete your account?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "All your data will be permanently removed. This action cannot be undone.",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CANCEL",
                        style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 199, 169, 127)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _deleteAccount();
                        Navigator.pop(context);
                      },
                      child: Text("DELETE", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteAccount() async {
    bool success = await ApiService.deleteAccount();
    if (success) {
      print("Account deleted successfully");
      Navigator.pushReplacementNamed(context, "/login"); // Или другой экран входа
    } else {
      print("Failed to delete account");
    }
  }

  // Improved weight editing from second file
  void _editWeight() {
    final displayed = _displayWeight;
    final min = _weightUnit == 'kg' ? 30.0 : 30.0 * 2.20462;
    final max = _weightUnit == 'kg' ? 200.0 : 200.0 * 2.20462;
    int initialItem = (displayed - min).round();
    double selected = displayed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Weight ($_weightUnit)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialItem),
                  itemExtent: 32,
                  onSelectedItemChanged: (i) => selected = min + i.toDouble(),
                  children: List.generate((max - min).round() + 1, (i) => Text((min + i).toStringAsFixed(0))),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 199, 169, 127),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final newKg = _weightUnit == 'lb' ? selected / 2.20462 : selected;
                  _updateField('weight', newKg);
                  Navigator.pop(context);
                },
                child: Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved height editing from second file
  void _editHeight() {
    if (_heightUnit == 'inch') {
      final cmValue = (userData!['height'] ?? 0.0) as double;
      final totalInches = (cmValue / 2.54).round();
      int feet = totalInches ~/ 12;
      int inches = totalInches % 12;
      int selectedFeet = feet;
      int selectedInches = inches;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Height (ft/in)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: selectedFeet),
                          itemExtent: 32,
                          onSelectedItemChanged: (i) => selectedFeet = i,
                          children: List.generate(8, (i) => Text('$i ft')),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: selectedInches),
                          itemExtent: 32,
                          onSelectedItemChanged: (i) => selectedInches = i,
                          children: List.generate(12, (i) => Text('$i in')),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 199, 169, 127),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final total = selectedFeet * 12 + selectedInches;
                    final newCm = total * 2.54;
                    _updateField('height', newCm);
                    Navigator.pop(context);
                  },
                  child: Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final cm = (userData!['height'] ?? 0.0) as double;
      double selected = cm;
      final min = 100.0;
      final max = 220.0;
      int initial = (cm - min).round();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Height (cm)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: initial),
                    itemExtent: 32,
                    onSelectedItemChanged: (i) => selected = min + i.toDouble(),
                    children: List.generate((max - min).round() + 1, (i) => Text('${(min + i).round()}')),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 199, 169, 127),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _updateField('height', selected);
                    Navigator.pop(context);
                  },
                  child: Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile & Goal"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 120, color: Colors.white),
                    ),
                    SizedBox(height: 20),

                    _buildCard(
                      title: "My Personal Information",
                      children: [
                        _buildInfoTile("Username", userData!["username"]),
                        _buildEditableTile("First Name", userData!["first_name"], () => _editTextField("first_name")),
                        _buildEditableTile("Last Name", userData!["last_name"], () => _editTextField("last_name")),
                        _buildEditableTile("Age", userData!["age"].toString(), () => _editNumberPicker("age", 12, 80)),
                        _buildEditableTile("Gender", userData!["gender"] ? "Male" : "Female", () => _editGenderPicker("gender")),
                        _buildEditableTile("Weight", "${_displayWeight.toStringAsFixed(1)} $_weightUnit", _editWeight),
                        _buildEditableTile("Height", _displayHeight, _editHeight),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildCard(
                      title: "Goal Settings",
                      children: [
                        _buildEditableTile("Fitness Goal", userData!["training_program"], () => _editPicker("training_program", fitnessGoals)),
                        _buildEditableTile("Training Location", userData!["training_location"], () => _editTrainingLocationPicker("training_location")),
                        _buildEditableTile("Training Experience", userData!["training_experience"], () => _editPicker("training_experience", experienceLevels)),
                      ],
                    ),
                    SizedBox(height: 30),

                    Divider(),
                    TextButton(
                      onPressed: () {
                        _confirmDeleteAccount();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 142, 142, 142),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      child: Text("Delete your account?"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 199, 169, 127)),
          ),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: Text(value, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildEditableTile(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  void _editGenderPicker(String field) {
    bool isMale = userData![field]; // Получаем boolean

    _showEditDialog(
      "Select Gender",
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioTile("Male", isMale ? "Male" : "Female", (value) {
                setStateDialog(() {
                  isMale = value == "Male";
                });
              }),
              _buildRadioTile("Female", isMale ? "Male" : "Female", (value) {
                setStateDialog(() {
                  isMale = value == "Male";
                });
              }),
            ],
          );
        },
      ),
      () => _updateField(field, isMale), // Отправляем true/false на сервер
    );
  }

  void _editTrainingLocationPicker(String field) {
    String selectedValue = userData![field];

    _showEditDialog(
      "Select Training Location",
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioTile("At home", selectedValue, (value) {
                setStateDialog(() {
                  selectedValue = value;
                });
              }),
              _buildRadioTile("In the gym", selectedValue, (value) {
                setStateDialog(() {
                  selectedValue = value;
                });
              }),
            ],
          );
        },
      ),
      () => _updateField(field, selectedValue), // Отправляем обновленное значение
    );
  }

  Widget _buildRadioTile(String title, String groupValue, ValueChanged<String> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(fontSize: 16)),
      value: title,
      groupValue: groupValue,
      onChanged: (value) => onChanged(value!),
      activeColor: Color.fromARGB(255, 199, 169, 127), // Коричневый цвет
    );
  }

  void _showEditDialog(String title, Widget content, VoidCallback onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: content,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 199, 169, 127),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    onSave();  // Вызывает _updateField и отправляет данные на сервер
                    Navigator.pop(context);
                  },
                  child: Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editTextField(String field) {
    TextEditingController controller = TextEditingController(text: userData![field]);
    _showEditDialog(
      field,
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Enter $field",
            labelStyle: TextStyle(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromARGB(255, 199, 169, 127), width: 2.0),
            ),
            floatingLabelStyle: TextStyle(),
          ),
        ),
      ),
      () => _updateField(field, controller.text),
    );
  }

  void _editNumberPicker(String field, int min, int max) {
    int selectedValue = int.parse(userData![field].toString());
    _showEditDialog(
      field,
      CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: selectedValue - min),
        itemExtent: 32,
        onSelectedItemChanged: (index) => selectedValue = min + index,
        children: List.generate(max - min + 1, (index) => Text("${min + index}")),
      ),
      () => _updateField(field, selectedValue),
    );
  }

  void _editPicker(String field, List<String> options) {
    String selectedValue = userData![field];
    _showEditDialog(
      field,
      CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: options.indexOf(selectedValue)),
        itemExtent: 32,
        onSelectedItemChanged: (index) => selectedValue = options[index],
        children: options.map((e) => Text(e)).toList(),
      ),
      () => _updateField(field, selectedValue),
    );
  }
}

List<String> fitnessGoals = ["Weight Loss", "Endurance", "Full Body", "Gain Muscle Mass", "Legs", "Wide Back"];
List<String> experienceLevels = ["No experience", "Beginner", "Experienced", "Pro"];