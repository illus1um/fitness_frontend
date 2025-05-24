import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  final String _model = 'gemini-2.0-flash';
  
  AIService() {
    if (_apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
  }

  Future<List<String>> listAvailableModels() async {
    final url = 'https://generativelanguage.googleapis.com/v1/models?key=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
      final data = jsonDecode(response.body);
      final models = data['models'] as List<dynamic>?;
      if (models == null) return [];
      return models.map((m) => m['name'] as String).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getResponse(String prompt) async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
          }
        }),
      );

      if (response.statusCode != 200) {
        return 'API Error: ${response.statusCode} - ${response.body}';
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null) {
          final parts = content['parts'];
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'Sorry, I could not process your request.';
          }
        }
      }
      
      return 'Sorry, I could not process your request.';
    } catch (e) {
      return 'An error occurred while processing your request: $e';
    }
  }

  // Method to get exercise advice
  Future<String> getExerciseAdvice(String exerciseName) async {
    return getResponse(
      'Give a short tip for the proper execution of the exercise "$exerciseName". '
      'The answer should be short, maximum 2-3 sentences.'
    );
  }

  // Method to get water intake advice
  Future<String> getWaterAdvice(double currentIntake, double goal) async {
    return getResponse(
      'My current water intake is: $currentIntake ml. '
      'My goal is: $goal ml. '
      'Give me a brief advice about my hydration. The answer should be short, 1-2 sentences.'
    );
  }
} 