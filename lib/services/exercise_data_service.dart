import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_info.dart';

class ExerciseDataService {
  static Map<String, String> _exerciseNames = {};
  static Map<String, ExerciseInfo> _exerciseData = {};
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/workout_exercises_full.json');
      final List<dynamic> exercises = json.decode(jsonString);
      
      for (final exercise in exercises) {
        final exerciseInfo = ExerciseInfo.fromJson(Map<String, dynamic>.from(exercise));
        _exerciseData[exerciseInfo.id] = exerciseInfo;
        _exerciseNames[exerciseInfo.id] = exerciseInfo.name;
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing exercise data: $e');
    }
  }

  static String getExerciseName(String exerciseId) {
    if (!_isInitialized) {
      return exerciseId;
    }
    
    return _exerciseNames[exerciseId] ?? exerciseId;
  }
  
  static ExerciseInfo? getExerciseInfo(String exerciseId) {
    if (!_isInitialized) return null;
    
    return _exerciseData[exerciseId];
  }

  static Map<String, dynamic>? getExerciseById(String exerciseId) {
    if (!_isInitialized) return null;
    
    final exercise = _exerciseData[exerciseId];
    if (exercise == null) return null;
    
    return {
      'name': exercise.name,
      'bodyPart': exercise.bodyPart,
      'equipment': exercise.equipment,
      'target': exercise.target,
      'secondaryTargets': exercise.secondaryTargets,
      'programs': exercise.programs,
      'locations': exercise.locations,
      'experienceLevels': exercise.experienceLevels,
    };
  }
} 