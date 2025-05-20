import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../../models/progress_entry.dart';
import '../../models/day_info.dart';
import '../models/water_intake.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show MediaType;
import 'package:cached_network_image/cached_network_image.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.76:8000"; // Backend server

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
        final data = json.decode(response.body);
        
        // Проверяем, содержит ли ответ относительный URL аватара
        if (data.containsKey('avatar_url') && data['avatar_url'] != null) {
          final rawUrl = data['avatar_url'].toString();
          print("Raw avatar_url from server: $rawUrl");
          
          // Преобразуем относительный путь в полный URL
          data['avatar_url'] = fixAvatarUrl(rawUrl);
          print("Fixed avatar_url: ${data['avatar_url']}");
        }
        
        return data;
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshAccessToken();
        return refreshed ? getUserProfile() : null;
      } else {
        print("Failed to load profile: Status ${response.statusCode}");
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

  /// POST /plan/
  static Future<bool> savePlan(List<DayInfo> plan, DateTime startDate) async {
    final token = await AuthService.getAccessToken();
    if (token == null) return false;
    
    final resp = await http.post(
      Uri.parse('$baseUrl/plan/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'start_date': startDate.toIso8601String(),
        'days': plan.map((d) => d.toJson()).toList(),
      }),
    );
    return resp.statusCode == 200;
  }

  /// GET /plan/
  static Future<Map<String, dynamic>?> getPlan() async {
    final token = await AuthService.getAccessToken();
    if (token == null) return null;
    
    final resp = await http.get(
      Uri.parse('$baseUrl/plan/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return {
        'start_date': DateTime.parse(data['start_date']),
        'days': (data['days'] as List)
            .map((d) => DayInfo.fromJson(d))
            .toList(),
      };
    }
    return null;
  }

  /// DELETE /plan/
  static Future<bool> clearPlan() async {
    final token = await AuthService.getAccessToken();
    if (token == null) return false;
    
    final resp = await http.delete(
      Uri.parse('$baseUrl/plan/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return resp.statusCode == 200;
  }

  // Water tracking endpoints
  static Future<List<WaterIntakeHistory>> getWaterHistory({int limit = 30}) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/water/history?limit=$limit'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => 
          WaterIntakeHistory.fromJson(item as Map<String, dynamic>)
        ).toList();
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshAccessToken();
        return refreshed ? await getWaterHistory(limit: limit) : [];
      }
      return [];
    } catch (e) {
      print("Error getting water history: $e");
      return [];
    }
  }

  static Future<DailyWaterIntake?> getDailyWaterIntake(String date) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/water/daily/$date'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DailyWaterIntake.fromJson(data);
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshAccessToken();
        return refreshed ? getDailyWaterIntake(date) : null;
      }
      return null;
    } catch (e) {
      print("Error getting daily water intake: $e");
      return null;
    }
  }

  static Future<bool> addWaterIntake(double amount, {List<WaterIntakeRecord>? records}) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final Map<String, dynamic> body = {
        "amount": amount,
      };

      if (records != null && records.isNotEmpty) {
        body["records"] = records.map((r) => r.toJson()).toList();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/water/add'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding water intake: $e");
      return false;
    }
  }

  static Future<bool> addWaterRecord(WaterIntakeRecord record) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/water/records'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(record.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding water record: $e");
      return false;
    }
  }

  static Future<bool> deleteWaterRecord(int recordId) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/water/records/$recordId'),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting water record: $e");
      return false;
    }
  }

  static Future<bool> deleteDailyWaterIntake(String date) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/water/daily/$date'),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting daily water intake: $e");
      return false;
    }
  }

  static Future<bool> deleteAllWaterData() async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/water/all'),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting all water data: $e");
      return false;
    }
  }
  
  // Аватар: загрузка изображения
  static Future<bool> uploadAvatar(File imageFile) async {
    try {
      String? token = await AuthService.getAccessToken();
      if (token == null) return false;
      
      // Check if file is a valid image format
      final String fileName = imageFile.path.toLowerCase();
      bool isValidFormat = false;
      String mimeType = '';
      
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        isValidFormat = true;
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        isValidFormat = true;
        mimeType = 'image/png';
      } else if (fileName.endsWith('.webp')) {
        isValidFormat = true;
        mimeType = 'image/webp';
      }
      
      if (!isValidFormat) {
        print("Error: Invalid image format. Only JPEG, PNG, and WebP are supported.");
        return false;
      }
      
      // Создаем multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload-avatar'),
      );
      
      // Добавляем заголовок авторизации
      request.headers['Authorization'] = 'Bearer $token';
      
      // Добавляем файл в запрос с явным указанием MIME типа
      final fileField = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(fileField);
      
      // Printing request details for debugging
      print("Uploading file: ${imageFile.path}");
      print("File size: ${await imageFile.length()} bytes");
      print("File MIME type: $mimeType");
      print("Endpoint: ${request.url}");
      
      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Print response body for debugging
      print("Response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Если сервер вернул URL аватара, обновляем локальный кеш
        try {
          final responseData = json.decode(response.body);
          if (responseData.containsKey('avatar_url')) {
            final avatarPath = responseData['avatar_url'] as String;
            print("Received new avatar path: $avatarPath");
            
            // Преобразуем относительный путь в полный URL
            final avatarUrl = fixAvatarUrl(avatarPath);
            print("Fixed avatar URL: $avatarUrl");
            
            // Очистка кеша для этого URL если он уже существует
            await CachedNetworkImage.evictFromCache(avatarUrl);
          }
        } catch (e) {
          print("Warning: Could not parse avatar response: $e");
        }
        return true;
      } else {
        print("Error uploading avatar: Status ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error uploading avatar: $e");
      return false;
    }
  }
  
  // Получение URL аватара из данных пользователя
  static Future<String?> getAvatarUrl() async {
    Map<String, dynamic>? userData = await getUserProfile();
    if (userData?['avatar_url'] == null || userData!['avatar_url'].toString().isEmpty) {
      return null;
    }
    
    String avatarPath = userData['avatar_url'];
    // Проверяем, является ли путь относительным и добавляем базовый URL
    if (avatarPath.startsWith('/')) {
      return '$baseUrl$avatarPath';
    }
    return avatarPath;
  }
  
  // Вспомогательный метод для преобразования относительных путей в полные URL
  static String fixAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }
    
    if (avatarPath.startsWith('/')) {
      return '$baseUrl$avatarPath';
    }
    
    if (!avatarPath.startsWith('http')) {
      return '$baseUrl/$avatarPath';
    }
    
    return avatarPath;
  }
}
