import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    var data = await ApiService.getUserProfile();

    if (data != null) {
      print("🔹 Полученные данные профиля: $data"); // ✅ Проверяем консоль
      setState(() {
        userData = data;
      });
    } else {
      print("🔺 Ошибка загрузки данных профиля");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Plan"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: userData == null
            ? Center(child: CircularProgressIndicator()) // ⏳ Пока грузится
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("🏋️‍♂️ Ваш тренировочный план:", "training_program"),
                  _buildInfoRow("📍 Где вы тренируетесь:", "training_location"),
                  _buildInfoRow("⚡ Ваш уровень:", "training_experience"),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            userData != null && userData![key] != null && userData![key] != ""
                ? userData![key] // ✅ Гарантированно отображаем
                : "Не выбрано",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
