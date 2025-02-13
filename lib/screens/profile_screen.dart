import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      appBar: AppBar(title: Text("Профиль")),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text("Логин: ${userData!["username"]}"),
                Text("Email: ${userData!["email"]}"),
                ElevatedButton(onPressed: logout, child: Text("Выход")),
              ],
            ),
    );
  }
}
