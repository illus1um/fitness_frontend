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

  factory DayInfo.fromJson(Map<String, dynamic> j) => DayInfo(
        dayIndex: j['dayIndex'],
        part: j['part'],
        exercises: (j['exercises'] as List)
            .map((e) => ExerciseInfo.fromStorage(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'part': part,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
