import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/screens/history_screen.dart';
import 'package:fitness_app/services/api_service.dart';
import 'notification_settings_screen.dart';

class DrinkingScreen extends StatefulWidget {
  final String username;

  DrinkingScreen({required this.username});

  @override
  _DrinkingScreenState createState() => _DrinkingScreenState();
}

class _DrinkingScreenState extends State<DrinkingScreen> {
  double dailyWaterTarget = 2.0;
  double currentWaterIntake = 0.0;
  List<double> _intakeHistory = [];
  List<double> _undoHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 📌 Загрузка данных профиля пользователя
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getUserProfile();

    if (profile != null) {
      double weight = profile["weight"] ?? 70.0;
      int age = profile["age"] ?? 25;
      bool isMale = profile["gender"] ?? true;

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);

      String userKey = "water_${widget.username}";
      String dateKey = "date_${widget.username}";

      String today = DateTime.now().toIso8601String().substring(0, 10);
      String? savedDate = prefs.getString(dateKey);

      if (savedDate != today) {
        // Новый день — сохраняем вчерашние данные
        double yesterdayIntake = prefs.getDouble(userKey) ?? 0.0;
        await _saveToHistory(savedDate ?? today, yesterdayIntake);

        await prefs.setDouble(userKey, 0.0);
        await prefs.setString(dateKey, today);
        currentWaterIntake = 0.0;
      } else {
        currentWaterIntake = prefs.getDouble(userKey) ?? 0.0;
      }

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
      });
    }
  }

  /// 📌 Расчёт дневной нормы воды
  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  /// 📌 Обновление воды
  Future<void> _updateWaterIntake(double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";

    setState(() {
      _intakeHistory.add(amount);
      currentWaterIntake = min(currentWaterIntake + amount, dailyWaterTarget);
      _undoHistory.clear();
    });

    await prefs.setDouble(userKey, currentWaterIntake);
  }

  /// 📌 Undo
  Future<void> _undoLastIntake() async {
    if (_intakeHistory.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userKey = "water_${widget.username}";

      setState(() {
        double lastAmount = _intakeHistory.removeLast();
        _undoHistory.add(lastAmount);
        currentWaterIntake = max(0, currentWaterIntake - lastAmount);
      });

      await prefs.setDouble(userKey, currentWaterIntake);
    }
  }

  /// 📌 Redo
  Future<void> _redoLastIntake() async {
    if (_undoHistory.isNotEmpty) {
      double redoAmount = _undoHistory.removeLast();
      await _updateWaterIntake(redoAmount);
    }
  }

  /// 📌 Сохраняем прогресс в историю
  Future<void> _saveToHistory(String date, double intake) async {
    if (intake == 0.0) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String historyKey = "history_${widget.username}";

    Map<String, dynamic> history = {};
    String? historyJson = prefs.getString(historyKey);

    if (historyJson != null) {
      history = json.decode(historyJson);
    }

    history[date] = intake;
    await prefs.setString(historyKey, json.encode(history));
  }

  /// 📌 Кастомное красивое окно для ввода воды
  void _showCustomWaterDialog() {
  TextEditingController customController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter amount (liters)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: customController,
              cursorColor: Color.fromARGB(255, 199, 169, 127), // 📌 Цвет каретки
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "e.g. 0.3",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 199, 169, 127), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 199, 169, 127), // 📌 Бежевый текст
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // 📌 Чёрная кнопка
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    double amount = double.tryParse(customController.text) ?? 0;
                    if (amount > 0) {
                      _updateWaterIntake(amount);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    "ADD",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double circleSize = screenWidth * 0.6;

    return Scaffold(
      appBar: AppBar(
        title: Text("Water Tracker"),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            tooltip: "Notification Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(username: widget.username),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.black),
            tooltip: "History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(username: widget.username),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Daily Drink Target",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 199, 169, 127),
                    ),
                  ),
                  SizedBox(height: 30),
                  TweenAnimationBuilder(
                    tween: Tween<double>(
                      begin: 0,
                      end: currentWaterIntake / dailyWaterTarget,
                    ),
                    duration: Duration(seconds: 1),
                    builder: (context, double progress, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: circleSize,
                            height: circleSize,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 14,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 85, 150, 193),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${currentWaterIntake.toStringAsFixed(2)} L / ${dailyWaterTarget.toStringAsFixed(2)} L",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildWaterButton("0.1L", 0.1, Icons.local_cafe),
                      _buildWaterButton("0.25L", 0.25, Icons.local_drink),
                      _buildWaterButton("0.5L", 0.5, Icons.sports_bar),
                      _buildWaterButton("Custom", 0.0, Icons.add, isCustom: true),
                      _buildUndoRedoButton("Undo", _undoLastIntake, Colors.black, Icons.undo),
                      _buildUndoRedoButton("Redo", _redoLastIntake, Colors.black, Icons.redo),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 📌 Кнопка добавления воды
  Widget _buildWaterButton(String label, double amount, IconData icon, {bool isCustom = false}) {
    return GestureDetector(
      onTap: () => isCustom ? _showCustomWaterDialog() : _updateWaterIntake(amount),
      child: Container(
        width: 70,
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

  /// 📌 Кнопки Undo/Redo
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
