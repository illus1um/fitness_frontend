import 'package:flutter/material.dart';
import 'package:fitness_app/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fitness_app/services/api_service.dart';

class AIAnalyticsScreen extends StatefulWidget {
  @override
  _AIAnalyticsScreenState createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen> {
  static final Color goldColor = Color.fromARGB(255, 199, 169, 127);
  final AIService _aiService = AIService();
  bool _isLoading = false;
  bool _hasAnalysis = false;
  String _analysisResult = "";
  Map<String, dynamic> _userData = {};
  static const String analyticsKey = 'ai_analytics_data';
  static const String lastAnalysisDateKey = 'last_analysis_date';

  @override
  void initState() {
    super.initState();
    _loadSavedAnalytics();
  }

  // Загрузка сохраненного анализа из SharedPreferences
  Future<void> _loadSavedAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAnalytics = prefs.getString(analyticsKey);
      
      if (savedAnalytics != null && savedAnalytics.isNotEmpty) {
        setState(() {
          _analysisResult = savedAnalytics;
          _hasAnalysis = true;
        });
      }
    } catch (e) {
      print('Error loading saved analytics: $e');
    }
  }

  // Получение данных пользователя для анализа
  Future<bool> _gatherUserData() async {
    setState(() {
      _userData = {};
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      bool hasData = false;
      
      // 1. Получаем профиль пользователя
      final apiUserProfile = await ApiService.getUserProfile();
      if (apiUserProfile != null) {
        _userData['profile'] = apiUserProfile;
        await prefs.setString('user_profile', jsonEncode(apiUserProfile));
        hasData = true;
      } else {
        // Пробуем использовать сохраненный профиль
        final savedProfile = prefs.getString('user_profile');
        if (savedProfile != null) {
          _userData['profile'] = jsonDecode(savedProfile);
          hasData = true;
        }
      }
      
      // 2. Получаем историю тренировок
      try {
        final progressEntries = await ApiService.getProgress();
        if (progressEntries.isNotEmpty) {
          _userData['workouts'] = progressEntries.map((entry) => entry.toJson()).toList();
          await prefs.setString('workout_history', jsonEncode(_userData['workouts']));
          hasData = true;
        } else {
          // Пробуем использовать сохраненную историю
          final savedWorkouts = prefs.getString('workout_history');
          if (savedWorkouts != null) {
            _userData['workouts'] = jsonDecode(savedWorkouts);
            hasData = true;
          }
        }
      } catch (e) {
        print('Error fetching workout history: $e');
        // Пробуем использовать сохраненную историю
        final savedWorkouts = prefs.getString('workout_history');
        if (savedWorkouts != null) {
          _userData['workouts'] = jsonDecode(savedWorkouts);
          hasData = true;
        }
      }
      
      // 3. Получаем данные о потреблении воды
      try {
        final waterDataList = [];
        final now = DateTime.now();
        
        for (int i = 0; i < 3; i++) {
          final date = now.subtract(Duration(days: i));
          final dateString = DateFormat('yyyy-MM-dd').format(date);
          final dailyIntake = await ApiService.getDailyWaterIntake(dateString);
          
          if (dailyIntake != null) {
            waterDataList.add({
              'date': dateString,
              'totalAmount': dailyIntake.totalAmount,
              'records': dailyIntake.records.map((r) => {
                'amount': r.amount,
                'timestamp': r.timestamp.toIso8601String(),
              }).toList(),
            });
          }
        }
        
        if (waterDataList.isNotEmpty) {
          _userData['water'] = waterDataList;
          await prefs.setString('water_tracking', jsonEncode(waterDataList));
          hasData = true;
        } else {
          // Пробуем использовать сохраненные данные о воде
          final savedWater = prefs.getString('water_tracking');
          if (savedWater != null) {
            _userData['water'] = jsonDecode(savedWater);
            hasData = true;
          }
        }
      } catch (e) {
        print('Error fetching water data: $e');
        // Пробуем использовать сохраненные данные о воде
        final savedWater = prefs.getString('water_tracking');
        if (savedWater != null) {
          _userData['water'] = jsonDecode(savedWater);
          hasData = true;
        }
      }
      
      return hasData;
    } catch (e) {
      print('Error gathering user data: $e');
      return false;
    }
  }

  // Создание запроса для AI
  String _createAnalyticsPrompt() {
    String prompt = "As a fitness AI assistant, analyze this user's data and provide personalized insights and recommendations. Format your response with clear sections:\n\n";
    
    if (_userData.containsKey('profile')) {
      prompt += "USER PROFILE: ${jsonEncode(_userData['profile'])}\n\n";
    }
    
    if (_userData.containsKey('workouts')) {
      prompt += "WORKOUT HISTORY: ${jsonEncode(_userData['workouts'])}\n\n";
    }
    
    if (_userData.containsKey('water')) {
      prompt += "WATER INTAKE (last 7 days): ${jsonEncode(_userData['water'])}\n\n";
    }
    
    prompt += "Please provide a concise analysis including:\n";
    prompt += "1. PROGRESS ASSESSMENT: Evaluate workout consistency, intensity progress, and achievements.\n";
    prompt += "2. WORKOUT ANALYSIS: Analyze exercise balance (upper/lower body, cardio/strength), suggestions to improve workout routine.\n";
    prompt += "3. HYDRATION STATUS: Evaluate water intake patterns, consistency, and if daily targets are being met.\n";
    prompt += "4. PERSONALIZED RECOMMENDATIONS: Give 3-5 specific, actionable tips based on all the data.\n";
    prompt += "5. WEEKLY GOALS: Suggest 2-3 realistic goals for the coming week.\n\n";
    
    prompt += "Keep your analysis concise, practical, and motivational. Focus on patterns rather than individual data points.";
    
    return prompt;
  }

  // Генерация анализа
  Future<void> _generateAnalysis() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 1. Сначала собираем данные
      final hasData = await _gatherUserData();
      
      if (!hasData) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data available for analysis. Please fill in your profile, workouts, and water intake.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // 2. Создаем запрос и получаем ответ от AI
      final prompt = _createAnalyticsPrompt();
      final analysis = await _aiService.getResponse(prompt);
      
      // 3. Сохраняем результат
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(analyticsKey, analysis);
      await prefs.setString(lastAnalysisDateKey, DateTime.now().toIso8601String());
      
      // 4. Обновляем UI
      setState(() {
        _analysisResult = analysis;
        _hasAnalysis = true;
        _isLoading = false;
      });
      
      // 5. Уведомляем пользователя
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis created successfully'),
          backgroundColor: goldColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating analysis: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Форматирование текста от AI
  String _formatAnalysis(String analysis) {
    // Удаляем маркеры форматирования
    analysis = analysis.replaceAll('**', '');
    analysis = analysis.replaceAll('*', '');
    analysis = analysis.replaceAll('__', '');
    
    // Преобразуем заголовки в формат ЗАГОЛОВОК: для лучшего разделения
    final sectionTitles = ['PROGRESS ASSESSMENT', 'WORKOUT ANALYSIS', 'HYDRATION STATUS', 
                          'RECOMMENDATIONS', 'WEEKLY GOALS'];
    
    for (final title in sectionTitles) {
      // Преобразуем разные форматы заголовков в стандартный
      final patterns = [
        RegExp(r'\d+\.\s*' + title + r'\s*:'), // 1. TITLE:
        RegExp(title + r'\s*:'), // TITLE:
        RegExp(r'"' + title + r'"' + r'\s*:'), // "TITLE":
        RegExp(title + r'\s*-'), // TITLE -
      ];
      
      for (final pattern in patterns) {
        analysis = analysis.replaceAll(pattern, '\n\n$title:');
      }
      
      // Если заголовка нет, но есть нумерованный пункт, предполагаем что это секция
      if (!analysis.contains('$title:')) {
        final numberPattern = RegExp(r'(\d+)\.\s*(.*?)\s*:');
        final matches = numberPattern.allMatches(analysis);
        
        for (final match in matches) {
          if (match.group(2)!.toUpperCase().contains(title)) {
            final fullMatch = match.group(0)!;
            analysis = analysis.replaceAll(fullMatch, '\n\n$title:');
          }
        }
      }
    }
    
    // Убираем лишние пробелы
    analysis = analysis.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return analysis;
  }

  // Получение времени последнего обновления
  Future<String> _getLastUpdatedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDateStr = prefs.getString(lastAnalysisDateKey);
      
      if (lastDateStr != null && lastDateStr.isNotEmpty) {
        final lastDate = DateTime.parse(lastDateStr);
        return DateFormat('MM/dd/yyyy at HH:mm').format(lastDate);
      }
    } catch (e) {
      // Игнорируем ошибки
    }
    
    return "just now";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Color(0xFF181A20) : Color(0xFFF6F6F6);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'AI Analytics', 
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? Color(0xFF23242B) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        actions: [
          if (_hasAnalysis) // Показываем кнопку обновления, только если есть анализ
            IconButton(
              icon: Icon(Icons.refresh, color: goldColor),
              onPressed: _isLoading ? null : _generateAnalysis,
              tooltip: 'Refresh analysis',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Analyzing your data...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : !_hasAnalysis 
            ? _buildFirstTimeView(isDarkMode)
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalyticsHeader(isDarkMode),
                    SizedBox(height: 16),
                    _buildAnalyticsContent(isDarkMode),
                  ],
                ),
              ),
      ),
    );
  }

  // Вид для первого входа (без анализа)
  Widget _buildFirstTimeView(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 60,
                color: goldColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Workout Analytics',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'AI will analyze your profile, workouts, and water intake data to provide personalized recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                height: 1.5,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateAnalysis,
              icon: Icon(Icons.analytics),
              label: Text('Analyze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Заголовок для блока с аналитикой
  Widget _buildAnalyticsHeader(bool isDarkMode) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Color(0xFF23242B) : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.insights,
                    color: goldColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Analysis',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      FutureBuilder<String>(
                        future: _getLastUpdatedTime(),
                        builder: (context, snapshot) {
                          return Text(
                            'Last updated: ${snapshot.data ?? 'just now'}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Содержимое аналитики
  Widget _buildAnalyticsContent(bool isDarkMode) {
    // Форматируем текст анализа для улучшения отображения
    final formattedAnalysis = _formatAnalysis(_analysisResult);
    
    if (formattedAnalysis.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No data available for analysis. Update to get information.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Ищем секции с помощью регулярных выражений
    final RegExp sectionRegex = RegExp(r'([A-Z\s]+):\s*(.*?)(?=\n\n[A-Z\s]+:|$)', dotAll: true);
    final matches = sectionRegex.allMatches(formattedAnalysis);
    
    final List<Widget> sections = [];
    
    if (matches.isEmpty) {
      // Если секции не найдены, отображаем весь текст как одну секцию
      sections.add(_buildAnalysisSection('AI Analysis', formattedAnalysis, isDarkMode));
    } else {
      // Создаем секции из найденных совпадений
      for (var match in matches) {
        if (match.groupCount >= 2) {
          final title = match.group(1)?.trim() ?? 'Section';
          final content = match.group(2)?.trim() ?? '';
          
          if (content.isNotEmpty) {
            sections.add(_buildAnalysisSection(title, content, isDarkMode));
          }
        }
      }
    }
    
    return Column(
      children: sections,
    );
  }

  // Секция для отдельного блока аналитики
  Widget _buildAnalysisSection(String title, String content, bool isDarkMode) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Color(0xFF23242B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.15),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  color: goldColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Получение иконки для секции по заголовку
  IconData _getSectionIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    
    if (lowercaseTitle.contains('progress') || lowercaseTitle.contains('assessment')) {
      return Icons.trending_up;
    } else if (lowercaseTitle.contains('workout') || lowercaseTitle.contains('exercise')) {
      return Icons.fitness_center;
    } else if (lowercaseTitle.contains('hydration') || lowercaseTitle.contains('water')) {
      return Icons.water_drop;
    } else if (lowercaseTitle.contains('recommendation') || lowercaseTitle.contains('tip')) {
      return Icons.lightbulb;
    } else if (lowercaseTitle.contains('goal')) {
      return Icons.flag;
    } else {
      return Icons.analytics;
    }
  }
} 