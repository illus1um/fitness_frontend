import 'exercise_info.dart';

class DayInfo {
  final int dayIndex;
  final String part;
  final List<ExerciseInfo> exercises;

  DayInfo({
    required this.dayIndex,
    required this.part,
    required this.exercises,
  });
} 