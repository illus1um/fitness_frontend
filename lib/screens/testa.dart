import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:fitness_app/services/api_service.dart'; // ✅ Подключаем API

class DrinkingScreen extends StatefulWidget {
  final String username;

  DrinkingScreen({required this.username});

  @override
  _DrinkingScreenState createState() => _DrinkingScreenState();
}

class _DrinkingScreenState extends State<DrinkingScreen> {
  double dailyWaterTarget = 2.0; // Норма воды
  double currentWaterIntake = 0.0; // Текущий прогресс
  final List<double> _intakeHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // ✅ Загружаем данные юзера
  }

  /// 📌 **Загружаем данные о пользователе (вес, возраст, пол)**
  Future<void> _loadUserData() async {
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      double weight = profile["weight"] ?? 70.0; // Дефолт 70 кг
      int age = profile["age"] ?? 25; // Дефолт 25 лет
      bool isMale = profile["gender"] ?? true; // Дефолт мужской

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userKey = "water_${widget.username}";

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
        currentWaterIntake = prefs.getDouble(userKey) ?? 0.0;
      });
    }
  }

  /// 📌 **Рассчитываем норму воды на основе веса, возраста и пола**
  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95; // -5%
    else if (age > 55) baseWater *= 0.90; // -10%
    return double.parse(baseWater.toStringAsFixed(2));
  }

  /// 📌 **Добавляем воду (уникальный прогресс для пользователя)**
  Future<void> _updateWaterIntake(double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";
    setState(() {
      currentWaterIntake = min(currentWaterIntake + amount, dailyWaterTarget);
    });
    await prefs.setDouble(userKey, currentWaterIntake);
  }

  /// 📌 **Отменяем последнее добавление воды**
  Future<void> _removeWaterIntake(double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";
    setState(() {
      currentWaterIntake = max(0, currentWaterIntake - amount);
    });
    await prefs.setDouble(userKey, currentWaterIntake);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Water Tracker"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Daily Drink Target", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          SizedBox(height: 30),

          /// 📌 **Анимация прогресса воды**
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: currentWaterIntake / dailyWaterTarget),
            duration: Duration(seconds: 1), // Плавное обновление
            builder: (context, double progress, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  Column(
                    children: [
                      Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                      Text("${currentWaterIntake.toStringAsFixed(2)} L / ${dailyWaterTarget.toStringAsFixed(2)} L",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 30),

          /// 📌 **Кнопки добавления воды**
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWaterButton("100 ml", 0.1),
              _buildWaterButton("250 ml", 0.25),
              _buildWaterButton("500 ml", 0.5),
            ],
          ),
          SizedBox(height: 20),

          /// 📌 **Кнопка отмены**
          TextButton(
            onPressed: () => _removeWaterIntake(0.25),
            child: Text("Undo last", style: TextStyle(fontSize: 16, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 📌 **Кнопка добавления воды**
  Widget _buildWaterButton(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () => _updateWaterIntake(amount),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        ),
        child: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
