import 'package:flutter/material.dart';
import 'package:fitness_app/screens/workout/workout_screen.dart';
import 'package:fitness_app/screens/guide/guide_screen.dart';
import 'package:fitness_app/screens/drinking/drinking_screen.dart';
import 'package:fitness_app/screens/else/else_screen.dart';
import 'package:fitness_app/services/auth_service.dart'; 

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String username = "";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    String? storedUsername = await AuthService.getUsername();
    if (storedUsername != null) {
      setState(() {
        username = storedUsername;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      WorkoutScreen(),
      // BodyScreen(),
      GuideScreen(),
      DrinkingScreen(username: username),
      ElseScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workout"),
          // BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Body"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Guide"),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: "Drinking"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Else"),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
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
