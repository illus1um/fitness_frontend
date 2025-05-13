import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'workout_day_screen.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final List<DayInfo> days;
  const WorkoutPlanScreen({required this.days, Key? key}) : super(key: key);

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  // все записи прогресса
  List<ProgressEntry> _allProgress = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prog = await ApiService.getProgress();
    setState(() {
      _allProgress = prog;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Тренировочный план')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Тренировочный план')),
      body: ListView.builder(
        itemCount: widget.days.length,
        itemBuilder: (_, i) {
          final day = widget.days[i];
          // фильтруем прогресс по дню
          final dayProg = _allProgress
              .where((e) => e.dayIndex == day.dayIndex)
              .toList();

          // считаем, сколько упражнений полностью завершено
          final completedExercises = day.exercises.where((ex) {
            final entry = dayProg.firstWhere(
              (p) => p.exerciseId == ex.id,
              orElse: () => ProgressEntry(
                dayIndex: day.dayIndex,
                exerciseId: ex.id,
                setsCompleted: 0,
                completedAt: DateTime.now(),
              ),
            );
            return entry.setsCompleted >= ex.sets;
          }).length;

          final total = day.exercises.length;
          final percent =
              total > 0 ? (completedExercises / total).clamp(0.0, 1.0) : 0.0;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            minLeadingWidth: 56,
            leading: CircularPercentIndicator(
              radius: 24,
              lineWidth: 4,
              percent: percent,
              center: Text('${(percent * 100).round()}%'),
              backgroundColor: Colors.grey.shade200,
              progressColor: Theme.of(context).primaryColor,
            ),
            title: Text('${day.dayIndex} тренировка'),
            subtitle: Text(day.part),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutDayScreen(day: day)),
            ),
          );
        },
      ),
    );
  }
}
