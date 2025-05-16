import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_info.dart';

/// Сервис для получения данных об упражнениях
class ExerciseDataService {
  static Map<String, String> _exerciseNames = {};
  static Map<String, ExerciseInfo> _exerciseData = {};
  static bool _isInitialized = false;

  /// Инициализирует сервис и загружает данные об упражнениях
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Загружаем данные из JSON файла с упражнениями
      final jsonString = await rootBundle.loadString('assets/workout_exercises_full.json');
      final List<dynamic> exercises = json.decode(jsonString);
      
      // Заполняем карту с именами упражнений и данными
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

  /// Возвращает название упражнения по ID
  static String getExerciseName(String exerciseId) {
    if (!_isInitialized) {
      // Если сервис не инициализирован, возвращаем ID как название
      return exerciseId;
    }
    
    return _exerciseNames[exerciseId] ?? exerciseId;
  }
  
  /// Возвращает данные об упражнении по ID
  static ExerciseInfo? getExerciseInfo(String exerciseId) {
    if (!_isInitialized) return null;
    
    return _exerciseData[exerciseId];
  }
} 