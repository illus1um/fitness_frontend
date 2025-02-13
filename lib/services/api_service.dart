import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; 

  static Future<Map<String, dynamic>?> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "email": email, "password": password}),
    );
    return response.statusCode == 200 ? json.decode(response.body) : null;
  }

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
      return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {"Authorization": "Bearer $token"},
    );
    return response.statusCode == 200 ? json.decode(response.body) : null;
  }

  static Future<bool> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      await prefs.remove("access_token");
      return true;
    }
    return false;
  }
}
