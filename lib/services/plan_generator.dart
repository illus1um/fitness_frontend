import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise_info.dart';
import '../models/day_info.dart';

class PlanGenerator {
  /// Генерирует [dayCount] дней тренировок
  /// на основе выбранных пользователем параметров.
  static Future<List<DayInfo>> generatePlan({
    required String program,    // e.g. "Gain Muscle Mass", "Legs", etc.
    required String location,   // "At home" или "In The Gym"
    required String experience, // e.g. "Experienced"
    required int dayCount,      // например, 4
  }) async {
    // 1) Загрузка JSON из assets
    final jsonStr = await rootBundle.loadString('assets/workout_exercises_full.json');
    final List<dynamic> rawList = json.decode(jsonStr);

    // 2) Парсинг в модель
    final allExercises = rawList
        .map((m) => ExerciseInfo.fromJson(m as Map<String, dynamic>))
        .toList();

    // 3) Фильтрация по трём критериям
    final filtered = allExercises.where((ex) {
      return _matchesProgram(ex, program)
          && _matchesLocation(ex, location)
          && _matchesExperience(ex, experience);
    }).toList();

    // Лог для отладки
    print('PlanGenerator: всего упражнений после фильтрации: ${filtered.length}');

    // 4) Перемешиваем для разнообразия
    filtered.shuffle();

    // 5) Разбиваем на сплит-дни
    final perDay = (filtered.length / dayCount).ceil();
    return List.generate(dayCount, (i) {
      final slice = filtered.skip(i * perDay).take(perDay).toList();
      print('PlanGenerator: день ${i + 1} содержит ${slice.length} упражнений');
      return DayInfo(
        dayIndex: i + 1,
        part: _mostCommon(slice.map((e) => e.bodyPart).toList()),
        exercises: slice,
      );
    });
  }

  /// Проверяет совпадение упражнения с программой.
  /// Если user выбрал "Legs", подбираем упражнения по bodyPart = upper|lower legs.
  static bool _matchesProgram(ExerciseInfo ex, String program) {
    final prog = program.toLowerCase();
    if (prog == 'legs') {
      return ['upper legs', 'lower legs']
          .contains(ex.bodyPart.toLowerCase());
    }
    // Иначе сравниваем с JSON-программами, игнорируя регистр
    return ex.programs.any((p) => p.toLowerCase() == prog);
  }

  /// Локация (At home / In The Gym)
  static bool _matchesLocation(ExerciseInfo ex, String location) {
    return ex.locations.any((l) => l.toLowerCase() == location.toLowerCase());
  }

  /// Уровень опыта
  static bool _matchesExperience(ExerciseInfo ex, String experience) {
    return ex.experienceLevels
        .any((e) => e.toLowerCase() == experience.toLowerCase());
  }

  /// Возвращает наиболее часто встречающуюся bodyPart или пустую строку для пустого списка
  static String _mostCommon(List<String> items) {
    if (items.isEmpty) return '';
    final counts = <String,int>{};
    for (var it in items) {
      counts[it] = (counts[it] ?? 0) + 1;
    }
    return counts.entries.reduce((a,b) => a.value >= b.value ? a : b).key;
  }
}