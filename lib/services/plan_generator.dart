import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise_info.dart';
import '../models/day_info.dart';
import '../utils/equipment_utils.dart';
import 'exercise_file_service.dart';

class PlanGenerator {
  static const int MAX_EXERCISES_PER_DAY = 8;
  
  static const int MIN_EXERCISES_PER_DAY = 4;
  
  static Future<List<DayInfo>> generatePlan({
    required String program,    
    required String location,   
    required String experience, 
    required int dayCount,      
  }) async {
    final allExercises = await ExerciseFileService.loadExercises();

    final filtered = allExercises.where((ex) {
      bool locationMatch = _matchesLocation(ex, location);
      
      if (location.toLowerCase() == "at home") {
        if (EquipmentUtils.isGymOnlyEquipment(ex.equipment)) {
          return false;
        }
        
        if (!EquipmentUtils.isHomeEquipment(ex.equipment)) {
          return false;
        }
      }
      
      return _matchesProgram(ex, program)
          && locationMatch
          && _matchesExperience(ex, experience);
    }).toList();

    print('PlanGenerator: всего упражнений после фильтрации: ${filtered.length}');

    filtered.shuffle();

    final List<DayInfo> result = [];
    
    final Map<String, List<ExerciseInfo>> exercisesByBodyPart = {};
    
    for (final ex in filtered) {
      if (!exercisesByBodyPart.containsKey(ex.bodyPart)) {
        exercisesByBodyPart[ex.bodyPart] = [];
      }
      exercisesByBodyPart[ex.bodyPart]!.add(ex);
    }
    
    for (int i = 0; i < dayCount; i++) {
      List<ExerciseInfo> dayExercises = [];
      
      String focusBodyPart = '';
      
      if (exercisesByBodyPart.isEmpty) {
        filtered.shuffle();
        for (final ex in filtered) {
          if (!exercisesByBodyPart.containsKey(ex.bodyPart)) {
            exercisesByBodyPart[ex.bodyPart] = [];
          }
          exercisesByBodyPart[ex.bodyPart]!.add(ex);
        }
      }
      
      if (exercisesByBodyPart.isNotEmpty) {
        focusBodyPart = exercisesByBodyPart.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b)
            .key;
      }
      
      if (exercisesByBodyPart.containsKey(focusBodyPart) && 
          exercisesByBodyPart[focusBodyPart]!.isNotEmpty) {
        int focusExCount = exercisesByBodyPart[focusBodyPart]!.length > 4 
            ? 4 
            : exercisesByBodyPart[focusBodyPart]!.length;
        
        for (int j = 0; j < focusExCount; j++) {
          if (exercisesByBodyPart[focusBodyPart]!.isNotEmpty) {
            dayExercises.add(exercisesByBodyPart[focusBodyPart]!.removeAt(0));
          }
        }
        
        if (exercisesByBodyPart[focusBodyPart]!.isEmpty) {
          exercisesByBodyPart.remove(focusBodyPart);
        }
      }
      
      final otherBodyParts = exercisesByBodyPart.keys.toList()..shuffle();
      
      for (final bodyPart in otherBodyParts) {
        if (dayExercises.length >= MAX_EXERCISES_PER_DAY) break;
        
        if (exercisesByBodyPart[bodyPart]!.isNotEmpty) {
          dayExercises.add(exercisesByBodyPart[bodyPart]!.removeAt(0));
          
          if (exercisesByBodyPart[bodyPart]!.isEmpty) {
            exercisesByBodyPart.remove(bodyPart);
          }
        }
      }
      
      if (dayExercises.length < MIN_EXERCISES_PER_DAY) {
        final additionalExercises = filtered
            .where((ex) => !dayExercises.contains(ex))
            .take(MIN_EXERCISES_PER_DAY - dayExercises.length)
            .toList();
        
        dayExercises.addAll(additionalExercises);
      }
      
      dayExercises.shuffle();
      
      print('PlanGenerator: день ${i + 1} содержит ${dayExercises.length} упражнений');
      
      result.add(DayInfo(
        dayIndex: i + 1,
        part: _determineDayFocus(dayExercises),
        exercises: dayExercises,
      ));
    }
    
    return result;
  }
  
  static String _determineDayFocus(List<ExerciseInfo> exercises) {
    if (exercises.isEmpty) return '';
    
    final counts = <String, int>{};
    for (final ex in exercises) {
      counts[ex.bodyPart] = (counts[ex.bodyPart] ?? 0) + 1;
    }
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static bool _matchesProgram(ExerciseInfo ex, String program) {
    final prog = program.toLowerCase();
    if (prog == 'legs') {
      return ['upper legs', 'lower legs']
          .contains(ex.bodyPart.toLowerCase());
    }
    return ex.programs.any((p) => p.toLowerCase() == prog);
  }

  static bool _matchesLocation(ExerciseInfo ex, String location) {
    return ex.locations.any((l) => l.toLowerCase() == location.toLowerCase());
  }
  
  static bool _matchesExperience(ExerciseInfo ex, String experience) {
    return ex.experienceLevels
        .any((e) => e.toLowerCase() == experience.toLowerCase());
  }
}