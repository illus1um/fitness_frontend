// lib/screens/workout/workout_screen.dart

import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_generator.dart';
import 'package:fitness_app/screens/workout/workout_plan_screen.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? userData;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();
    if (data != null) {
      setState(() => userData = data);
    } else {
      // обработка ошибки если нужно
    }
  }

  Future<void> _startWorkout() async {
    if (userData == null) return;

    setState(() => _isGenerating = true);

    // тут можно менять dayCount на нужное число дней
    final plan = await PlanGenerator.generatePlan(
      program: userData!['training_program'],
      location: userData!['training_location'],
      experience: userData!['training_experience'],
      dayCount: 4,
    );

    setState(() => _isGenerating = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlanScreen(days: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Overview"),
        centerTitle: true,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _startWorkout,
                    icon: _isGenerating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.fitness_center),
                    label: Text(
                      _isGenerating ? "Генерируем план..." : "Начать тренировку",
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.flag,
            title: "Goal",
            value: userData!["training_program"] ?? "Not set",
          ),
          _buildInfoTile(
            icon: Icons.location_on,
            title: "Location",
            value: userData!["training_location"] ?? "Not set",
          ),
          _buildInfoTile(
            icon: Icons.emoji_events,
            title: "Experience",
            value: userData!["training_experience"] ?? "Not set",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }
}
