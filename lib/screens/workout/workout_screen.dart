// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_generator.dart';
import 'package:fitness_app/services/plan_cache.dart';
import 'package:fitness_app/services/notification_service.dart';
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
  
  bool? _hasGeneratedPlanCache;
  bool _isLoading = true; 

  final Set<DateTime> _workoutDays = {};
  
  final Set<int> _availableDays = {};
  
  List<ProgressEntry> _progress = [];

  @override
  void initState() {
    super.initState();
    _init();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasGeneratedPlanCache == true) {
      _refreshDataInBackground();
    }
  }
  
  Future<void> _init() async {
    setState(() => _isLoading = true);
    
    await _loadUserData();
    
    final serverPlan = await ApiService.getPlan();
    
    if (serverPlan != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', true);
      _hasGeneratedPlanCache = true;
      await _loadCachedPlan();
    } else {
      final cachedPlan = await PlanCache.loadPlan();
      final startDate = await PlanCache.loadStartDate();
      
      if (cachedPlan != null && startDate != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_generated_plan', true);
        _hasGeneratedPlanCache = true;
        await _loadCachedPlan();
      } else {
        final hasGenerated = await _checkUserHasGeneratedPlan();
        _hasGeneratedPlanCache = hasGenerated;
        
        if (hasGenerated) {
          await _loadCachedPlan();
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();
    if (data != null && mounted) {
      setState(() => userData = data);
    }
  }

  Future<void> _loadCachedPlan() async {
    try {
      final serverPlan = await ApiService.getPlan();
      
      final prefs = await SharedPreferences.getInstance();
      
      if (serverPlan != null) {
        await prefs.setBool('has_generated_plan', true);
        _hasGeneratedPlanCache = true;
        
        final plan = serverPlan['days'] as List<DayInfo>;
        final startDate = serverPlan['start_date'] as DateTime;
        final progress = await ApiService.getProgress();
        
        await PlanCache.savePlan(plan);
        await PlanCache.saveStartDate(startDate);
        await PlanCache.saveProgress(progress);
        
        _prepareWorkoutDays(plan, startDate);
        _updateAvailableDays(plan, startDate, progress);
        
        setState(() {
          _plan = plan;
          _startDate = startDate;
          _progress = progress;
        });
        
        print('DEBUG: Plan loaded from server with ${plan.length} days');
        return;
      }

      final hasGeneratedPlan = prefs.getBool('has_generated_plan') ?? false;
      
      final plan = await PlanCache.loadPlan();
      final sd = await PlanCache.loadStartDate();
      final progress = await PlanCache.loadProgress();
      
      if (plan != null && sd != null) {
        await prefs.setBool('has_generated_plan', true);
        _hasGeneratedPlanCache = true;
        
        _prepareWorkoutDays(plan, sd);
        _updateAvailableDays(plan, sd, progress);
        
        setState(() {
          _plan = plan;
          _startDate = sd;
          _progress = progress;
        });
        
        await ApiService.savePlan(plan, sd);
        
        print('DEBUG: Plan loaded from cache and saved to server with ${plan.length} days');
      } else {
        _hasGeneratedPlanCache = hasGeneratedPlan;
        print('DEBUG: No plan found in cache or server');
      }
    } catch (e) {
      print('ERROR loading plan: $e');
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
      setState(() {}); 
      return;
    }

    setState(() => _isGenerating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_generated_plan', true);
    
    _hasGeneratedPlanCache = true;

    await ApiService.clearProgress();
    await ApiService.clearPlan();
    await PlanCache.clearPlan();
    
    await NotificationService.cancelAllWorkoutNotifications();

    final startDate = DateTime.now();
    await PlanCache.saveStartDate(startDate);

    await Future.delayed(Duration(milliseconds: 800));

    final plan = await PlanGenerator.generatePlan(
      program:    userData!['training_program'],
      location:   userData!['training_location'],
      experience: userData!['training_experience'],
      dayCount:   15,
    );

    await Future.delayed(Duration(milliseconds: 500));

    await PlanCache.savePlan(plan);
    await ApiService.savePlan(plan, startDate);
    
    _prepareWorkoutDays(plan, startDate);
    
    if (plan.isNotEmpty) {
      int firstDayIndex = plan[0].dayIndex;
      _availableDays.add(firstDayIndex);
    }

    setState(() {
      _plan = plan;
      _startDate = startDate;
      _progress = [];
      _isGenerating = false; 
    });

    if (context.mounted) {
    }
  }

  void _prepareWorkoutDays(List<DayInfo> plan, DateTime sd) {
    _workoutDays.clear();
    final startDate = DateTime(sd.year, sd.month, sd.day);
    
    final List<DateTime> workoutDates = [];
    
    for (int i = 0; i < plan.length; i++) {
      final dayIndex = plan[i].dayIndex;
      
      int daysBetweenWorkouts = plan.length <= 15 ? 2 : 1;
      
      final dayOffset = (dayIndex - 1) * daysBetweenWorkouts;
      final workoutDay = startDate.add(Duration(days: dayOffset));
      
      final cleanDate = DateTime(workoutDay.year, workoutDay.month, workoutDay.day);
      _workoutDays.add(cleanDate);
      workoutDates.add(cleanDate);
      print('Added workout day: ${workoutDay.toString()} for day index $dayIndex');
    }
    
    _scheduleWorkoutNotifications(workoutDates, plan);
  }
  
  Future<void> _scheduleWorkoutNotifications(List<DateTime> workoutDates, List<DayInfo> plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('workout_notifications_enabled') ?? true;
      
      if (!notificationsEnabled) {
        print('DEBUG: Workout notifications are disabled in settings');
        return;
      }
      
      await NotificationService.scheduleWorkoutNotifications(workoutDates, plan);
      print('DEBUG: Workout notifications scheduled for ${workoutDates.length} days');
    } catch (e) {
      print('ERROR: Failed to schedule workout notifications: $e');
    }
  }

  void _updateAvailableDays(List<DayInfo> plan, DateTime startDate, List<ProgressEntry> progress) {
    _availableDays.clear();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    print('DEBUG: Today: $today');
    
    final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    print('DEBUG: Clean start date: $cleanStartDate');
    
    final int daysBetweenWorkouts = plan.length <= 15 ? 2 : 1;
    
    List<DayInfo> normalizedPlan = [];
    for (int i = 0; i < plan.length; i++) {
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
    
    for (int i = 0; i < normalizedPlan.length; i++) {
      final dayInfo = normalizedPlan[i];
      final dayIndex = dayInfo.dayIndex;
      
      final dayOffset = (dayIndex - 1) * daysBetweenWorkouts;
      final workoutDate = cleanStartDate.add(Duration(days: dayOffset));
      
      final diffFromToday = today.difference(workoutDate).inDays;
      
      print('DEBUG: Day $dayIndex date: $workoutDate, diff from today: $diffFromToday');
      
      if (diffFromToday >= 0) {
        _availableDays.add(dayIndex);
        continue;
      }
      
      if (i == 0) {
        _availableDays.add(dayIndex);
        continue;
      }
      
      final prevDayIndex = normalizedPlan[i - 1].dayIndex;
      if (_isDayCompleted(prevDayIndex, progress, plan)) {
        _availableDays.add(dayIndex);
        continue;
      }
    }
    
    print('DEBUG: Available days after update: $_availableDays');
  }
  
  bool _isDayCompleted(int dayIndex, List<ProgressEntry> progress, List<DayInfo> plan) {
    final day = plan.firstWhere((d) => d.dayIndex == dayIndex, orElse: () => DayInfo(
      dayIndex: -1,
      part: '',
      exercises: [],
    ));
    
    if (day.dayIndex == -1 || day.exercises.isEmpty) {
      print('DEBUG: Day $dayIndex not found or has no exercises');
      return false;
    }
    
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
    return completedExercises == totalExercises;
  }

  void _goToPlan() {
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
  
  Future<void> _onWorkoutComplete() async {
    final updatedProgress = await ApiService.getProgress();
    
    await PlanCache.saveProgress(updatedProgress);
    
    if (_plan != null && _startDate != null) {
      _updateAvailableDays(_plan!, _startDate!, updatedProgress);
      setState(() {
        _progress = updatedProgress;
      });
    }
  }

  bool _isDayOpen(int dayIndex) {
    return _availableDays.contains(dayIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout Overview"),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
      body: userData == null || _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7A97F)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading your workout profile...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC7A97F),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  if (_plan != null && _startDate != null && _hasGeneratedPlanCache == true) ...[
                    Text(
                      'Training Schedule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    AnimatedOpacity(
                      opacity: _isGenerating ? 0.3 : 1.0,
                      duration: Duration(milliseconds: 500),
                      child: Container(
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildTableCalendarWithSize();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _isGenerating
                      ? _buildGeneratingPlanIndicator()
                      : (_plan == null || _hasGeneratedPlanCache != true
                          ? _buildStartWorkoutButton()
                          : _buildViewPlanButton()),
                ],
              ),
            ),
    );
  }

  Widget _buildStartWorkoutButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
            color: Color.fromARGB(255, 199, 160, 106).withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 1),
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

  Widget _buildViewPlanButton() {
    final isEnabled = _plan != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                colors: isDarkMode
                    ? [Colors.grey.shade800, Colors.grey.shade700]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Color.fromARGB(255, 199, 160, 106).withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _goToPlan : null,
        icon: Icon(
          Icons.fitness_center, 
          color: isEnabled ? Colors.white : Colors.grey.shade700,
          size: 24,
        ),
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

  Widget _buildGeneratingPlanIndicator() {
    return Column(
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7A97F)),
        ),
        SizedBox(height: 16),
        Text(
          "Generating your personalized plan...",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFC7A97F),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTableCalendarWithSize() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    // Определяем интервал между тренировками на основе размера плана
    final int daysBetweenWorkouts = _plan!.length <= 15 ? 2 : 1;
    
    final DateTime firstDay = _startDate!;
    final DateTime lastDay = _startDate!.add(Duration(days: (_plan!.length - 1) * daysBetweenWorkouts + 30));
    
    final DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;
    if (firstWeekdayOfMonth == 7) firstWeekdayOfMonth = 0;

    final int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    final int totalCells = firstWeekdayOfMonth + daysInMonth;

    final int numberOfRows = (totalCells / 7).ceil();

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
      sixWeekMonthsEnforced: false,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ) ?? TextStyle(),
        leftChevronIcon: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Color(0xFF3A3225) // Darker gold for dark mode
                : goldColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.chevron_left, color: goldColor, size: 22),
        ),
        rightChevronIcon: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Color(0xFF3A3225) // Darker gold for dark mode
                : goldColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.chevron_right, color: goldColor, size: 22),
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 10),
        headerMargin: const EdgeInsets.only(bottom: 6),
      ),
      rowHeight: rowHeight, // Dynamic row height
      daysOfWeekHeight: 30, // Reduced further
      calendarStyle: CalendarStyle(
        defaultTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
        ) ?? TextStyle(),
        disabledTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
        todayTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: isDarkMode ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
        todayDecoration: BoxDecoration(
          color: goldColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        selectedTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: isDarkMode ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
        selectedDecoration: BoxDecoration(
          color: goldColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        weekendTextStyle: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
            .copyWith(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
              fontSize: 16,
            ),
        markerDecoration: BoxDecoration(
          color: goldColor,
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
                  color: goldColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(0.3),
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
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final goldColor = Color(0xFFC7A97F);
          
          final simpleDay = DateTime(day.year, day.month, day.day);
          if (_startDate == null) return null;
          
          // Проверяем, находится ли день в списке тренировочных дней
          final isWorkoutDay = _workoutDays.any((workoutDate) =>
            workoutDate.year == simpleDay.year && 
            workoutDate.month == simpleDay.month && 
            workoutDate.day == simpleDay.day
          );
          
          if (!isWorkoutDay) return null;
          
          // Вычисляем разницу в днях между днём календаря и начальной датой
          final diff = simpleDay.difference(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
          ).inDays;
          
          // Находим индекс тренировочного дня (учитывая, что тренировки каждые 2 дня)
          final dayNumber = diff ~/ 2;
          // В плане индексы начинаются с 1
          final dayIndex = dayNumber + 1;
          
          // Проверяем, доступен ли день
          final enabled = _isDayOpen(dayIndex);
          
          return Tooltip(
            message: enabled ? 'Training Day $dayIndex' : 'Locked Training Day $dayIndex',
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled 
                    ? (isDarkMode ? Color(0xFF3A3225) : goldColor.withOpacity(0.15))
                    : Colors.transparent,
                border: enabled
                    ? Border.all(
                        color: goldColor,
                        width: 2,
                      )
                    : null,
                boxShadow: enabled ? [
                  BoxShadow(
                    color: goldColor.withOpacity(isDarkMode ? 0.3 : 0.2),
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
                        ? goldColor
                        : (isDarkMode ? Colors.white : Colors.black),
                    fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                    fontSize: numberOfRows > 5 ? 14 : 16,
                  ),
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final goldColor = Color(0xFFC7A97F);
          
          final text = DateFormat.E().format(day);
          final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
          
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode 
                        ? Colors.grey.shade800 
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            child: Text(
              text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: goldColor,
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
        
        // Определяем интервал между тренировками
        int daysBetweenWorkouts = _plan!.length <= 15 ? 2 : 1;
        
        // Не тренировочный день если имеет отрицательную разницу или не соответствует интервалу
        if (diff < 0 || (daysBetweenWorkouts == 2 && diff % 2 != 0)) {
          return;
        }
        
        // Вычисляем номер тренировочного дня (0-based)
        final dayNumber = daysBetweenWorkouts == 2 ? diff ~/ 2 : diff;
        
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: isDarkMode ? 0 : 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.flag,
            title: "Goal",
            value: userData!["training_program"] ?? "Not set",
            isFirst: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDarkMode 
                  ? Colors.grey.shade800
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          _buildInfoTile(
            icon: Icons.location_on,
            title: "Location",
            value: userData!["training_location"] ?? "Not set",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDarkMode 
                  ? Colors.grey.shade800
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          _buildInfoTile(
            icon: Icons.emoji_events,
            title: "Experience",
            value: userData!["training_experience"] ?? "Not set",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Container(
      padding: EdgeInsets.only(
        top: isFirst ? 16 : 12,
        bottom: isLast ? 16 : 12,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Color(0xFF3A3225)  // Darker gold for dark mode
                  : goldColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: goldColor,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to check if user has generated a plan
  Future<bool> _checkUserHasGeneratedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_generated_plan') ?? false;
  }

  // Метод для фонового обновления данных без индикатора загрузки
  Future<void> _refreshDataInBackground() async {
    // Загружаем данные пользователя в фоне
    await _loadUserData();
    
    // Проверяем наличие плана на сервере
    final serverPlan = await ApiService.getPlan();
    
    // Если план существует на сервере, устанавливаем флаг и загружаем данные
    if (serverPlan != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', true);
      _hasGeneratedPlanCache = true;
      
      if (_plan == null || _startDate == null) {
        await _loadCachedPlan();
        if (mounted) setState(() {});
      }
      return;
    }
    
    // Проверим наличие плана в кэше
    final cachedPlan = await PlanCache.loadPlan();
    final startDate = await PlanCache.loadStartDate();
    
    if (cachedPlan != null && startDate != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', true);
      _hasGeneratedPlanCache = true;
      
      if (_plan == null || _startDate == null) {
        await _loadCachedPlan();
        if (mounted) setState(() {});
      }
      return;
    }
    
    // Если плана нет ни на сервере, ни в кэше, проверим только статус флага
    final prefs = await SharedPreferences.getInstance();
    final hasGenerated = prefs.getBool('has_generated_plan') ?? false;
    
    if (hasGenerated != _hasGeneratedPlanCache) {
      _hasGeneratedPlanCache = hasGenerated;
      if (mounted) setState(() {});
    }
    
    // Если план был сгенерирован согласно флагу, но не загружен, загрузим его
    if (hasGenerated && (_plan == null || _startDate == null)) {
      await _loadCachedPlan();
      if (mounted) setState(() {});
    }
  }
}