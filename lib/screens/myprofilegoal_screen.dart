import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';

class MyProfileGoalScreen extends StatefulWidget {
  @override
  _MyProfileGoalScreenState createState() => _MyProfileGoalScreenState();
}

class _MyProfileGoalScreenState extends State<MyProfileGoalScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    var data = await ApiService.getUserProfile();
    setState(() {
      userData = data;
    });
  }

  void _updateField(String field, dynamic newValue) async {
  setState(() {
    userData![field] = newValue;
  });

  Map<String, dynamic> updatedData = {field: newValue};

  bool success = await ApiService.updateUserProfile(updatedData);
  if (success) {
    print("$field успешно обновлено на сервере");
  } else {
    print("Ошибка при обновлении $field на сервере");
  }
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
              color: Colors.white,
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
                  style: TextStyle(fontSize: 14, color: Colors.black54),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile & Goal"),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                    /// 🖼 **Аватарка**
                    CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 120, color: Colors.white),
                    ),
                    SizedBox(height: 20),

                    /// 📌 **Карточка "My Personal Information"**
                    _buildCard(
                      title: "My Personal Information",
                      children: [
                        _buildInfoTile("Username", userData!["username"]),
                        _buildEditableTile("First Name", userData!["first_name"], () => _editTextField("first_name")),
                        _buildEditableTile("Last Name", userData!["last_name"], () => _editTextField("last_name")),
                        _buildEditableTile("Age", userData!["age"].toString(), () => _editNumberPicker("age", 12, 80)),
                        _buildEditableTile("Gender", userData!["gender"] ? "Male" : "Female", () => _editGenderPicker("gender")),
                        _buildEditableTile("Weight", "${userData!["weight"]} kg", () => _editDoublePicker("weight", 30, 200)),
                        _buildEditableTile("Height", "${userData!["height"]} cm", () => _editDoublePicker("height", 100, 220)),
                      ],
                    ),
                    SizedBox(height: 20),

                    /// 📌 **Карточка "Goal Settings"**
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
                        foregroundColor: Colors.grey,
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text("Delete your account?"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 📌 **Карточка**
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(255 * 0.1.toInt()), // Замена .withOpacity()
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
      trailing: Text(value, style: TextStyle(fontSize: 16, color: Colors.black54)),
    );
  }

  Widget _buildEditableTile(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16, color: Colors.black54)),
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
              color: Colors.white,
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
            labelStyle: TextStyle(color: Colors.black54),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromARGB(255, 199, 169, 127), width: 2.0),
            ),
            floatingLabelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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

  void _editDoublePicker(String field, double min, double max) {
    double selectedValue = double.parse(userData![field].toString());
    _showEditDialog(
      field,
      CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: (selectedValue - min).toInt()),
        itemExtent: 32,
        onSelectedItemChanged: (index) => selectedValue = min + index.toDouble(),
        children: List.generate((max - min + 1).toInt(), (index) => Text("${(min + index).toStringAsFixed(1)}")),
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
