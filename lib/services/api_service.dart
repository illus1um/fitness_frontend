import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // Локальный сервер FastAPI

  /// Регистрация нового пользователя
  static Future<Map<String, dynamic>?> register(
      String username, String email, String password, String firstName, String lastName, bool gender) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender
      }),
    );
    return response.statusCode == 200 ? json.decode(response.body) : null;
  }

  /// Авторизация (получение токенов)
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": username, "password": password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", data["access_token"]);
      await prefs.setString("refresh_token", data["refresh_token"]);
      return data;
    }
    return null;
  }

  /// Получение данных о текущем пользователе
  static Future<Map<String, dynamic>?> getUserProfile() async {
    String? token = await _getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 401) {
      bool refreshed = await refreshAccessToken();
      if (refreshed) {
        return getUserProfile(); // Повторный запрос с обновлённым токеном
      } else {
        return null;
      }
    }

    return response.statusCode == 200 ? json.decode(response.body) : null;
  }

  /// Обновление `access_token` с помощью `refresh_token`
  static Future<bool> refreshAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString("refresh_token");
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await prefs.setString("access_token", data["access_token"]);
      return true;
    }
    return false;
  }

  /// Выход пользователя (удаление токенов)
  static Future<bool> logout() async {
    String? token = await _getAccessToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      await _clearTokens();
      return true;
    }
    return false;
  }

  /// Получение токена из `SharedPreferences`
  static Future<String?> _getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// Очистка токенов (выход)
  static Future<void> _clearTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }

  static Future<bool> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"email": email},
    );
    return response.statusCode == 200;
  }

  static Future<bool> verifyResetCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-reset-code'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"email": email, "code": code},
    );
    return response.statusCode == 200;
  }

  static Future<bool> resetPassword(String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"email": email, "code": code, "new_password": newPassword},
    );
    return response.statusCode == 200;
  }
}
