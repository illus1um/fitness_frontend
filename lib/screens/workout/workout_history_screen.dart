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
  final Color goldColor = const Color(0xFFC7A97F);
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    await ExerciseDataService.initialize();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final progressEntries = await ApiService.getProgress();
      
      final Map<String, Map<int, List<ProgressEntry>>> groupedByDateAndDay = {};
      
      for (final entry in progressEntries) {
        final dateStr = DateFormat('yyyy-MM-dd').format(entry.completedAt);
        
        groupedByDateAndDay.putIfAbsent(dateStr, () => {});
        groupedByDateAndDay[dateStr]!.putIfAbsent(entry.dayIndex, () => []);
        
        groupedByDateAndDay[dateStr]![entry.dayIndex]!.add(entry);
      }
      
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF3A3225)
                  : goldColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: goldColor,
              ),
              onPressed: _loadHistory,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(goldColor),
              ),
            )
          : _groupedHistory.isEmpty
              ? _buildEmptyState(theme, isDarkMode)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView.builder(
                    itemCount: _groupedHistory.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(index, isDarkMode);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF3A3225)
                  : goldColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 60,
              color: goldColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No workout history yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your first workout to see it here',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
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
                  Navigator.of(context).pop();
                },
                child: const Center(
                  child: Text(
                    'START A WORKOUT',
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
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem(int index, bool isDarkMode) {
    final history = _groupedHistory[index];
    final date = history['date'] as DateTime;
    final dayIndex = history['day_index'] as int;
    final exercisesCount = history['exercises_count'] as int;
    final totalSets = history['total_sets'] as int;
    final entries = history['entries'] as List<ProgressEntry>;
    
    final dateFormatter = DateFormat('EEE, MMM d');
    final formattedDate = dateFormatter.format(date);
    
    final daysAgo = DateTime.now().difference(date).inDays;
    String timeAgoText;
    if (daysAgo == 0) {
      timeAgoText = 'Today';
    } else if (daysAgo == 1) {
      timeAgoText = 'Yesterday';
    } else {
      timeAgoText = '$daysAgo days ago';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(
            primary: goldColor,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF3A3225)
                      : goldColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$dayIndex',
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $dayIndex Workout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          timeAgoText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: goldColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF3A3225)
                  : goldColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalSets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: goldColor,
                  ),
                ),
                Text(
                  'sets',
                  style: TextStyle(
                    fontSize: 11,
                    color: goldColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          children: [
            SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode 
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          _buildStatBadge(
                            icon: Icons.fitness_center,
                            value: '$exercisesCount',
                            label: 'Exercise',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            icon: Icons.check_circle_outline,
                            value: '$totalSets',
                            label: 'Sets',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            icon: Icons.calendar_today,
                            value: DateFormat('MMM d').format(date),
                            label: 'Date',
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                    
                    // Список упражнений
                    const SizedBox(height: 6),
                    Text(
                      'Exercises:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    ...entries.map((entry) {
                      final exerciseName = ExerciseDataService.getExerciseName(entry.exerciseId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF3A3225)
                                    : goldColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: goldColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exerciseName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Sets: ${entry.setsCompleted}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(entry.completedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: goldColor,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 