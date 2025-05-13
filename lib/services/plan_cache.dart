// lib/services/plan_cache.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_info.dart';

class PlanCache {
  static const _planKey = 'current_plan';
  static const _startKey = 'plan_start_date';

  static Future<void> savePlan(List<DayInfo> plan) async {
    final prefs = await SharedPreferences.getInstance();
    // 1. сохраняем сам план
    await prefs.setString(_planKey, json.encode(plan.map((d) => d.toJson()).toList()));
    // 2. сохраняем дату старта (сейчас)
    await prefs.setString(_startKey, DateTime.now().toIso8601String());
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
  }
}
