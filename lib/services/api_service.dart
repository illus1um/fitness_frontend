import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../../models/progress_entry.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000"; // Backend server

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await AuthService.saveTokens(data["access_token"], data["refresh_token"], username);
        return true;
      }
      return false;
    } catch (e) {
      print("Ошибка при входе: $e");
      return false;
    }
  }

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

  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/change-password'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "old_password": oldPassword,
          "new_password": newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error changing password: $e");
      return false;
    }
  }


  static Future<bool> updateProfile(double weight, double height, int age) async {
    try {
      String? token = await AuthService.getAccessToken();
      print("Token: $token");
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

  static Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/users/update-profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(updatedData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при обновлении профиля: $e");
      return false;
    }
  }

  static Future<bool> deleteAccount() async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/users/delete-account'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        await AuthService.removeTokens();
        return true;
      }

      return false;
    } catch (e) {
      print("Error deleting account: $e");
      return false;
    }
  }

  
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
        String? username = await AuthService.getUsername();
        await AuthService.saveTokens(
          data["access_token"], 
          data["refresh_token"], 
          username ?? ""
        );
        return true;
      }

      return false;
    } catch (e) {
      print("Ошибка при обновлении токена: $e");
      return false;
    }
  }

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

  static Future<List<ProgressEntry>> getProgress() async {
    final token = await AuthService.getAccessToken();
    if (token == null) return [];
    final resp = await http.get(
      Uri.parse('$baseUrl/progress/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> list = json.decode(resp.body);
      return list.map((e) => ProgressEntry.fromJson(e)).toList();
    }
    return [];
  }

  /// GET /progress/{day}
  static Future<List<ProgressEntry>> getDayProgress(int day) async {
    final token = await AuthService.getAccessToken();
    if (token == null) return [];
    final resp = await http.get(
      Uri.parse('$baseUrl/progress/$day'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> list = json.decode(resp.body);
      return list.map((e) => ProgressEntry.fromJson(e)).toList();
    }
    return [];
  }

  /// POST /progress/
  static Future<bool> saveProgress(ProgressEntry entry) async {
    final token = await AuthService.getAccessToken();
    if (token == null) return false;
    final resp = await http.post(
      Uri.parse('$baseUrl/progress/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(entry.toJson()),
    );
    return resp.statusCode == 200;
  }

  /// DELETE /progress/
  static Future<bool> clearProgress() async {
    final token = await AuthService.getAccessToken();
    if (token == null) return false;
    final resp = await http.delete(
      Uri.parse('$baseUrl/progress/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return resp.statusCode == 200;
  }

    /// Проверка доступности username
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/check-username?username=$username'));
      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при проверке username: $e");
      return false;
    }
  }

  /// Проверка доступности email
  static Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/check-email?email=$email'));
      return response.statusCode == 200;
    } catch (e) {
      print("Ошибка при проверке email: $e");
      return false;
    }
  }
}
