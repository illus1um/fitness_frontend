// lib/screens/workout/workout_day_screen.dart

import 'package:flutter/material.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'workout_session_screen.dart';

class WorkoutDayScreen extends StatefulWidget {
  final DayInfo day;
  const WorkoutDayScreen({required this.day, Key? key}) : super(key: key);

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  Map<String, int> _completedSets = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDayProgress();
  }

  Future<void> _loadDayProgress() async {
    final list = await ApiService.getDayProgress(widget.day.dayIndex);
    setState(() {
      _completedSets = { for (var e in list) e.exerciseId: e.setsCompleted };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Упражнения дня ${widget.day.dayIndex}')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: widget.day.exercises.length,
              itemBuilder: (ctx, i) {
                final ex = widget.day.exercises[i];
                final done = _completedSets[ex.id] ?? 0;
                final isDone = done >= ex.sets;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: ListTile(
                    leading: Image.asset(
                      ex.assetPreviewPath,
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                    ),
                    title: Text(ex.name),
                    subtitle: Text('$done/${ex.sets} подходов'),
                    trailing: isDone 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutSessionScreen(
                          day: widget.day,
                          startIndex: i,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(day: widget.day),
            ),
          ),
          child: const Text('НАЧАТЬ ТРЕНИРОВКУ'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ),
    );
  }
}
