// ignore_for_file: deprecated_member_use

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
    // Обновляем прогресс
    await _loadProgress();
    
    // Вызываем коллбэк, если он задан
    if (widget.onWorkoutComplete != null) {
      await widget.onWorkoutComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Workout Plan'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(goldColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Plan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: widget.days.isEmpty 
        ? Center(
            child: Text(
              'No workout days available.',
              style: TextStyle(fontSize: 16),
            ),
          )
        : ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 16),
          itemCount: widget.days.length,
          itemBuilder: (_, i) {
            final day = widget.days[i];
            final percent = _calculateDayProgress(day);
            final isCompleted = _isDayCompleted(day);
            final isAvailable = _isDayAvailable(day.dayIndex);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                      ? Colors.black.withOpacity(0.3) 
                      : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: isDarkMode ? 0 : 1,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isAvailable 
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDayScreen(
                            day: day,
                            onComplete: _onDayComplete,
                          ),
                        ),
                      ).then((_) => _loadProgress())
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('This workout day is not available yet. Complete previous days first.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Progress circle
                        _buildProgressCircle(percent, isCompleted, isAvailable, goldColor, isDarkMode),
                        SizedBox(width: 20),
                        
                        // Workout info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout ${day.dayIndex}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable 
                                    ? (isDarkMode ? Colors.white : Colors.black)
                                    : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                day.part,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isAvailable 
                                    ? (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)
                                    : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Icon
                        _buildTrailingIcon(isCompleted, isAvailable, goldColor, isDarkMode),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildProgressCircle(
    double percent, 
    bool isCompleted, 
    bool isAvailable, 
    Color goldColor, 
    bool isDarkMode
  ) {
    // Fix for the 100% display issue - make sure percent is exactly 1.0 if completed
    if (isCompleted) percent = 1.0;
    
    return CircularPercentIndicator(
      radius: 32,
      lineWidth: 5,
      percent: percent,
      animation: true,
      animationDuration: 500,
      circularStrokeCap: CircularStrokeCap.round,
      center: Text(
        '${(percent * 100).round()}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isAvailable 
            ? (isCompleted 
                ? goldColor
                : (isDarkMode ? Colors.white : Colors.black))
            : Colors.grey,
        ),
      ),
      backgroundColor: isDarkMode 
        ? Colors.grey.shade800
        : Colors.grey.shade200,
      progressColor: isCompleted 
        ? goldColor
        : isAvailable
          ? goldColor 
          : Colors.grey,
    );
  }

  Widget _buildTrailingIcon(
    bool isCompleted, 
    bool isAvailable, 
    Color goldColor, 
    bool isDarkMode
  ) {
    if (isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          color: goldColor,
          size: 24,
        ),
      );
    } else if (isAvailable) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward,
          color: goldColor,
          size: 20,
        ),
      );
    } else {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock,
          color: isDarkMode 
            ? Colors.grey.shade600
            : Colors.grey.shade400,
          size: 20,
        ),
      );
    }
  }
}
