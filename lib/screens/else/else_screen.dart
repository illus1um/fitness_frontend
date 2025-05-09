import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/reglog/login_screen.dart';
import 'package:fitness_app/screens/else/myprofilegoal_screen.dart';
import 'change_password.dart';
import 'package:fitness_app/screens/else/settings.dart';

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
        elevation: 0,
        scrolledUnderElevation: 0,      
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Вернул прокрутку
              child: Padding(
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    SizedBox(height: 30),

                    /// 📌 **Основной список в карточке**
                    _buildCard(
                      title: "General",
                      children: [
                        _buildListTile(
                          Icons.person,
                          "My Profile & Goal",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyProfileGoalScreen()),
                          ),
                        ),

                        _buildListTile(Icons.history, "My Workouts", () {}),

                        _buildListTile(Icons.settings, "Settings", () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsScreen()),
                          ),),
                      ],
                    ),
                    SizedBox(height: 20),

                    /// 📌 **Информация пользователя в карточке**
                    _buildCard(
                      title: "Account",
                      children: [
                        _buildInfoTile(Icons.email, userData!["email"]),
                        _buildListTile(Icons.lock, "Change Password", () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));}),
                        _buildListTile(Icons.exit_to_app, "Logout from Account", _logout, color: const Color.fromARGB(255, 214, 88, 79)),
                      ],
                    ),
                    SizedBox(height: 20), // Добавил отступ, чтобы не упиралось в край экрана
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
      margin: EdgeInsets.only(bottom: 10), // Добавил отступ между карточками
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            physics: NeverScrollableScrollPhysics(), // Убираем отдельный скролл для списка
            children: children,
          ),
        ],
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
