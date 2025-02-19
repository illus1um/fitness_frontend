import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Домашняя страницаs")),
      body: Center(
        child: Text("Добро пожаловать в ваше фитнес-приложение!"),
      ),
    );
  }
}
