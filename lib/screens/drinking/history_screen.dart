import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final String username;
  const HistoryScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, double> history = {};
  double dailyWaterTarget = 2.0;
  String _waterUnit = 'L';
  static const double _litersToFlOz = 33.814;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    _waterUnit = prefs.getString('water_unit') ?? 'L';
    await _loadHistory();
    await _loadUserProfile();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history_${widget.username}';
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      setState(() {
        history = Map<String, double>.from(json.decode(jsonStr));
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      final weight = (profile['weight'] ?? 70.0) as double;
      final age = (profile['age'] ?? 25) as int;
      final isMale = (profile['gender'] ?? true) as bool;
      final base = isMale ? weight * 0.035 : weight * 0.031;
      final factor = age > 55 ? 0.90 : (age > 30 ? 0.95 : 1.0);
      setState(() {
        dailyWaterTarget = double.parse((base * factor).toStringAsFixed(2));
      });
    }
  }

  double _convertToDisplay(double liters) {
    return _waterUnit == 'fl oz' ? liters * _litersToFlOz : liters;
  }

  String get _unitLabel => _waterUnit;

  Color _intakeColor(double intake, ThemeData theme) {
    if (intake >= dailyWaterTarget) {
      return theme.primaryColor;
    } else if (intake >= dailyWaterTarget * 0.5) {
      return theme.colorScheme.secondary;
    } else {
      return Color.fromARGB(255, 236, 56, 56);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedDates = history.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('Water Intake History', style: TextStyle(fontWeight: FontWeight.w700),),
        centerTitle: true,
        elevation: 0,
      ),
      body: sortedDates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No history yet.\nStart tracking your water intake!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge!.copyWith(color: theme.disabledColor),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final intakeLiters = history[date]!;
                final displayIntake = _convertToDisplay(intakeLiters);
                final color = _intakeColor(intakeLiters, theme);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    color: theme.cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: Icon(
                        intakeLiters >= dailyWaterTarget ? Icons.emoji_events : Icons.calendar_today,
                        color: intakeLiters >= dailyWaterTarget
                            ? theme.colorScheme.secondary
                            : theme.iconTheme.color,
                        size: intakeLiters >= dailyWaterTarget ? 32 : 28,
                      ),
                      title: Text(date,
                          style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Water intake',
                          style: theme.textTheme.bodyMedium!.copyWith(color: theme.hintColor)),
                      trailing: Text(
                        '${displayIntake.toStringAsFixed(1)} $_unitLabel',
                        style: theme.textTheme.bodyLarge!
                            .copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
