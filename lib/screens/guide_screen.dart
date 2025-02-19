import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guide")),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text("🏋️‍♂️ Exercises"),
            onTap: () {}, // Будет открываться список упражнений
          ),
          ListTile(
            title: Text("🥗 Sports Nutrition"),
            onTap: () {}, // Будет открываться информация о питании
          ),
          ListTile(
            title: Text("🍏 Caloric Content of Products"),
            onTap: () {}, // Будет открываться список продуктов
          ),
          ListTile(
            title: Text("📖 Encyclopedia"),
            onTap: () {}, // Будет открываться энциклопедия фитнеса
          ),
        ],
      ),
    );
  }
}
