import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveTokens(String accessToken, String refreshToken, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", accessToken);
    await prefs.setString("refresh_token", refreshToken);
    await prefs.setString("username", username);
  }

  static Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  static Future<String?> getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("refresh_token");
  }

  static Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("username");
  }

  static Future<void> removeTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("username");
  }
}
