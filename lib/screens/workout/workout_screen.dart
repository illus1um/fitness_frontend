// lib/screens/workout/workout_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_generator.dart';
import 'package:fitness_app/screens/workout/workout_plan_screen.dart';
import '../../models/day_info.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? userData;
  bool _isGenerating = false;
  List<DayInfo>? _plan;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCachedPlan();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();
    if (data != null) {
      setState(() => userData = data);
    }
  }

  Future<void> _loadCachedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('current_plan');
    if (jsonStr != null) {
      final List<dynamic> decoded = json.decode(jsonStr);
      setState(() {
        _plan = decoded
            .map((d) => DayInfo.fromJson(Map<String, dynamic>.from(d)))
            .toList();
      });
    }
  }

  Future<void> _cachePlan(List<DayInfo> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final str = json.encode(plan.map((d) => d.toJson()).toList());
    await prefs.setString('current_plan', str);
  }

  Future<void> _startWorkout() async {
    if (userData == null) return;

    // Если план уже был сгенерирован, сразу переходим
    if (_plan != null) {
      _goToPlan();
      return;
    }

    setState(() => _isGenerating = true);

    final plan = await PlanGenerator.generatePlan(
      program: userData!['training_program'],
      location: userData!['training_location'],
      experience: userData!['training_experience'],
      dayCount: 15, // измените по необходимости
    );

    setState(() => _isGenerating = false);
    await _cachePlan(plan);

    setState(() => _plan = plan);
    _goToPlan();
  }

  void _goToPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutPlanScreen(days: _plan!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout Overview"),
        centerTitle: true,
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _startWorkout,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fitness_center),
                    label: Text(
                      _isGenerating
                          ? "Генерируем план..."
                          : (_plan != null
                              ? "Продолжить тренировку"
                              : "Начать тренировку"),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 4),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
