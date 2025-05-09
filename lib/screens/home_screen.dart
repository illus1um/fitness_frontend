import 'package:flutter/material.dart';
import 'package:fitness_app/screens/workout_screen.dart';
import 'package:fitness_app/screens/guide_screen.dart';
import 'package:fitness_app/screens/drinking_screen.dart';
import 'package:fitness_app/screens/else_screen.dart';
import 'package:fitness_app/services/auth_service.dart';  // ✅ Добавлено для получения username

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String username = ""; // ✅ Переменная для username

  @override
  void initState() {
    super.initState();
    _loadUsername(); // ✅ Загружаем username при запуске
  }

  Future<void> _loadUsername() async {
    String? storedUsername = await AuthService.getUsername(); // ✅ Получаем username
    if (storedUsername != null) {
      setState(() {
        username = storedUsername;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      WorkoutScreen(),  // 🏋️‍♂️ Тренировки (по умолчанию)
      // BodyScreen(),  // 🏃‍♂️ Тело
      GuideScreen(),  // 📖 Гайд
      DrinkingScreen(username: username),  // ✅ Передаём username
      ElseScreen(),  // ⚙️ Профиль и настройки
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 244, 241, 237),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workout"),
          // BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Body"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Guide"),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: "Drinking"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Else"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 199, 169, 127),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
