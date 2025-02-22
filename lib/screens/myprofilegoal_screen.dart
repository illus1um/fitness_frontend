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

  void _updateField(String field, String newValue) {
    print("Обновляем $field на $newValue");
  }

  void _deleteAccount() {
    print("Запрос на удаление аккаунта");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile & Goal"),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                        _buildEditableTile("First Name", userData!["first_name"]),
                        _buildEditableTile("Last Name", userData!["last_name"]),
                        _buildEditableTile("Age", userData!["age"].toString()),
                        _buildEditableTile("Gender", userData!["gender"] ? "Male" : "Female"),
                        _buildEditableTile("Weight", "${userData!["weight"]} kg"),
                        _buildEditableTile("Height", "${userData!["height"]} cm"),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildCard(
                      title: "Goal Settings",
                      children: [
                        _buildEditableTile("Fitness Goal", userData!["training_program"]),
                        _buildEditableTile("Training Location", userData!["training_location"]),
                        _buildEditableTile("Training Experience", userData!["training_experience"]),
                      ],
                    ),
                    SizedBox(height: 30),

                    Divider(),
                    TextButton(
                      onPressed: _deleteAccount,
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

  /// 📌 **Карточка с тенями**
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Легкая тень
            blurRadius: 6, // Размытие тени
            spreadRadius: 2, // Распределение тени
            offset: Offset(0, 4), // Смещение вниз
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 199, 169, 127),
            ),
          ),
          SizedBox(height: 10),
          ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: children,
          ),
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

  Widget _buildEditableTile(String label, String value) {
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
      onTap: () => _updateField(label, value),
    );
  }
}
