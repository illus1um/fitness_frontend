import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise_info.dart';
import '../models/day_info.dart';
import '../utils/equipment_utils.dart';
import 'exercise_file_service.dart';

class PlanGenerator {
  /// Максимальное количество упражнений в день
  static const int MAX_EXERCISES_PER_DAY = 8;
  
  /// Минимальное количество упражнений в день
  static const int MIN_EXERCISES_PER_DAY = 4;
  
  /// Генерирует [dayCount] дней тренировок
  /// на основе выбранных пользователем параметров.
  static Future<List<DayInfo>> generatePlan({
    required String program,    // e.g. "Gain Muscle Mass", "Legs", etc.
    required String location,   // "At home" или "In The Gym"
    required String experience, // e.g. "Experienced"
    required int dayCount,      // например, 4
  }) async {
    // 1) Загрузка упражнений через сервис (из локального файла или из assets)
    final allExercises = await ExerciseFileService.loadExercises();

    // 2) Фильтрация по трём критериям, с проверкой оборудования
    final filtered = allExercises.where((ex) {
      // Строгая фильтрация по локации
      bool locationMatch = _matchesLocation(ex, location);
      
      // Для домашних тренировок - дополнительно проверяем оборудование
      if (location.toLowerCase() == "at home") {
        // Проверяем на наличие оборудования, которое не доступно дома
        if (EquipmentUtils.isGymOnlyEquipment(ex.equipment)) {
          return false;
        }
        
        // Для домашних тренировок разрешаем только оборудование, доступное дома
        if (!EquipmentUtils.isHomeEquipment(ex.equipment)) {
          return false;
        }
      }
      
      return _matchesProgram(ex, program)
          && locationMatch
          && _matchesExperience(ex, experience);
    }).toList();

    // Лог для отладки
    print('PlanGenerator: всего упражнений после фильтрации: ${filtered.length}');

    // 4) Перемешиваем для разнообразия
    filtered.shuffle();

    // 5) Разбиваем на дни, учитывая группы мышц
    final List<DayInfo> result = [];
    
    // Группируем по основным группам мышц
    final Map<String, List<ExerciseInfo>> exercisesByBodyPart = {};
    
    // Создаем группы по bodyPart
    for (final ex in filtered) {
      if (!exercisesByBodyPart.containsKey(ex.bodyPart)) {
        exercisesByBodyPart[ex.bodyPart] = [];
      }
      exercisesByBodyPart[ex.bodyPart]!.add(ex);
    }
    
    // Распределяем упражнения по дням, обеспечивая разнообразие
    for (int i = 0; i < dayCount; i++) {
      // Создаем список упражнений для текущего дня
      List<ExerciseInfo> dayExercises = [];
      
      // Определяем фокус дня (основную группу мышц)
      String focusBodyPart = '';
      
      // Если это первый день или у нас закончились все группы мышц, перемешаем и начнем сначала
      if (exercisesByBodyPart.isEmpty) {
        // Перемешиваем снова, если закончились упражнения
        filtered.shuffle();
        for (final ex in filtered) {
          if (!exercisesByBodyPart.containsKey(ex.bodyPart)) {
            exercisesByBodyPart[ex.bodyPart] = [];
          }
          exercisesByBodyPart[ex.bodyPart]!.add(ex);
        }
      }
      
      // Выбираем группу мышц с наибольшим количеством упражнений
      if (exercisesByBodyPart.isNotEmpty) {
        focusBodyPart = exercisesByBodyPart.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b)
            .key;
      }
      
      // Добавляем упражнения для основной группы мышц (максимум 4)
      if (exercisesByBodyPart.containsKey(focusBodyPart) && 
          exercisesByBodyPart[focusBodyPart]!.isNotEmpty) {
        // Берем до 4 упражнений для основной группы мышц
        int focusExCount = exercisesByBodyPart[focusBodyPart]!.length > 4 
            ? 4 
            : exercisesByBodyPart[focusBodyPart]!.length;
        
        for (int j = 0; j < focusExCount; j++) {
          if (exercisesByBodyPart[focusBodyPart]!.isNotEmpty) {
            dayExercises.add(exercisesByBodyPart[focusBodyPart]!.removeAt(0));
          }
        }
        
        // Если упражнений не осталось, удаляем группу мышц из словаря
        if (exercisesByBodyPart[focusBodyPart]!.isEmpty) {
          exercisesByBodyPart.remove(focusBodyPart);
        }
      }
      
      // Добавляем упражнения для других групп мышц (чтобы всего было от MIN до MAX)
      // Перемешиваем ключи для разнообразия
      final otherBodyParts = exercisesByBodyPart.keys.toList()..shuffle();
      
      for (final bodyPart in otherBodyParts) {
        if (dayExercises.length >= MAX_EXERCISES_PER_DAY) break;
        
        if (exercisesByBodyPart[bodyPart]!.isNotEmpty) {
          dayExercises.add(exercisesByBodyPart[bodyPart]!.removeAt(0));
          
          // Удаляем пустые списки
          if (exercisesByBodyPart[bodyPart]!.isEmpty) {
            exercisesByBodyPart.remove(bodyPart);
          }
        }
      }
      
      // Если упражнений слишком мало, добавим из перемешанного общего списка
      if (dayExercises.length < MIN_EXERCISES_PER_DAY) {
        final additionalExercises = filtered
            .where((ex) => !dayExercises.contains(ex))
            .take(MIN_EXERCISES_PER_DAY - dayExercises.length)
            .toList();
        
        dayExercises.addAll(additionalExercises);
      }
      
      // Перемешиваем упражнения внутри дня для разнообразия
      dayExercises.shuffle();
      
      print('PlanGenerator: день ${i + 1} содержит ${dayExercises.length} упражнений');
      
      // Создаем DayInfo
      result.add(DayInfo(
        dayIndex: i + 1,
        part: _determineDayFocus(dayExercises),
        exercises: dayExercises,
      ));
    }
    
    return result;
  }
  
  /// Определяет основную группу мышц для дня на основе упражнений
  static String _determineDayFocus(List<ExerciseInfo> exercises) {
    if (exercises.isEmpty) return '';
    
    // Считаем количество упражнений для каждой группы мышц
    final counts = <String, int>{};
    for (final ex in exercises) {
      counts[ex.bodyPart] = (counts[ex.bodyPart] ?? 0) + 1;
    }
    
    // Находим группу с наибольшим количеством упражнений
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
}