import 'package:flutter/material.dart';
import '../../models/day_info.dart';
import 'workout_session_screen.dart';

class WorkoutDayScreen extends StatelessWidget {
  final DayInfo day;
  const WorkoutDayScreen({required this.day, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Упражнения дня ${day.dayIndex}')),
      body: ListView.builder(
        itemCount: day.exercises.length,
        itemBuilder: (_, i) {
          final exerciseInfo = day.exercises[i];
          return ListTile(
            leading: Image.asset(
              exerciseInfo.assetPreviewPath,        // <- здесь .png­превью
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
            ),
            title: Text(exerciseInfo.name),
            subtitle: Text('${exerciseInfo.sets}×${exerciseInfo.reps}'),
            trailing: Icon(Icons.chevron_right),
            onTap: () { /* открыть детали */ },
          );

        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(day: day),
            ),
          ),
          child: Text('НАЧАТЬ ТРЕНИРОВКУ'),
        ),
      ),
    );
  }
}