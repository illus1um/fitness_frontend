// lib/screens/workout/workout_day_screen.dart

import 'package:flutter/material.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'workout_session_screen.dart';

class WorkoutDayScreen extends StatefulWidget {
  final DayInfo day;
  final Function? onComplete;
  
  const WorkoutDayScreen({
    required this.day,
    this.onComplete,
    Key? key
  }) : super(key: key);

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
  
  // Проверяем, завершен ли день полностью
  bool _isDayCompleted() {
    if (widget.day.exercises.isEmpty) return false;
    
    return widget.day.exercises.every((ex) {
      final done = _completedSets[ex.id] ?? 0;
      return done >= ex.sets;
    });
  }
  
  // Обработчик завершения тренировки
  Future<void> _onSessionComplete() async {
    await _loadDayProgress();
    
    // Если день полностью завершен, вызываем коллбэк
    if (_isDayCompleted() && widget.onComplete != null) {
      await widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDayCompleted = _isDayCompleted();
    
    return Scaffold(
      appBar: AppBar(title: Text('Day ${widget.day.dayIndex + 1} Exercises')),
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
                    subtitle: Text('$done/${ex.sets} sets'),
                    trailing: isDone 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutSessionScreen(
                          day: widget.day,
                          startIndex: i,
                          onComplete: _onSessionComplete,
                        ),
                      ),
                    ).then((_) => _loadDayProgress()),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDayCompleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'All exercises completed!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSessionScreen(
                    day: widget.day,
                    onComplete: _onSessionComplete,
                  ),
                ),
              ).then((_) => _loadDayProgress()),
              child: const Text('START WORKOUT'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
