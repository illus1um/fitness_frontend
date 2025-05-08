import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart'; // для загрузки профиля

class HistoryScreen extends StatefulWidget {
  final String username;

  HistoryScreen({required this.username});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, double> history = {};
  double dailyWaterTarget = 2.0; // индивидуальная норма

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadHistory();
    await _loadUserProfile();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String historyKey = "history_${widget.username}";

    String? historyJson = prefs.getString(historyKey);
    if (historyJson != null) {
      setState(() {
        history = Map<String, double>.from(json.decode(historyJson));
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await ApiService.getUserProfile();

    if (profile != null) {
      double weight = profile["weight"] ?? 70.0;
      int age = profile["age"] ?? 25;
      bool isMale = profile["gender"] ?? true;

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
      });
    }
  }

  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  /// 📌 Выбор цвета на основе индивидуальной нормы
  Color getColorForIntake(double intake) {
    if (intake >= dailyWaterTarget) {
      return Colors.green;
    } else if (intake >= dailyWaterTarget * 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = history.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Сортировка по убыванию

    return Scaffold(
      appBar: AppBar(
        title: Text("Water Intake History"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: sortedDates.isEmpty
          ? Center(
              child: Text(
                "No history yet.\nStart tracking your water intake!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                String date = sortedDates[index];
                double intake = history[date] ?? 0.0;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: intake >= dailyWaterTarget
                        ? Icon(Icons.emoji_events, color: Colors.amber, size: 32)
                        : Icon(Icons.calendar_today, color: Colors.blueAccent, size: 28),
                    title: Text(
                      date,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Water intake",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      "${intake.toStringAsFixed(2)} L",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: getColorForIntake(intake),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
