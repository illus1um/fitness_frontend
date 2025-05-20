// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/day_info.dart';
import '../../models/exercise_info.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final DayInfo day;
  final List<Map<String, dynamic>> completedExercises;
  final DateTime completionDate;
  final VoidCallback onFinish;

  const WorkoutSummaryScreen({
    required this.day,
    required this.completedExercises,
    required this.completionDate, 
    required this.onFinish,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFC7A97F);
    
    // Подсчитываем общую статистику
    int totalSets = 0;
    int totalCompleted = 0;
    
    for (final ex in completedExercises) {
      final exercise = ex['exercise'] as ExerciseInfo;
      final completed = ex['sets_completed'] as int;
      totalSets += exercise.sets;
      totalCompleted += completed;
    }
    
    // Вычисляем процент выполнения
    final completionRate = totalSets > 0 ? totalCompleted / totalSets : 0.0;
    
    // Форматируем дату
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final formattedDate = dateFormatter.format(completionDate);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false, // Отключаем кнопку назад
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с поздравлением и красивым бейджем
                  Center(
                    child: Column(
                      children: [
                        // Trophy badge with animated shimmer
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                goldColor.withOpacity(0.7),
                                goldColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Congratulation text with beautiful styling
                        Text(
                          'Great Job!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Day completion info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF3A3225) : goldColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Day ${day.dayIndex} completed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Date
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Overall progress circle with percentage
                  Center(
                    child: CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 15,
                      percent: completionRate.clamp(0.0, 1.0),
                      animation: true,
                      animationDuration: 1500,
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: goldColor,
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(completionRate * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Общая статистика в красивых карточках
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: isDarkMode ? 0 : 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context, 
                          'Exercises', 
                          '${completedExercises.length}',
                          Icons.fitness_center,
                          isDarkMode,
                          goldColor,
                        ),
                        _buildDivider(isDarkMode),
                        _buildStatItem(
                          context, 
                          'Sets Done', 
                          '$totalCompleted/$totalSets',
                          Icons.check_circle_outline,
                          isDarkMode,
                          goldColor,
                        ),
                        _buildDivider(isDarkMode),
                        _buildStatItem(
                          context, 
                          'Focus', 
                          day.part,
                          Icons.adjust,
                          isDarkMode,
                          goldColor,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Заголовок секции упражнений с иконкой
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF3A3225) : goldColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.format_list_bulleted,
                          color: goldColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Completed Exercises',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Список упражнений с улучшенным дизайном
                  ...completedExercises.map((ex) {
                    final exercise = ex['exercise'] as ExerciseInfo;
                    final completed = ex['sets_completed'] as int;
                    final completionPercentage = exercise.sets > 0 ? completed / exercise.sets : 0.0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: isDarkMode ? 0 : 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Изображение упражнения в контейнере с тенью
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  exercise.assetPreviewPath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: isDarkMode ? const Color(0xFF262626) : Colors.grey[200],
                                    child: Icon(
                                      Icons.fitness_center,
                                      size: 30,
                                      color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Информация об упражнении с мини-прогрессом
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDarkMode 
                                              ? const Color(0xFF3A3225)
                                              : goldColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          exercise.target,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: goldColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDarkMode 
                                              ? const Color(0xFF3A3225)
                                              : goldColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          exercise.equipment,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: goldColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: completionPercentage.clamp(0.0, 1.0),
                                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        completed >= exercise.sets ? Colors.green : goldColor,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 10),
                            
                            // Счетчик выполненных сетов
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDarkMode 
                                    ? (completed >= exercise.sets ? Colors.green.withOpacity(0.2) : const Color(0xFF3A3225))
                                    : (completed >= exercise.sets ? Colors.green.withOpacity(0.1) : goldColor.withOpacity(0.15)),
                                border: Border.all(
                                  color: completed >= exercise.sets ? Colors.green : goldColor,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$completed/${exercise.sets}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: completed >= exercise.sets ? Colors.green : goldColor,
                                    ),
                                  ),
                                  Text(
                                    'sets',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          // Кнопка "Готово" с градиентом
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    goldColor,
                    const Color(0xFFD4B995),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    // Вызываем коллбэк для завершения тренировки
                    onFinish();
                    
                    // Дополнительно убеждаемся, что вернулись на главный экран
                    // даже если коллбэк onFinish не содержит правильной логики навигации
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    });
                  },
                  child: const Center(
                    child: Text(
                      'COMPLETE WORKOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
    bool isDarkMode,
    Color goldColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF3A3225) : goldColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: goldColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 40,
      width: 1,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
    );
  }
} 