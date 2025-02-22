import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness App',
      theme: ThemeData(primarySwatch: Colors.brown,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Poppins', // Устанавливаем Poppins для всего приложения
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black),
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Color.fromARGB(255, 199, 169, 127), // ✅ Глобальный цвет загрузки
        )
        ),
        initialRoute: "/login",
        routes: appRoutes,
      // home: HomeScreen(),
    );
  }
}
  