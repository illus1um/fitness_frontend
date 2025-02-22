import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/login_screen.dart';

class ElseScreen extends StatefulWidget {
  @override
  _ElseScreenState createState() => _ElseScreenState();
}

class _ElseScreenState extends State<ElseScreen> {
  Map<String, dynamic>? userData;

  void loadUserData() async {
    var data = await ApiService.getUserProfile();
    setState(() {
      userData = data;
    });
  }

  void logout() async {
    bool success = await ApiService.logout();
    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text("👤 ${userData!["first_name"]} ${userData!["last_name"]}"),
                Text("📧 ${userData!["email"]}"),
                Text("📛 ${userData!["username"]}"),
                Text("🎂 ${userData!["age"]}"),
                ElevatedButton(onPressed: logout, child: Text("Logout")),
              ],
            ),
    );
  }
}
