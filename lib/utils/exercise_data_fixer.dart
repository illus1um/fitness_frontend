import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exercise_info.dart';
import '../services/exercise_file_service.dart';
import 'equipment_utils.dart';


class ExerciseDataFixer {
  static Future<bool> fixExerciseData() async {
    try {
      // Загружаем упражнения через сервис
      final exercises = await ExerciseFileService.loadExercises();
      
      print('Загружено ${exercises.length} упражнений для коррекции');
      
      int fixedLocationCount = 0;
      int fixedExperienceCount = 0;
      
      final correctedExercises = exercises.map((ex) {
        final Map<String, dynamic> fixedData = ex.toJson();
        
        // 1. Исправляем locations: если упражнение требует оборудования из зала,
        // убираем "At home" из его locations
        if (ex.locations.contains('At home') && 
            EquipmentUtils.isGymOnlyEquipment(ex.equipment)) {
          fixedData['locations'] = ['In The Gym'];
          fixedLocationCount++;
        }
        
        // 2. Если оборудование доступно дома, но "At home" отсутствует, добавляем
        if (!ex.locations.contains('At home') && 
            EquipmentUtils.isHomeEquipment(ex.equipment) && 
            !EquipmentUtils.isGymOnlyEquipment(ex.equipment)) {
          fixedData['locations'] = [...ex.locations, 'At home'];
          fixedLocationCount++;
        }
        
        // 3. Исправляем уровень опыта для сложных упражнений
        if (_isAdvancedExercise(ex) && ex.experienceLevels.contains('Beginner')) {
          // Удаляем 'Beginner' и 'No experience' из списка
          final updatedLevels = ex.experienceLevels
              .where((level) => level != 'Beginner' && level != 'No experience')
              .toList();
          
          // Если список пуст, добавляем 'Experienced' и 'Pro'
          if (updatedLevels.isEmpty) {
            updatedLevels.addAll(['Experienced', 'Pro']);
          }
          
          fixedData['experienceLevels'] = updatedLevels;
          fixedExperienceCount++;
        }
        
        // 4. Исправляем базовые упражнения для новичков
        if (_isBasicExercise(ex) && !ex.experienceLevels.contains('Beginner')) {
          final updatedLevels = [...ex.experienceLevels, 'Beginner'];
          // Для самых базовых можно добавить и 'No experience'
          if (_isVeryBasicExercise(ex) && !updatedLevels.contains('No experience')) {
            updatedLevels.add('No experience');
          }
          
          fixedData['experienceLevels'] = updatedLevels;
          fixedExperienceCount++;
        }
        
        return fixedData;
      }).toList();
      
      print('Исправлено $fixedLocationCount упражнений с неверной локацией');
      print('Исправлено $fixedExperienceCount упражнений с неверным уровнем опыта');
      
      // Сохраняем исправленные данные в temporaryDirectory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/fixed_exercises.json');
      await file.writeAsString(json.encode(correctedExercises));
      
      print('Исправленные данные сохранены в ${file.path}');
      return true;
    } catch (e) {
      print('Ошибка при исправлении данных упражнений: $e');
      return false;
    }
  }
  
  /// Устанавливает исправленный JSON в качестве основного
  static Future<bool> applyFixedData() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fixedFile = File('${tempDir.path}/fixed_exercises.json');
      
      if (!await fixedFile.exists()) {
        print('Файл с исправленными данными не найден');
        return false;
      }
      
      final fixedJson = await fixedFile.readAsString();
      
      // Заменяем файл через сервис
      final result = await ExerciseFileService.replaceExerciseFile(fixedJson);
      
      print('Исправленные данные применены: $result');
      return result;
    } catch (e) {
      print('Ошибка при установке исправленных данных: $e');
      return false;
    }
  }
  
  /// Определяет, является ли упражнение сложным (не для новичков)
  static bool _isAdvancedExercise(ExerciseInfo ex) {
    // Список ключевых слов, указывающих на сложные упражнения
    final advancedKeywords = [
      'planche', 'muscle up', 'handstand', 'lever', 
      'one arm', 'one-arm', 'pistol', 'ring', 'clean and jerk',
      'snatch', 'overhead', 'advanced', 'complex', 'dragon'
    ];
    
    // Проверяем название упражнения на ключевые слова
    final nameLower = ex.name.toLowerCase();
    if (advancedKeywords.any((word) => nameLower.contains(word))) {
      return true;
    }
    
    // Сложные типы оборудования
    if (ex.equipment.toLowerCase().contains('olympic')) {
      return true;
    }
    
    return false;
  }
  
  /// Определяет, является ли упражнение базовым (подходит для новичков)
  static bool _isBasicExercise(ExerciseInfo ex) {
    // Список ключевых слов для базовых упражнений
    final basicKeywords = [
      'basic', 'simple', 'beginner', 'assisted', 'modified',
      'knee push', 'wall', 'supported', 'machine', 'guide'
    ];
    
    // Проверяем название
    final nameLower = ex.name.toLowerCase();
    if (basicKeywords.any((word) => nameLower.contains(word))) {
      return true;
    }
    
    // Базовые группы упражнений
    if (ex.bodyPart.toLowerCase() == 'cardio') {
      return true;
    }
    
    return false;
  }
  
  /// Очень базовые упражнения (подходят даже без опыта)
  static bool _isVeryBasicExercise(ExerciseInfo ex) {
    final veryBasicKeywords = [
      'walk', 'assisted', 'basic', 'modified', 'knee', 'wall'
    ];
    
    final nameLower = ex.name.toLowerCase();
    return veryBasicKeywords.any((word) => nameLower.contains(word));
  }
} 