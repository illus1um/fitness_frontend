import 'package:flutter/material.dart';
import 'package:fitness_app/screens/workout_screen.dart';
import 'package:fitness_app/screens/body_screen.dart';
import 'package:fitness_app/screens/guide_screen.dart';
import 'package:fitness_app/screens/drinking_screen.dart';
import 'package:fitness_app/screens/else_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    WorkoutScreen(),  // 🏋️‍♂️ Тренировки (по умолчанию)
    BodyScreen(),  // 🏃‍♂️ Тело
    GuideScreen(),  // 📖 Гайд
    DrinkingScreen(),  // 💧 Трекинг воды
    ElseScreen(),  // ⚙️ Профиль и настройки
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 244, 241, 237),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workout"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Body"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Guide"),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: "Drinking"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Else"),
        ],
        
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 199, 169, 127),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
