import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/reglog/login_screen.dart';
import 'package:fitness_app/screens/else/myprofilegoal_screen.dart';
import 'change_password.dart';


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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Else"),
        centerTitle: true,
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

                        _buildListTile(
                          Icons.settings,
                          "Settings",
                          () => Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildCard(
                      title: "Account",
                      children: [
                        _buildInfoTile(Icons.email, userData!["email"]),
                        _buildListTile(Icons.lock, "Change Password", () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));}),
                        _buildListTile(Icons.exit_to_app, "Logout from Account", _logout, color: const Color.fromARGB(255, 201, 50, 50)),
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
        color: Theme.of(context).cardColor,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 199, 169, 127)),
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

  /// 📌 **Элемент списка с иконкой**
Widget _buildListTile(
  IconData icon,
  String title,
  VoidCallback onTap, {
  Color? color, // теперь nullable
}) {
  // берём цвет иконок из темы, если не передали явно
  final iconColor = color ?? Theme.of(context).iconTheme.color!;
  // и текстовый стиль из темы с заменой цвета на iconColor
  final textStyle = Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(color: iconColor);

  return ListTile(
    leading: Icon(icon, color: iconColor),
    title: Text(title, style: textStyle),
    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
    onTap: onTap,
  );
}

  Widget _buildInfoTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color:  Theme.of(context).iconTheme.color),
      title: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
