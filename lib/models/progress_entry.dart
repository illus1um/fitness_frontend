class ProgressEntry {
  final int dayIndex;
  final String exerciseId;
  final int setsCompleted;
  final DateTime completedAt;

  ProgressEntry({
    required this.dayIndex,
    required this.exerciseId,
    required this.setsCompleted,
    required this.completedAt,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      dayIndex: json['day_index'] as int,
      exerciseId: json['exercise_id'] as String,
      setsCompleted: json['sets_completed'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_index': dayIndex,
        'exercise_id': exerciseId,
        'sets_completed': setsCompleted,
      };
}
