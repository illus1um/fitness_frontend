import 'package:flutter/material.dart';
import '../../utils/exercise_data_fixer.dart';
import '../../services/plan_cache.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseDataFixScreen extends StatefulWidget {
  const ExerciseDataFixScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseDataFixScreen> createState() => _ExerciseDataFixScreenState();
}

class _ExerciseDataFixScreenState extends State<ExerciseDataFixScreen> {
  bool _isFixing = false;
  bool _isFixComplete = false;
  bool _isApplying = false;
  bool _isApplyComplete = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Исправление данных упражнений'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информационная карточка
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Что делает этот инструмент?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Этот инструмент автоматически исправляет метаданные упражнений:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildFeatureItem('Удаляет отметку "At home" для упражнений, требующих зала'),
                  _buildFeatureItem('Добавляет отметку "At home" к упражнениям, выполнимым дома'),
                  _buildFeatureItem('Исправляет уровни сложности для продвинутых упражнений'),
                  _buildFeatureItem('Добавляет отметку "Beginner" к базовым упражнениям'),
                  SizedBox(height: 15),
                  Text(
                    'После исправления упражнения будут правильно отфильтрованы при создании плана тренировок.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Прогресс-бар
            if (_isFixing || _isApplying)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            
            // Сообщение о завершении
            if (_isFixComplete && !_isApplying && !_isApplyComplete)
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Данные успешно исправлены! Нажмите "Применить исправления", чтобы обновить базу данных.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
            if (_isApplyComplete)
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Исправления успешно применены! Пожалуйста, перезапустите приложение, чтобы увидеть изменения.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Кнопки
            ElevatedButton(
              onPressed: (_isFixing || _isApplying || _isFixComplete) ? null : _startFixing,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'Исправить данные упражнений',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 15),
            
            ElevatedButton(
              onPressed: (_isFixing || _isApplying || !_isFixComplete || _isApplyComplete) ? null : _applyFixes,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'Применить исправления',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startFixing() async {
    setState(() {
      _isFixing = true;
      _statusMessage = 'Анализ базы данных упражнений...';
      _progress = 0.1;
    });
    
    // Имитируем прогресс
    for (double i = 0.2; i <= 0.8; i += 0.1) {
      await Future.delayed(Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _progress = i;
        _statusMessage = 'Исправление метаданных упражнений...';
      });
    }
    
    // Запускаем исправление
    final result = await ExerciseDataFixer.fixExerciseData();
    
    if (!mounted) return;
    
    setState(() {
      _isFixing = false;
      _isFixComplete = result;
      _progress = 1.0;
      _statusMessage = result 
          ? 'Данные успешно исправлены!' 
          : 'Ошибка при исправлении данных';
    });
    
    // Небольшая задержка для анимации
    await Future.delayed(Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _progress = 0;
    });
  }
  
  Future<void> _applyFixes() async {
    setState(() {
      _isApplying = true;
      _statusMessage = 'Применение исправлений...';
      _progress = 0.3;
    });
    
    // Имитируем прогресс
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;
    setState(() {
      _progress = 0.6;
    });
    
    // Применяем исправления
    final result = await ExerciseDataFixer.applyFixedData();
    
    if (result) {
      // После успешного применения исправлений очищаем кеш планов тренировок,
      // чтобы при следующем создании плана использовались новые данные
      await PlanCache.clearPlan();
      
      // Очищаем кеш на сервере также
      await ApiService.clearPlan();
      
      // Сбрасываем флаг, что у пользователя нет сгенерированного плана
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', false);
    }
    
    if (!mounted) return;
    
    setState(() {
      _isApplying = false;
      _isApplyComplete = result;
      _progress = 1.0;
      _statusMessage = result 
          ? 'Исправления успешно применены!' 
          : 'Ошибка при применении исправлений';
    });
    
    // Небольшая задержка для анимации
    await Future.delayed(Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _progress = 0;
    });
  }
} 