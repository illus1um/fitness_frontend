import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_generator.dart';
import 'package:fitness_app/services/plan_cache.dart';
import 'package:fitness_app/screens/workout/workout_plan_screen.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? userData;
  bool _isGenerating = false;
  List<DayInfo>? _plan;
  DateTime? _startDate;
  DateTime _focusedDay = DateTime.now();

  /// Набор чистых дат тренировочных дней (без времени)
  final Set<DateTime> _workoutDays = {};
  
  /// Набор индексов доступных тренировочных дней
  final Set<int> _availableDays = {};
  
  /// Прогресс пользователя
  List<ProgressEntry> _progress = [];

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
    try {
      final plan = await PlanCache.loadPlan();
      final sd = await PlanCache.loadStartDate();
      final progress = await PlanCache.loadProgress();
      
      if (plan != null && sd != null) {
        _prepareWorkoutDays(plan, sd);
        _updateAvailableDays(plan, sd, progress);
        
        setState(() {
          _plan = plan;
          _startDate = sd;
          _progress = progress;
        });
        
        print('DEBUG: Plan loaded successfully with ${plan.length} days');
      } else {
        print('DEBUG: No plan or start date found in cache');
      }
    } catch (e) {
      print('ERROR loading cached plan: $e');
      // Восстанавливаемся после ошибки, очищая данные
      setState(() {
        _plan = null;
        _startDate = null;
        _progress = [];
        _workoutDays.clear();
        _availableDays.clear();
      });
    }
  }

  Future<void> _startWorkout() async {
    if (userData == null) return;
    if (_plan != null) {
      _goToPlan();
      return;
    }

    setState(() => _isGenerating = true);

    final startDate = DateTime.now();
    await PlanCache.saveStartDate(startDate);

    final plan = await PlanGenerator.generatePlan(
      program:    userData!['training_program'],
      location:   userData!['training_location'],
      experience: userData!['training_experience'],
      dayCount:   15,
    );

    setState(() => _isGenerating = false);

    await PlanCache.savePlan(plan);
    _prepareWorkoutDays(plan, startDate);
    
    // Принудительно добавляем первый день в доступные, так как мы только что создали план
    // Получаем индекс первого дня (обычно это 1, так как в плане индексы начинаются с 1)
    if (plan.isNotEmpty) {
      int firstDayIndex = plan[0].dayIndex;
      _availableDays.add(firstDayIndex);
      print('DEBUG: Added first day (index=$firstDayIndex) to available days');
    }

    setState(() {
      _plan = plan;
      _startDate = startDate;
      _progress = [];
    });

    // Сразу открываем план тренировок
    _goToPlan();
  }

  void _prepareWorkoutDays(List<DayInfo> plan, DateTime sd) {
    _workoutDays.clear();
    final startDate = DateTime(sd.year, sd.month, sd.day);
    for (int i = 0; i < plan.length; i++) {
      final workoutDay = startDate.add(Duration(days: i * 2));
      // Сохраняем только дату без времени
      _workoutDays.add(DateTime(workoutDay.year, workoutDay.month, workoutDay.day));
      print('Added workout day: ${workoutDay.toString()}');
    }
  }
  
  /// Обновляет набор доступных тренировочных дней
  void _updateAvailableDays(List<DayInfo> plan, DateTime startDate, List<ProgressEntry> progress) {
    _availableDays.clear();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    print('DEBUG: Today: $today');
    
    // Очищаем даты (без времени)
    final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    print('DEBUG: Clean start date: $cleanStartDate');
    
    // Для удобства нормализуем план к индексам, которые мы используем (0, 1, 2, ...)
    List<DayInfo> normalizedPlan = [];
    for (int i = 0; i < plan.length; i++) {
      // Находим день с индексом i+1 (так как в плане индексы от 1)
      final day = plan.firstWhere((d) => d.dayIndex == i+1, orElse: () => DayInfo(
        dayIndex: -1,
        part: '',
        exercises: [],
      ));
      
      if (day.dayIndex != -1) {
        normalizedPlan.add(day);
      }
    }
    
    print('DEBUG: Normalized plan days: ${normalizedPlan.map((d) => d.dayIndex).toList()}');
    
    // Проверяем каждый день тренировочного плана
    for (int i = 0; i < normalizedPlan.length; i++) {
      // Дата текущего дня
      final currentDayDate = cleanStartDate.add(Duration(days: i * 2));
      print('DEBUG: Checking day $i (dayIndex=${normalizedPlan[i].dayIndex}), date: $currentDayDate');
      
      // Дата не наступила - день недоступен
      if (currentDayDate.isAfter(today)) {
        print('DEBUG: Day $i is in the future, not available');
        continue;
      }
      
      // Первый день (i == 0) всегда доступен, если его дата <= сегодня (проверка выше)
      if (i == 0) {
        _availableDays.add(normalizedPlan[i].dayIndex);
        print('DEBUG: First day (dayIndex=${normalizedPlan[i].dayIndex}) is available');
        continue;
      }
      
      // Для последующих дней проверяем, выполнен ли предыдущий день
      final prevDay = normalizedPlan[i-1];
      
      // Предыдущий день не завершен - день недоступен
      final prevDayCompleted = _isDayCompleted(prevDay.dayIndex, progress, plan);
      print('DEBUG: Previous day (dayIndex=${prevDay.dayIndex}) completed: $prevDayCompleted');
      
      if (!prevDayCompleted) {
        print('DEBUG: Day $i (dayIndex=${normalizedPlan[i].dayIndex}) not available - previous day not completed');
        continue;
      }
      
      // День доступен
      _availableDays.add(normalizedPlan[i].dayIndex);
      print('DEBUG: Day $i (dayIndex=${normalizedPlan[i].dayIndex}) is available');
    }
    
    print('DEBUG: Available days: $_availableDays');
  }
  
  /// Проверяет выполнение всех упражнений для конкретного дня
  bool _isDayCompleted(int dayIndex, List<ProgressEntry> progress, List<DayInfo> plan) {
    // Находим информацию о дне
    final day = plan.firstWhere((d) => d.dayIndex == dayIndex, orElse: () => DayInfo(
      dayIndex: -1,
      part: '',
      exercises: [],
    ));
    
    if (day.dayIndex == -1 || day.exercises.isEmpty) {
      print('DEBUG: Day $dayIndex not found or has no exercises');
      return false;
    }
    
    // Для каждого упражнения проверяем, выполнено ли оно полностью
    int totalExercises = day.exercises.length;
    int completedExercises = 0;
    
    for (var exercise in day.exercises) {
      final entry = progress.firstWhere(
        (p) => p.dayIndex == dayIndex && p.exerciseId == exercise.id,
        orElse: () => ProgressEntry(
          dayIndex: dayIndex,
          exerciseId: exercise.id,
          setsCompleted: 0,
          completedAt: DateTime.now(),
        ),
      );
      
      if (entry.setsCompleted >= exercise.sets) {
        completedExercises++;
      }
    }
    
    print('DEBUG: Day $dayIndex - Completed $completedExercises/$totalExercises exercises');
    // Все упражнения выполнены
    return completedExercises == totalExercises;
  }

  void _goToPlan() {
    // Передаем все дни, а не только доступные
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlanScreen(
          days: _plan!,
          availableDays: _availableDays,
          onWorkoutComplete: _onWorkoutComplete,
        ),
      ),
    );
  }
  
  /// Обработчик завершения тренировки
  Future<void> _onWorkoutComplete() async {
    // Загружаем актуальный прогресс
    final updatedProgress = await ApiService.getProgress();
    
    // Сохраняем прогресс в кэш
    await PlanCache.saveProgress(updatedProgress);
    
    // Обновляем список доступных дней
    if (_plan != null && _startDate != null) {
      _updateAvailableDays(_plan!, _startDate!, updatedProgress);
      setState(() {
        _progress = updatedProgress;
      });
    }
  }

  /// Проверяет, можно ли уже открыть тренировочный день с указанным индексом
  bool _isDayOpen(int dayIndex) {
    return _availableDays.contains(dayIndex);
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  if (_plan != null && _startDate != null) ...[
                    Text(
                      'Training Schedule',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Календарь с адаптивной высотой
                    SingleChildScrollView(
                      child: Container(
                        height: 350, // Увеличиваем высоту для месяцев с 6 неделями
                        child: _buildTableCalendar(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed:
                          _isGenerating ? null : _startWorkout,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.fitness_center),
                      label: Text(_isGenerating
                          ? "Generating plan..."
                          : "Start Workout"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  ElevatedButton.icon(
                    onPressed: (_plan != null) ? _goToPlan : null,
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("Continue Workout"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  TableCalendar _buildTableCalendar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TableCalendar(
      firstDay: _startDate!,
      lastDay: _startDate!.add(Duration(days: (_plan!.length - 1) * 2)),
      focusedDay: _focusedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ) ?? TextStyle(),
        leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
        rightChevronIcon: Icon(Icons.chevron_right, color: theme.iconTheme.color),
      ),
      rowHeight: 45,
      calendarStyle: CalendarStyle(
        defaultTextStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
        ) ?? TextStyle(),
        disabledTextStyle: (theme.textTheme.bodyMedium ?? TextStyle())
            .copyWith(color: theme.disabledColor),
        todayTextStyle: (theme.textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: (theme.textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: colorScheme.onPrimary,
              fontSize: 16,
            ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: (theme.textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: colorScheme.error,
              fontSize: 16,
            ),
        markerDecoration: BoxDecoration(
          color: colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.all(4),
        cellPadding: EdgeInsets.zero,
      ),
      eventLoader: (day) {
        final simpleDay = DateTime(day.year, day.month, day.day);
        final isWorkout = _workoutDays.any((d) =>
          d.year == simpleDay.year && d.month == simpleDay.month && d.day == simpleDay.day
        );
        print('eventLoader: $simpleDay isWorkout=$isWorkout');
        if (isWorkout) {
          return ['workout'];
        }
        return [];
      },
      enabledDayPredicate: (day) => true,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 4,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Color(0xFFC7A97F),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
        defaultBuilder: (ctx, day, focused) {
          final simpleDay = DateTime(day.year, day.month, day.day);
          if (_startDate == null) return null;
          
          final diff = day.difference(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
          ).inDays;
          
          // Определяем, является ли этот день тренировочным
          final isWorkoutDay = diff >= 0 && diff % 2 == 0;
          if (!isWorkoutDay) return null;
          
          // Номер тренировочного дня (0-based) и индекс в плане (1-based)
          final dayNumber = diff ~/ 2;
          final dayIndex = dayNumber + 1; // в плане индексы начинаются с 1
          
          // Проверяем, доступен ли день
          final enabled = _isDayOpen(dayIndex);
          
          return Tooltip(
            message: enabled ? 'Training Day $dayIndex' : 'Locked Training Day $dayIndex',
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? colorScheme.primary.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
                border: enabled
                    ? Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: (theme.textTheme.bodyMedium ?? TextStyle()).copyWith(
                    color: enabled
                        ? colorScheme.primary
                        : theme.disabledColor,
                    fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final text = DateFormat.E().format(day);
          return Center(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        
        if (_startDate == null) return;
        
        final diff = selectedDay.difference(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        ).inDays;
        
        print('DEBUG: Selected day: $selectedDay');
        print('DEBUG: Start date: ${DateTime(_startDate!.year, _startDate!.month, _startDate!.day)}');
        print('DEBUG: Difference in days: $diff');
        
        // Не тренировочный день
        if (diff < 0 || diff % 2 != 0) {
          print('DEBUG: Not a workout day (diff=$diff)');
          return;
        }
        
        // Вычисляем номер тренировочного дня (0-based)
        final dayNumber = diff ~/ 2;
        
        // Индекс дня в плане (1-based, так как dayIndex в плане начинается с 1)
        final targetDayIndex = dayNumber + 1;
        
        print('DEBUG: Target day number: $dayNumber');
        print('DEBUG: Target day index: $targetDayIndex');
        print('DEBUG: Is day open: ${_isDayOpen(targetDayIndex)}');
        print('DEBUG: Available days: $_availableDays');
        
        // Проверяем, есть ли день с таким индексом в плане
        if (dayNumber < _plan!.length && _isDayOpen(targetDayIndex)) {
          // Находим конкретный день для открытия
          final dayToOpen = _plan!.firstWhere((d) => d.dayIndex == targetDayIndex, 
            orElse: () => DayInfo(dayIndex: -1, part: '', exercises: []));
            
          if (dayToOpen.dayIndex == -1) {
            print('DEBUG: Day with index $targetDayIndex not found in plan');
            return;
          }
          
          print('DEBUG: Opening day: ${dayToOpen.dayIndex}');
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutPlanScreen(
                days: [dayToOpen],
                availableDays: {targetDayIndex}, // Этот день точно доступен
                onWorkoutComplete: _onWorkoutComplete,
              ),
            ),
          );
        } else {
          print('DEBUG: Day $targetDayIndex is not available or not in plan range');
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
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
            value:
                userData!["training_program"] ?? "Not set",
          ),
          _buildInfoTile(
            icon: Icons.location_on,
            title: "Location",
            value:
                userData!["training_location"] ?? "Not set",
          ),
          _buildInfoTile(
            icon: Icons.emoji_events,
            title: "Experience",
            value:
                userData!["training_experience"] ?? "Not set",
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
      leading:
          Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value,
          style:
              const TextStyle(fontWeight: FontWeight.w600)),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 4),
    );
  }
}