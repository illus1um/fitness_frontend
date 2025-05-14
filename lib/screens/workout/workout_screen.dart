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
    final plan = await PlanCache.loadPlan();
    final sd   = await PlanCache.loadStartDate();
    if (plan != null && sd != null) {
      _prepareWorkoutDays(plan, sd);
      setState(() {
        _plan = plan;
        _startDate = sd;
      });
    }
  }

  void _prepareWorkoutDays(List<DayInfo> plan, DateTime sd) {
    _workoutDays.clear();
    for (int i = 0; i < plan.length; i++) {
      final day = DateTime(sd.year, sd.month, sd.day)
          .add(Duration(days: i * 2));
      _workoutDays.add(day);
    }
  }

  Future<void> _startWorkout() async {
    if (userData == null) return;
    if (_plan != null) {
      _goToPlan();
      return;
    }

    setState(() => _isGenerating = true);

    final plan = await PlanGenerator.generatePlan(
      program:    userData!['training_program'],
      location:   userData!['training_location'],
      experience: userData!['training_experience'],
      dayCount:   15,
    );

    setState(() => _isGenerating = false);

    await PlanCache.savePlan(plan);
    final sd = await PlanCache.loadStartDate();
    if (sd != null) _prepareWorkoutDays(plan, sd);

    setState(() {
      _plan = plan;
      _startDate = sd;
    });

    _goToPlan();
  }

  void _goToPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlanScreen(days: _plan!),
      ),
    );
  }

  /// Проверяет, можно ли уже открыть тренировочный день [i]
  bool _isDayOpen(int i) {
    if (_startDate == null) return false;
    final scheduled = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    ).add(Duration(days: i * 2));

    final today = DateTime.now();
    // Открыт, если дата <= сегодня
    return !scheduled.isAfter(
      DateTime(today.year, today.month, today.day),
    );
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
                      'Your Training Schedule',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Календарь фиксированной высоты
                    SizedBox(
                      height: 320,
                      child: _buildTableCalendar(),
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
                    onPressed: _plan != null ? _goToPlan : null,
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
      enabledDayPredicate: (day) {
        final diff = day.difference(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        ).inDays;
        if (diff < 0 || diff % 2 != 0) return false;
        final idx = diff ~/ 2;
        return idx < _plan!.length && _isDayOpen(idx);
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (ctx, day, focused) {
          final simpleDay = DateTime(day.year, day.month, day.day);
          final isWorkout = _workoutDays.contains(simpleDay);
          final diff = day.difference(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
          ).inDays;
          final enabled = diff >= 0 && diff % 2 == 0 && _isDayOpen(diff ~/ 2);
          final idx = diff ~/ 2;
          
          return Tooltip(
            message: isWorkout ? 'Training Day ${idx + 1}' : 'Rest Day',
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWorkout 
                    ? (enabled ? colorScheme.primary.withOpacity(0.2) : theme.disabledColor.withOpacity(0.2))
                    : null,
                border: isWorkout 
                    ? Border.all(
                        color: enabled ? colorScheme.primary : theme.disabledColor,
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: (theme.textTheme.bodyMedium ?? TextStyle()).copyWith(
                    color: enabled
                        ? (isWorkout
                            ? colorScheme.primary
                            : theme.textTheme.bodyMedium?.color ?? Colors.black)
                        : theme.disabledColor,
                    fontWeight: isWorkout ? FontWeight.bold : FontWeight.normal,
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
        
        final diff = selectedDay.difference(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        ).inDays;
        final idx = diff ~/ 2;
        if (idx >= 0 && idx < _plan!.length && _isDayOpen(idx)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutPlanScreen(
                days: [_plan![idx]],
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