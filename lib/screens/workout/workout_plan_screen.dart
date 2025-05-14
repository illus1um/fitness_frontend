import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'workout_day_screen.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final List<DayInfo> days;
  final Set<int>? availableDays;
  final Function? onWorkoutComplete;
  
  const WorkoutPlanScreen({
    required this.days,
    this.availableDays,
    this.onWorkoutComplete,
    Key? key
  }) : super(key: key);

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
  
  // Проверяет, завершен ли день полностью
  bool _isDayCompleted(DayInfo day) {
    if (day.exercises.isEmpty) return false;
    
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
    
    // Возвращаем true если все упражнения выполнены
    return completedExercises == day.exercises.length;
  }
  
  // Расчет прогресса выполнения дня (от 0.0 до 1.0)
  double _calculateDayProgress(DayInfo day) {
    if (day.exercises.isEmpty) return 0.0;
    
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
    return total > 0 ? (completedExercises / total).clamp(0.0, 1.0) : 0.0;
  }
  
  // Проверяет, доступен ли день
  bool _isDayAvailable(int dayIndex) {
    if (widget.availableDays == null) return true; // Если не задан список доступных дней, считаем все доступными
    return widget.availableDays!.contains(dayIndex);
  }
  
  // Обработчик завершения дня тренировки
  Future<void> _onDayComplete() async {
    await _loadProgress();
    
    // Вызываем коллбэк, если он задан
    if (widget.onWorkoutComplete != null) {
      await widget.onWorkoutComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Workout Plan')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Workout Plan')),
      body: ListView.builder(
        itemCount: widget.days.length,
        itemBuilder: (_, i) {
          final day = widget.days[i];
          final percent = _calculateDayProgress(day);
          final isCompleted = _isDayCompleted(day);
          final isAvailable = _isDayAvailable(day.dayIndex);

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
              progressColor: isCompleted 
                ? Colors.green 
                : Theme.of(context).primaryColor,
            ),
            title: Text(
              'Workout ${day.dayIndex + 0}',
              style: TextStyle(
                color: isAvailable ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              day.part,
              style: TextStyle(
                color: isAvailable ? null : Colors.grey,
              ),
            ),
            trailing: isCompleted 
              ? Icon(Icons.check_circle, color: Colors.green)
              : isAvailable 
                ? Icon(Icons.arrow_forward)
                : Icon(Icons.lock, color: Colors.grey),
            onTap: isAvailable 
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDayScreen(
                      day: day,
                      onComplete: _onDayComplete,
                    ),
                  ),
                )
              : () {
                  // Показываем сообщение, что день недоступен
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('This workout day is not available yet. Complete previous days first.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}
