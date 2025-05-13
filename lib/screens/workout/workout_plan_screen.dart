import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import 'workout_day_screen.dart';

class WorkoutPlanScreen extends StatelessWidget {
  final List<DayInfo> days;
  const WorkoutPlanScreen({required this.days, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочный план'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          // Пока нет сохранённого прогресса — показываем 0%
          final percent = 0.0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),

            // Достаточная ширина под индикатор
            minLeadingWidth: 56,

            leading: CircularPercentIndicator(
              radius: 24,               // диаметр = 48
              lineWidth: 4,
              percent: percent,
              center: Text('${i + 1}'),
              backgroundColor: Colors.grey.shade200,
              progressColor: Theme.of(context).primaryColor,
            ),

            title: Text('${i + 1} тренировка'),
            subtitle: Text(day.part),

            trailing: const Icon(Icons.arrow_forward),
            onTap: day.exercises.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDayScreen(day: day),
                      ),
                    );
                  },
          );
        },
      ),
    );
  }
}
