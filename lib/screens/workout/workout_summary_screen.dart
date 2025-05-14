import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/day_info.dart';
import '../../models/exercise_info.dart';

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
    
    // Подсчитываем общую статистику
    int totalSets = 0;
    int totalCompleted = 0;
    
    for (final ex in completedExercises) {
      final exercise = ex['exercise'] as ExerciseInfo;
      final completed = ex['sets_completed'] as int;
      totalSets += exercise.sets;
      totalCompleted += completed;
    }
    
    // Форматируем дату
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final formattedDate = dateFormatter.format(completionDate);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Summary'),
        automaticallyImplyLeading: false, // Отключаем кнопку назад
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с поздравлением
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          'Great Job!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Day ${day.dayIndex} completed',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Общая статистика
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem(context, 
                                'Exercises', 
                                '${completedExercises.length}',
                                Icons.fitness_center
                              ),
                              _buildStatItem(context, 
                                'Sets Completed', 
                                '$totalCompleted/$totalSets',
                                Icons.check_circle
                              ),
                              _buildStatItem(context, 
                                'Focus', 
                                day.part,
                                Icons.adjust
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Заголовок секции упражнений
                  Text(
                    'Exercises',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Список упражнений
                  ...completedExercises.map((ex) {
                    final exercise = ex['exercise'] as ExerciseInfo;
                    final completed = ex['sets_completed'] as int;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                exercise.assetPreviewPath,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Target: ${exercise.target}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$completed/${exercise.sets}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: completed >= exercise.sets ? Colors.green : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Sets',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
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
          
          // Кнопка "Готово"
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 