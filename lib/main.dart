import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness App',
      theme: ThemeData(primarySwatch: Colors.blue,
      fontFamily: 'Poppins', // Устанавливаем Poppins для всего приложения
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black),
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      initialRoute: "/login",
      routes: appRoutes,
    );
  }
}
  