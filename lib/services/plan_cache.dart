// lib/services/plan_cache.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_info.dart';
import '../models/progress_entry.dart';
import 'api_service.dart';

class PlanCache {
  static const _planKey = 'current_plan';
  static const _startKey = 'plan_start_date';
  static const _progressKey = 'workout_progress';

  static Future<void> savePlan(List<DayInfo> plan) async {
    final prefs = await SharedPreferences.getInstance();
    // 1. сохраняем сам план
    await prefs.setString(_planKey, json.encode(plan.map((d) => d.toJson()).toList()));
  }

  static Future<void> saveStartDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startKey, date.toIso8601String());
  }

  static Future<List<DayInfo>?> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_planKey);
    if (jsonStr == null) return null;
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded
        .map((d) => DayInfo.fromJson(Map<String, dynamic>.from(d)))
        .toList();
  }

  static Future<DateTime?> loadStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_startKey);
    return s == null ? null : DateTime.parse(s);
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
    await prefs.remove(_startKey);
    await prefs.remove(_progressKey);
    await ApiService.clearProgress();
  }

  // Saving workout progress
  static Future<void> saveProgress(List<ProgressEntry> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = json.encode(progress.map((e) => e.toJson()).toList());
    await prefs.setString(_progressKey, progressJson);
  }

  // Loading workout progress
  static Future<List<ProgressEntry>> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_progressKey);
      if (jsonStr == null) return [];
      
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded
          .map((e) => ProgressEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error loading progress: $e');
      // В случае ошибки очищаем кэшированный прогресс и возвращаем пустой список
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      return [];
    }
  }
}
