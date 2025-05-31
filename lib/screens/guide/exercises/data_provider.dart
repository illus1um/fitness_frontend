import 'dart:convert';
import 'package:flutter/services.dart';

class DataProvider {
  static Future<Map<String, List<Map<String, dynamic>>>> loadExercises() async {
    String jsonString = await rootBundle.loadString('assets/exercises.json');
    List<dynamic> jsonList = json.decode(jsonString);

    Map<String, List<Map<String, dynamic>>> groupedExercises = {};

    for (var exercise in jsonList) {
      String muscleGroup = exercise["bodyPart"];
      String name = exercise["name"];
      String target = exercise["target"] ?? "Unknown";
      String equipment = (exercise["equipment"] ?? "Bodyweight").toLowerCase().replaceAll(" ", "");
      
      // Вместо пути к гифке в ассетах будем хранить только имя файла
      String gifFileName = exercise["gifUrl"].split('/').last;
      if (!gifFileName.toLowerCase().endsWith('.gif')) {
        gifFileName = "$gifFileName.gif";
      }
      
      List<String> instructions = (exercise["instructions"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (!groupedExercises.containsKey(muscleGroup)) {
        groupedExercises[muscleGroup] = [];
      }
      groupedExercises[muscleGroup]!.add({
        "name": name,
        "target": target,
        "equipment": equipment,
        "gifFileName": gifFileName, // Используем имя файла вместо пути
        "instructions": instructions,
      });
    }

    return groupedExercises;
  }
}
