import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // FastAPI сервер

  /// **Авторизация пользователя**
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await AuthService.saveTokens(data["access_token"], data["refresh_token"]);
        return true;
      }
      return false;
    } catch (e) {
      print("Ошибка при входе: $e");
      return false;
    }
  }

  /// **Регистрация нового пользователя**
  static Future<bool> register(String username, String email, String password, String firstName, String lastName, bool gender) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "first_name": firstName,
          "last_name": lastName,
          "gender": gender,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при регистрации: $e");
      return false;
    }
  }

  /// **Получение профиля текущего пользователя**
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshAccessToken();
        return refreshed ? getUserProfile() : null;
      }

      return null;
    } catch (e) {
      print("Ошибка при получении профиля: $e");
      return null;
    }
  }
  static Future<bool> updateProfile(double weight, double height, int age) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/update-profile'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "weight": weight,
          "height": height,
          "age": age,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при обновлении профиля: $e");
      return false;
    }
  }
  /// **Обновление `access_token` с помощью `refresh_token`**
  static Future<bool> refreshAccessToken() async {
    try {
      String? refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await AuthService.saveTokens(data["access_token"], data["refresh_token"]);
        return true;
      }

      return false;
    } catch (e) {
      print("Ошибка при обновлении токена: $e");
      return false;
    }
  }

  /// **Выход пользователя (удаление токенов)**
  static Future<bool> logout() async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        await AuthService.removeTokens();
        return true;
      }

      return false;
    } catch (e) {
      print("Ошибка при выходе: $e");
      return false;
    }
  }

  static Future<bool> checkProfileStatus() async {
    String? token = await AuthService.getAccessToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$baseUrl/users/profile-status'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["profile_completed"];
    }
    return false;
  }

  static Future<bool> setTrainingProgram(String program) async {
  String? token = await AuthService.getAccessToken();
  if (token == null) return false;

  final response = await http.post(
    Uri.parse('$baseUrl/users/set-program'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode({"training_program": program}),
  );

  return response.statusCode == 200;
  }

  static Future<bool> setTrainingLocation(String location) async {
  String? token = await AuthService.getAccessToken();
  if (token == null) return false;

  final response = await http.post(
    Uri.parse('$baseUrl/users/set-location'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode({"training_location": location}),
  );

  return response.statusCode == 200;
  }

  static Future<bool> setTrainingExperience(String experience) async {
    String? token = await AuthService.getAccessToken();
    if (token == null) return false;

    final response = await http.post(
    Uri.parse('$baseUrl/users/set-experience'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode({"training_experience": experience}),
    );

    return response.statusCode == 200;
  } 


  /// **Запрос кода сброса пароля**
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/forgot'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при запросе кода сброса пароля: $e");
      return false;
    }
  }

  /// **Проверка кода сброса пароля**
  static Future<bool> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/verify'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email, "code": code},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при проверке кода сброса пароля: $e");
      return false;
    }
  }

  /// **Сброс пароля**
  static Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email, "code": code, "new_password": newPassword},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при сбросе пароля: $e");
      return false;
    }
  }
}
