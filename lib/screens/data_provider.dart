import 'dart:convert';
import 'package:flutter/services.dart';

class DataProvider {
  static Future<Map<String, List<Map<String, dynamic>>>> loadExercises() async {
    // Читаем JSON-файл из assets
    String jsonString = await rootBundle.loadString('assets/exercises.json');
    List<dynamic> jsonList = json.decode(jsonString);

    // Группируем упражнения по мышечным группам
    Map<String, List<Map<String, dynamic>>> groupedExercises = {};

    for (var exercise in jsonList) {
      String muscleGroup = exercise["bodyPart"];
      String name = exercise["name"];
      String target = exercise["target"] ?? "Unknown"; // Основная целевая мышца
      String gif = "assets/gifs/${exercise["gifUrl"].split('/').last}.gif";
      List<String> instructions = (exercise["instructions"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          []; // Обрабатываем `instructions`, если они `null`

      // Добавляем в соответствующую группу
      if (!groupedExercises.containsKey(muscleGroup)) {
        groupedExercises[muscleGroup] = [];
      }
      groupedExercises[muscleGroup]!.add({
        "name": name,
        "target": target,
        "gif": gif,
        "instructions": instructions,
      });
    }

    return groupedExercises;
  }
}
