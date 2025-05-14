import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_generator.dart';
import 'package:fitness_app/services/plan_cache.dart';
import 'package:fitness_app/screens/workout/workout_plan_screen.dart';
import 'package:fitness_app/screens/workout/workout_history_screen.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutHistoryScreen(),
                ),
              );
            },
          ),
        ],
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Calendar container with gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFC7A97F).withOpacity(0.05),
                            Color(0xFFC7A97F).withOpacity(0.15),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      // Using LayoutBuilder instead of fixed height container for flexibility
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate the available height
                          return _buildTableCalendarWithSize();
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 32),
                    _buildStartWorkoutButton(),
                    const SizedBox(height: 32),
                  ],

                  _buildContinueWorkoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildStartWorkoutButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Color(0xFFC7A97F),
            Color(0xFFD4B995),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFC7A97F).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _startWorkout,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.fitness_center, color: Colors.white, size: 24),
        label: Text(
          _isGenerating ? "Generating plan..." : "Start Workout",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size.fromHeight(60),
        ),
      ),
    );
  }

  Widget _buildContinueWorkoutButton() {
    final isEnabled = _plan != null;
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: isEnabled
            ? LinearGradient(
                colors: [
                  Color(0xFFC7A97F),
                  Color(0xFFD4B995),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Color(0xFFC7A97F).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _goToPlan : null,
        label: Text(
          "Workout Plan",
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey.shade700,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size.fromHeight(60),
          disabledForegroundColor: Colors.grey.shade600,
          disabledBackgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  // Build calendar with adjustable size based on number of rows
  Widget _buildTableCalendarWithSize() {
    final DateTime firstDay = _startDate!;
    final DateTime lastDay = _startDate!.add(Duration(days: (_plan!.length - 1) * 2));
    
    // Calculate number of rows that will be displayed
    // Get the first day of the month we're viewing
    final DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    
    // Find what day of the week the 1st falls on (0 = Monday with StartingDayOfWeek.monday)
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;
    if (firstWeekdayOfMonth == 7) firstWeekdayOfMonth = 0; // Convert Sunday from 7 to 0
    
    // Calculate days in month
    final int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    // Calculate total cells needed (previous month days showing + days in month)
    final int totalCells = firstWeekdayOfMonth + daysInMonth;
    
    // Calculate number of rows (divide by 7 days per week and round up)
    final int numberOfRows = (totalCells / 7).ceil();
    
    // Adjust row height based on number of rows
    final rowHeight = numberOfRows > 5 ? 42.0 : 46.0;
    
    return TableCalendar(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: _focusedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      calendarFormat: CalendarFormat.month,
      sixWeekMonthsEnforced: false, // Allow flexible height for months with fewer weeks
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ) ?? TextStyle(),
        leftChevronIcon: Container(
          decoration: BoxDecoration(
            color: Color(0xFFC7A97F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.chevron_left, color: Color(0xFFC7A97F), size: 22),
        ),
        rightChevronIcon: Container(
          decoration: BoxDecoration(
            color: Color(0xFFC7A97F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.chevron_right, color: Color(0xFFC7A97F), size: 22),
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 10),
        headerMargin: const EdgeInsets.only(bottom: 6),
      ),
      rowHeight: rowHeight, // Dynamic row height
      daysOfWeekHeight: 30, // Reduced further
      calendarStyle: CalendarStyle(
        defaultTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: Colors.grey,
        ) ?? TextStyle(),
        disabledTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: Colors.black,
              fontSize: 16,
            ),
        todayTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
        todayDecoration: BoxDecoration(
          color: Color(0xFFC7A97F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFC7A97F).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        selectedTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
        selectedDecoration: BoxDecoration(
          color: Color(0xFFC7A97F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFC7A97F).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        weekendTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: Colors.grey,
              fontSize: 16,
            ),
        markerDecoration: BoxDecoration(
          color: Color(0xFFC7A97F),
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.all(4), // Slightly reduced margin
        cellPadding: EdgeInsets.zero,
      ),
      eventLoader: (day) {
        final simpleDay = DateTime(day.year, day.month, day.day);
        final isWorkout = _workoutDays.any((d) =>
          d.year == simpleDay.year && d.month == simpleDay.month && d.day == simpleDay.day
        );
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
              bottom: 3, // Slightly reduced spacing
              child: Container(
                width: 6, // Slightly smaller marker
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFFC7A97F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFC7A97F).withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
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
                color: enabled ? Color(0xFFC7A97F).withOpacity(0.15) : Colors.transparent,
                border: enabled
                    ? Border.all(
                        color: Color(0xFFC7A97F),
                        width: 2,
                      )
                    : null,
                boxShadow: enabled ? [
                  BoxShadow(
                    color: Color(0xFFC7A97F).withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 0.5,
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: (Theme.of(context).textTheme.bodyMedium ?? TextStyle()).copyWith(
                    color: enabled
                        ? Color(0xFFC7A97F)
                        : Colors.black,
                    fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                    fontSize: numberOfRows > 5 ? 14 : 16,
                  ),
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final text = DateFormat.E().format(day);
          final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
          
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isWeekend ? Color(0xFFC7A97F) : Color(0xFFC7A97F),
                ),
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
        
        // Не тренировочный день
        if (diff < 0 || diff % 2 != 0) {
          return;
        }
        
        // Вычисляем номер тренировочного дня (0-based)
        final dayNumber = diff ~/ 2;
        
        // Индекс дня в плане (1-based, так как dayIndex в плане начинается с 1)
        final targetDayIndex = dayNumber + 1;
        
        // Проверяем, есть ли день с таким индексом в плане
        if (dayNumber < _plan!.length && _isDayOpen(targetDayIndex)) {
          // Находим конкретный день для открытия
          final dayToOpen = _plan!.firstWhere((d) => d.dayIndex == targetDayIndex, 
            orElse: () => DayInfo(dayIndex: -1, part: '', exercises: []));
            
          if (dayToOpen.dayIndex == -1) {
            return;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutPlanScreen(
                days: [dayToOpen],
                availableDays: {targetDayIndex},
                onWorkoutComplete: _onWorkoutComplete,
              ),
            ),
          );
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