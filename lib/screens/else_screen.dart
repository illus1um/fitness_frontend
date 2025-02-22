import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/login_screen.dart';
import 'package:fitness_app/screens/myprofilegoal_screen.dart';

class ElseScreen extends StatefulWidget {
  @override
  _ElseScreenState createState() => _ElseScreenState();
}

class _ElseScreenState extends State<ElseScreen> {
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

  void _logout() async {
    bool success = await ApiService.logout();
    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Else"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  /// 🖼 **Аватарка**
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome, ${userData!["first_name"]}!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),

                  /// 📌 **Основной список**
                  _buildListTile(Icons.settings, "Settings", () {}),
                  _buildListTile(
                    Icons.person, 
                    "My Profile & Goal", 
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyProfileGoalScreen()),
                    ),
                  ),
                  _buildListTile(Icons.history, "My Workouts", () {}),
                  SizedBox(height: 30),

                  /// 📌 **Информация пользователя**
                  _buildInfoTile(Icons.email, userData!["email"]),
                  _buildListTile(Icons.lock, "Change Password", () {}),
                  _buildListTile(Icons.exit_to_app, "Logout from Account", _logout, color: Colors.red),
                ],
              ),
            ),
    );
  }

  /// 📌 **Элемент списка с иконкой**
  Widget _buildListTile(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }

  /// 📌 **Элемент информации (без стрелки)**
  Widget _buildInfoTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
