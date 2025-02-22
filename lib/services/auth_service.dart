import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// **Сохранение `access_token`, `refresh_token` и `username`**
  static Future<void> saveTokens(String accessToken, String refreshToken, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", accessToken);
    await prefs.setString("refresh_token", refreshToken);
    await prefs.setString("username", username); // ✅ Сохраняем username
  }

  /// **Получение `access_token`**
  static Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// **Получение `refresh_token`**
  static Future<String?> getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("refresh_token");
  }

  /// **Получение `username` (Добавленный метод!)**
  static Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("username"); // ✅ Получаем username
  }

  /// **Удаление данных (Logout)**
  static Future<void> removeTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("username"); // ✅ Удаляем username при выходе
  }
}
