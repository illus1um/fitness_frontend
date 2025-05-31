import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exercise_info.dart';

/// Сервис для управления файлами упражнений
class ExerciseFileService {
  /// Имя файла с упражнениями
  static const String EXERCISE_FILE_NAME = 'workout_exercises_full.json';

  /// Загружает упражнения из assets или из файла в документах, если он там есть
  static Future<List<ExerciseInfo>> loadExercises() async {
    try {
      // Проверяем, есть ли файл в директории документов
      final appDocDir = await getApplicationDocumentsDirectory();
      final customFile = File('${appDocDir.path}/$EXERCISE_FILE_NAME');
      
      String jsonString;
      
      if (await customFile.exists()) {
        // Если файл существует в документах, используем его
        jsonString = await customFile.readAsString();
        print('ExerciseFileService: Загружены упражнения из локального файла');
      } else {
        // Иначе загружаем из assets
        jsonString = await rootBundle.loadString('assets/$EXERCISE_FILE_NAME');
        print('ExerciseFileService: Загружены упражнения из assets');
      }
      
      final List<dynamic> rawList = json.decode(jsonString);
      
      return rawList
          .map((m) => ExerciseInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('ExerciseFileService: Ошибка при загрузке упражнений: $e');
      
      // Fallback - загружаем из assets
      final jsonString = await rootBundle.loadString('assets/$EXERCISE_FILE_NAME');
      final List<dynamic> rawList = json.decode(jsonString);
      
      return rawList
          .map((m) => ExerciseInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    }
  }

  /// Заменяет файл с упражнениями из assets на исправленную версию
  static Future<bool> replaceExerciseFile(String jsonContent) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetFile = File('${appDocDir.path}/$EXERCISE_FILE_NAME');
      
      await targetFile.writeAsString(jsonContent);
      
      print('ExerciseFileService: Файл упражнений успешно заменён');
      return true;
    } catch (e) {
      print('ExerciseFileService: Ошибка при замене файла упражнений: $e');
      return false;
    }
  }

  /// Возвращает файл к стандартному из assets
  static Future<bool> resetToDefault() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final customFile = File('${appDocDir.path}/$EXERCISE_FILE_NAME');
      
      if (await customFile.exists()) {
        await customFile.delete();
        print('ExerciseFileService: Восстановлен файл упражнений по умолчанию');
      }
      
      return true;
    } catch (e) {
      print('ExerciseFileService: Ошибка при сбросе файла упражнений: $e');
      return false;
    }
  }
} 