import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/models/water_intake.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final String username;
  const HistoryScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, double> history = {};
  double dailyWaterTarget = 2.0;
  String _waterUnit = 'L';
  static const double _litersToFlOz = 33.814;
  bool _isLoading = true;
  
  // Золотой акцентный цвет, соответствующий теме приложения
  final Color goldAccent = Color(0xFFC7A97F);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    _waterUnit = prefs.getString('water_unit') ?? 'L';
    await _loadHistory();
    await _loadUserProfile();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadHistory() async {
    try {
      final historyList = await ApiService.getWaterHistory(limit: 30);
      
      if (historyList.isNotEmpty) {
        Map<String, double> historyMap = {};
        for (var entry in historyList) {
          historyMap[entry.date] = entry.amount;
        }
        
        setState(() {
          history = historyMap;
        });
      }
    } catch (e) {
      print('Error loading water history: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load water history. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      final weight = (profile['weight'] ?? 70.0) as double;
      final age = (profile['age'] ?? 25) as int;
      final isMale = (profile['gender'] ?? true) as bool;
      final base = isMale ? weight * 0.035 : weight * 0.031;
      final factor = age > 55 ? 0.90 : (age > 30 ? 0.95 : 1.0);
      setState(() {
        dailyWaterTarget = double.parse((base * factor).toStringAsFixed(2));
      });
    }
  }

  double _convertToDisplay(double liters) {
    return _waterUnit == 'fl oz' ? liters * _litersToFlOz : liters;
  }

  String get _unitLabel => _waterUnit;

  Color _intakeColor(double intake, ThemeData theme, bool isDarkMode) {
    if (intake >= dailyWaterTarget) {
      return goldAccent;
    } else if (intake >= dailyWaterTarget * 0.8) {
      return Color(0xFF7FB77E); // Зеленый
    } else if (intake >= dailyWaterTarget * 0.5) {
      return Color(0xFFFFB26B); // Оранжевый
    } else {
      return Color(0xFFFF7B7B); // Красный
    }
  }
  
  // Форматирование даты для более читаемого вывода
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(date);
    } catch (_) {
      // Если формат даты не распознан, возвращаем исходную строку
      return dateStr;
    }
  }
  
  // Рассчитываем статистику
  Map<String, dynamic> _calculateStats() {
    if (history.isEmpty) {
      return {
        'average': 0.0,
        'best': 0.0,
        'goalReached': 0,
        'streak': 0,
      };
    }
    
    double total = 0.0;
    double best = 0.0;
    int goalReached = 0;
    
    for (var value in history.values) {
      total += value;
      if (value > best) best = value;
      if (value >= dailyWaterTarget) goalReached++;
    }
    
    // Вычисляем текущую серию дней с достигнутой целью
    int streak = 0;
    final sortedDates = history.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Проверяем сегодняшний день
    if (sortedDates.isNotEmpty) {
      DateTime currentDate = DateTime.now();
      String formattedToday = DateFormat('yyyy-MM-dd').format(currentDate);
      
      // Если сегодня в истории и цель достигнута
      if (sortedDates.contains(formattedToday) && 
          history[formattedToday]! >= dailyWaterTarget) {
        streak = 1;
        
        // Проверяем предыдущие дни
        currentDate = currentDate.subtract(Duration(days: 1));
        while (true) {
          String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
          if (history.containsKey(dateStr) && history[dateStr]! >= dailyWaterTarget) {
            streak++;
            currentDate = currentDate.subtract(Duration(days: 1));
          } else {
            break;
          }
        }
      }
    }
    
    return {
      'average': history.isEmpty ? 0.0 : total / history.length,
      'best': best,
      'goalReached': goalReached,
      'streak': streak,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Получаем статистику
    final stats = _calculateStats();
    
    // Сортируем даты в порядке убывания (сначала новые)
    final sortedDates = history.keys.toList()..sort((a, b) => b.compareTo(a));
    
    final weekDays = _getLastSevenDays();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Water Intake History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
            ),
          )
        : RefreshIndicator(
            color: goldAccent,
            onRefresh: _loadAllData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статистика
                  _buildStatisticsSection(stats, isDarkMode, cardColor, textColor),
                  
                  SizedBox(height: 24),
                  
                  // Недельный график
                  _buildWeeklyChart(weekDays, isDarkMode, cardColor, textColor),
                  
                  SizedBox(height: 24),
                  
                  // Заголовок истории
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Daily Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // История по дням
                  sortedDates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.water_drop_outlined,
                                size: 70,
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No history yet.\nStart tracking your water intake!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final intakeLiters = history[date]!;
                          final displayIntake = _convertToDisplay(intakeLiters);
                          final progress = (intakeLiters / dailyWaterTarget).clamp(0.0, 1.0);
                          final color = _intakeColor(intakeLiters, theme, isDarkMode);
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: cardColor,
                              elevation: 2,
                              shadowColor: isDarkMode 
                                ? Colors.black.withOpacity(0.4) 
                                : Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDarkMode 
                                              ? color.withOpacity(0.2) 
                                              : color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            intakeLiters >= dailyWaterTarget 
                                              ? Icons.emoji_events 
                                              : Icons.water_drop,
                                            color: color,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatDate(date),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                intakeLiters >= dailyWaterTarget
                                                  ? 'Goal reached!'
                                                  : '${(progress * 100).toInt()}% of daily goal',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${displayIntake.toStringAsFixed(1)} $_unitLabel',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildStatisticsSection(Map<String, dynamic> stats, bool isDarkMode, Color cardColor, Color textColor) {
    final avgIntake = _convertToDisplay(stats['average']);
    final bestIntake = _convertToDisplay(stats['best']);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: cardColor,
        elevation: 3,
        shadowColor: isDarkMode 
          ? Colors.black.withOpacity(0.4) 
          : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: goldAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Your Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Average',
                      value: '${avgIntake.toStringAsFixed(1)} $_unitLabel',
                      icon: Icons.show_chart,
                      iconColor: Color(0xFF7FB77E),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Best',
                      value: '${bestIntake.toStringAsFixed(1)} $_unitLabel',
                      icon: Icons.emoji_events,
                      iconColor: goldAccent,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Goals Reached',
                      value: '${stats['goalReached']} days',
                      icon: Icons.check_circle,
                      iconColor: Color(0xFF7FB77E),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Current Streak',
                      value: '${stats['streak']} days',
                      icon: Icons.local_fire_department,
                      iconColor: Color(0xFFFFB26B),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _getLastSevenDays() {
    final result = <Map<String, dynamic>>[];
    final today = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final weekdayStr = DateFormat('E').format(date).substring(0, 1);
      
      // Находим запись для этого дня или ставим 0
      final intake = history.containsKey(dateStr) ? history[dateStr]! : 0.0;
      final progress = intake / dailyWaterTarget;
      
      result.add({
        'date': dateStr,
        'weekday': weekdayStr,
        'intake': intake,
        'progress': progress,
      });
    }
    
    return result;
  }
  
  Widget _buildWeeklyChart(List<Map<String, dynamic>> weekData, bool isDarkMode, Color cardColor, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: cardColor,
        elevation: 3,
        shadowColor: isDarkMode 
          ? Colors.black.withOpacity(0.4) 
          : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: goldAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weekData.map((day) {
                    // Цвет полосы графика зависит от прогресса
                    final Color barColor = day['progress'] >= 1.0
                        ? goldAccent
                        : day['progress'] >= 0.8
                            ? Color(0xFF7FB77E)
                            : day['progress'] >= 0.5
                                ? Color(0xFFFFB26B)
                                : day['progress'] > 0
                                    ? Color(0xFFFF7B7B)
                                    : isDarkMode
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!;
                    
                    // Максимальная высота полосы - 120, минимальная - 5 (если intake > 0)
                    final num barHeight = day['intake'] > 0 
                        ? 5 + (day['progress'] * 115).clamp(0.0, 115.0)
                        : 0;
                    
                    final isToday = day['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now());
                    
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight.toDouble(),
                            width: 30,
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(day['intake'] > 0 ? 1.0 : 0.3),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: day['intake'] > 0 ? [
                                BoxShadow(
                                  color: barColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ] : null,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            decoration: isToday ? BoxDecoration(
                              color: goldAccent,
                              borderRadius: BorderRadius.circular(8),
                            ) : null,
                            child: Text(
                              day['weekday'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday 
                                  ? Colors.white 
                                  : isDarkMode 
                                    ? Colors.grey[400] 
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (isToday && isDarkMode) 
                            Container(
                              width: 4,
                              height: 4,
                              margin: EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: goldAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
