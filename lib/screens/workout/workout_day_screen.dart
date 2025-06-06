import 'package:flutter/material.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import '../../services/gif_service.dart';
import 'workout_session_screen.dart';

class WorkoutDayScreen extends StatefulWidget {
  final DayInfo day;
  final Function? onComplete;
  
  const WorkoutDayScreen({
    required this.day,
    this.onComplete,
    Key? key
  }) : super(key: key);

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  Map<String, int> _completedSets = {};
  bool _loading = true;

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _loadDayProgress();
    
    if (widget.day.exercises.isNotEmpty) {
      GifService.preloadExercisePreviews(widget.day.exercises);
    }
  }

  Future<void> _loadDayProgress() async {
    final list = await ApiService.getDayProgress(widget.day.dayIndex);
    setState(() {
      _completedSets = { for (var e in list) e.exerciseId: e.setsCompleted };
      _loading = false;
    });
  }
  
  bool _isDayCompleted() {
    if (widget.day.exercises.isEmpty) return false;
    
    return widget.day.exercises.every((ex) {
      final done = _completedSets[ex.id] ?? 0;
      return done >= ex.sets;
    });
  }
  
  Future<void> _onSessionComplete() async {
    await _loadDayProgress();
    
    if (_isDayCompleted() && widget.onComplete != null) {
      await widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDayCompleted = _isDayCompleted();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.day.dayIndex}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(goldColor),
              ),
            )
          : widget.day.exercises.isEmpty
              ? Center(
                  child: Text(
                    'No exercises for this workout day.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: widget.day.exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = widget.day.exercises[i];
                    final done = _completedSets[ex.id] ?? 0;
                    final isDone = done >= ex.sets;
                    return _buildExerciseCard(ex, done, isDone, i, isDarkMode, goldColor);
                  },
                ),
      bottomNavigationBar: _buildBottomBar(isDayCompleted, isDarkMode, goldColor),
    );
  }

  Widget _buildExerciseCard(
    dynamic ex, 
    int done, 
    bool isDone, 
    int index, 
    bool isDarkMode, 
    Color goldColor
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: isDarkMode ? 0 : 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(
                day: widget.day,
                startIndex: index,
                onComplete: _onSessionComplete,
              ),
            ),
          ).then((_) => _loadDayProgress()),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                    child: GifService.loadNetworkPreview(
                      gifName: ex.gifFileName,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: Icon(
                        Icons.fitness_center,
                        size: 30,
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalize(ex.name),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildProgressIndicator(done, ex.sets, isDone, isDarkMode, goldColor),
                    ],
                  ),
                ),
                
                // Completion indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? goldColor.withOpacity(0.15)
                        : (isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.5)
                            : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : Icons.chevron_right,
                    size: isDone ? 24 : 20,
                    color: isDone
                        ? goldColor
                        : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    int completed, 
    int total, 
    bool isDone, 
    bool isDarkMode, 
    Color goldColor
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$completed/$total sets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDone
                    ? goldColor
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
            Spacer(),
            Text(
              '${(completed / total * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDone
                    ? goldColor
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completed / total,
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? goldColor : goldColor.withOpacity(0.7),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDayCompleted, bool isDarkMode, Color goldColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDayCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: goldColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'All exercises completed!',
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize:
                      16,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  goldColor,
                  Color(0xFFD4B995),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSessionScreen(
                    day: widget.day,
                    onComplete: _onSessionComplete,
                  ),
                ),
              ).then((_) => _loadDayProgress()),
              child: Text(
                'START WORKOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                minimumSize: Size.fromHeight(56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
