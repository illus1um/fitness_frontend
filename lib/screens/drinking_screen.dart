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
  double dailyWaterTarget = 2.0;
  double currentWaterIntake = 0.0;
  final List<double> _intakeHistory = []; // ✅ История добавленной воды для Undo/Redo

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 📌 **Загружаем данные пользователя (вес, возраст, пол)**
  Future<void> _loadUserData() async {
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      double weight = profile["weight"] ?? 70.0;
      int age = profile["age"] ?? 25;
      bool isMale = profile["gender"] ?? true;

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userKey = "water_${widget.username}";

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
        currentWaterIntake = prefs.getDouble(userKey) ?? 0.0;
      });
    }
  }

  /// 📌 **Рассчет дневной нормы воды**
  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  /// 📌 **Добавление воды**
  Future<void> _updateWaterIntake(double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";

    setState(() {
      _intakeHistory.add(amount);
      currentWaterIntake = min(currentWaterIntake + amount, dailyWaterTarget);
    });

    await prefs.setDouble(userKey, currentWaterIntake);
  }

  /// 📌 **Отмена последнего добавления воды**
  Future<void> _undoLastIntake() async {
    if (_intakeHistory.isNotEmpty) {
      double lastAmount = _intakeHistory.removeLast();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userKey = "water_${widget.username}";

      setState(() {
        currentWaterIntake = max(0, currentWaterIntake - lastAmount);
      });

      await prefs.setDouble(userKey, currentWaterIntake);
    }
  }

  /// 📌 **Повторить отмененный шаг (Redo)**
  Future<void> _redoLastIntake() async {
    if (_intakeHistory.isNotEmpty) {
      double redoAmount = _intakeHistory.last;
      await _updateWaterIntake(redoAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Water Tracker"), centerTitle: true, backgroundColor: Colors.white),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Daily Drink Target", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 199, 169, 127))),
          SizedBox(height: 30),

          /// 📌 **Анимация прогресса воды**
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: currentWaterIntake / dailyWaterTarget),
            duration: Duration(seconds: 1),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 85, 150, 193)),
                    ),
                  ),
                  Column(
                    children: [
                      Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildWaterButton("0.2L", 0.2, Icons.local_cafe),
                _buildWaterButton("0.25L", 0.25, Icons.local_drink),
                _buildWaterButton("0.5L", 0.5, Icons.sports_bar),
                _buildUndoRedoButton("Undo", _undoLastIntake,  Colors.black, Icons.undo),
                _buildUndoRedoButton("Redo", _redoLastIntake, Colors.black, Icons.redo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 **Кнопка добавления воды с иконкой**
  Widget _buildWaterButton(String label, double amount, IconData icon) {
    return GestureDetector(
      onTap: () => _updateWaterIntake(amount),
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 199, 169, 127),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// 📌 **Кнопки Undo / Redo**
  Widget _buildUndoRedoButton(String label, Function onTap, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
//Color.fromARGB(255, 219, 200, 173),
//Color.fromARGB(255, 199, 169, 127)