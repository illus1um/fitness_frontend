import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import '../../services/exercise_data_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  _WorkoutHistoryScreenState createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _groupedHistory = [];
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    // Инициализируем сервис с данными об упражнениях
    await ExerciseDataService.initialize();
    // Загружаем историю
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Получаем полную историю прогресса
      final progressEntries = await ApiService.getProgress();
      
      // Группируем записи по дате и дню тренировки
      final Map<String, Map<int, List<ProgressEntry>>> groupedByDateAndDay = {};
      
      for (final entry in progressEntries) {
        // Форматируем дату для группировки по дням
        final dateStr = DateFormat('yyyy-MM-dd').format(entry.completedAt);
        
        // Создаем вложенные карты при необходимости
        groupedByDateAndDay.putIfAbsent(dateStr, () => {});
        groupedByDateAndDay[dateStr]!.putIfAbsent(entry.dayIndex, () => []);
        
        // Добавляем запись в соответствующую группу
        groupedByDateAndDay[dateStr]![entry.dayIndex]!.add(entry);
      }
      
      // Преобразуем в формат для отображения в UI
      final List<Map<String, dynamic>> result = [];
      
      groupedByDateAndDay.forEach((dateStr, dayEntries) {
        dayEntries.forEach((dayIndex, entries) {
          result.add({
            'date': DateTime.parse(dateStr),
            'day_index': dayIndex,
            'entries': entries,
            'exercises_count': entries.map((e) => e.exerciseId).toSet().length,
            'total_sets': entries.fold(0, (sum, e) => sum + e.setsCompleted),
          });
        });
      });
      
      // Сортируем по дате (сначала новые)
      result.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      setState(() {
        _groupedHistory = result;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workout history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _groupedHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No workout history yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete your first workout to see it here',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _groupedHistory.length,
                  itemBuilder: (context, index) {
                    final history = _groupedHistory[index];
                    final date = history['date'] as DateTime;
                    final dayIndex = history['day_index'] as int;
                    final exercisesCount = history['exercises_count'] as int;
                    final totalSets = history['total_sets'] as int;
                    final entries = history['entries'] as List<ProgressEntry>;
                    
                    // Форматируем дату
                    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
                    final formattedDate = dateFormatter.format(date);
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Day $dayIndex Workout',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(formattedDate),
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.fitness_center,
                            color: theme.primaryColor,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$exercisesCount exercises',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '$totalSets sets',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exercises:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...entries.map((entry) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(ExerciseDataService.getExerciseName(entry.exerciseId)),
                                    subtitle: Text('Sets completed: ${entry.setsCompleted}'),
                                    trailing: Text(
                                      DateFormat('h:mm a').format(entry.completedAt),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 