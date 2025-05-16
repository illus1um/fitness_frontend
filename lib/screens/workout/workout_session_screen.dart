// lib/screens/workout/workout_session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import '../../models/exercise_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_summary_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final DayInfo day;
  final int startIndex;
  final Function? onComplete;
  
  const WorkoutSessionScreen({
    required this.day,
    this.startIndex = 0,
    this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late int exIndex;
  int currentSet = 0;
  bool isResting = false;
  bool isPaused = false;
  Timer? timer;
  int secondsLeft = 0;
  late PageController _pageController;
  // Key for CircularPercentIndicator to preserve animation state
  final GlobalKey<State<StatefulWidget>> _progressCircleKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _setsCircleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    exIndex = widget.startIndex;
    _pageController = PageController(initialPage: exIndex);
    _loadCurrentProgress();
  }
  
  Future<void> _loadCurrentProgress() async {
    final ex = widget.day.exercises[exIndex];
    final progress = await ApiService.getDayProgress(widget.day.dayIndex);
    
    // Находим текущий прогресс для упражнения
    final exProgress = progress.firstWhere(
      (p) => p.exerciseId == ex.id,
      orElse: () => ProgressEntry(
        dayIndex: widget.day.dayIndex,
        exerciseId: ex.id,
        setsCompleted: 0,
        completedAt: DateTime.now(),
      ),
    );
    
    // Устанавливаем текущий подход
    setState(() {
      currentSet = exProgress.setsCompleted;
    });
    
    _startPhase();
  }

  void _startPhase() {
    final ex = widget.day.exercises[exIndex];
    secondsLeft = isResting ? ex.restSec : ex.durationSec;
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    if (secondsLeft <= 0) return;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 0) {
        t.cancel();
        _onPhaseComplete();
      } else if (!isPaused) {
        setState(() => secondsLeft--);
      }
    });
  }

  void _onPhaseComplete() {
    final ex = widget.day.exercises[exIndex];
    if (!isResting) {
      // завершили подход
      currentSet++;
      _saveProgress();
      if (currentSet < ex.sets) {
        setState(() => isResting = true);
        _startPhase();
      } else {
        _nextExercise();
      }
    } else {
      // завершили отдых → новый подход
      setState(() => isResting = false);
      _startPhase();
    }
  }

  Future<void> _saveProgress() async {
    final ex = widget.day.exercises[exIndex];
    
    await ApiService.saveProgress(ProgressEntry(
      dayIndex: widget.day.dayIndex,
      exerciseId: ex.id,
      setsCompleted: currentSet,
      completedAt: DateTime.now(),
    ));
  }
  
  void _skipExercise() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Skip Exercise?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Do you really want to skip the current exercise?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextExercise();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextExercise() {
    timer?.cancel();
    
    if (exIndex < widget.day.exercises.length - 1) {
      setState(() {
        exIndex++;
        currentSet = 0;
        isResting = false;
      });
      
      // Анимированный переход к следующему упражнению
      _pageController.animateToPage(
        exIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _loadCurrentProgress();
    } else {
      _showFinishDialog();
    }
  }
  
  void _previousExercise() {
    if (exIndex > 0) {
      timer?.cancel();
      setState(() {
        exIndex--;
      });
      
      // Анимированный переход к предыдущему упражнению
      _pageController.animateToPage(
        exIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _loadCurrentProgress();
    }
  }

  void _showFinishDialog() {
    // Получаем данные о завершенной тренировке
    final completedWorkout = widget.day.exercises.map((ex) {
      final progress = _getExerciseProgress(ex.id);
      return {
        'exercise': ex,
        'sets_completed': progress,
      };
    }).toList();
    
    // Дата завершения
    final completionDate = DateTime.now();
    
    // Переходим на экран итогов
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          day: widget.day,
          completedExercises: completedWorkout,
          completionDate: completionDate,
          onFinish: () async {
            // Вызываем коллбэк завершения
            if (widget.onComplete != null) {
              await widget.onComplete!();
            }
            
            // Закрываем все экраны и возвращаемся на главную страницу
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
  
  // Получаем прогресс по конкретному упражнению
  int _getExerciseProgress(String exerciseId) {
    // Находим упражнение по ID
    final exercise = widget.day.exercises.firstWhere(
      (e) => e.id == exerciseId, 
      orElse: () => widget.day.exercises[0]
    );
    
    // Если это текущее упражнение, возвращаем текущий прогресс
    if (widget.day.exercises[exIndex].id == exerciseId) {
      return currentSet;
    }
    
    // Для завершенных упражнений возвращаем полное количество сетов
    // Для еще не начатых - возвращаем 0
    final index = widget.day.exercises.indexOf(exercise);
    if (index < exIndex) {
      return exercise.sets; // Предыдущие упражнения считаются выполненными
    } else {
      return 0; // Будущие упражнения еще не начаты
    }
  }

  void _showInstructionsScreen() {
    final ex = widget.day.exercises[exIndex];
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ExerciseInstructionsScreen(exercise: ex),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  double _pct(int num, int den) => den > 0 ? (num / den).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final ex = widget.day.exercises[exIndex];
    final phaseTotal = isResting ? ex.restSec : ex.durationSec;
    final phaseDone = phaseTotal - secondsLeft;
    final timerPercent = _pct(phaseDone, phaseTotal);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'End Workout?',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Your progress will be saved, but the workout will not be completed.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрываем диалог
                      Navigator.pop(context); // Возвращаемся на экран дня
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Exit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text('${exIndex + 1}/${widget.day.exercises.length} ${ex.name}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Color(0xFF3A3225)
                  : goldColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: goldColor,
              ),
              onPressed: () {
                setState(() => isPaused = !isPaused);
                if (!isPaused) _startTimer();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.day.exercises.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                if (index != exIndex) {
                  setState(() {
                    exIndex = index;
                  });
                  _loadCurrentProgress();
                }
              },
              itemBuilder: (context, index) {
                final currentEx = widget.day.exercises[index];
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Exercise image and info button with improved styling
                      Container(
                        height: 280,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                        child: Stack(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 280,
                                width: double.infinity,
                                color: isDarkMode ? Color(0xFF262626) : Colors.grey.shade100,
                                child: Image.asset(
                                  currentEx.assetGifPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.fitness_center,
                                      size: 80,
                                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Info button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: InkWell(
                                onTap: () => _showInstructionsScreen(),
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Color(0xFF3A3225)
                                        : goldColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: goldColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Exercise details with improved styling
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Exercise name
                            Center(
                              child: Text(
                                currentEx.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Target muscle
                            _buildDetailRow(
                              context,
                              Icons.fitness_center,
                              "Target",
                              currentEx.target,
                              isDarkMode,
                              goldColor,
                            ),
                            SizedBox(height: 12),
                            
                            // Equipment
                            _buildDetailRow(
                              context,
                              Icons.sports_gymnastics,
                              "Equipment",
                              currentEx.equipment,
                              isDarkMode,
                              goldColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Enhanced progress indicators
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Timer indicator
                    _buildProgressCircle(
                      key: _progressCircleKey,
                      pct: timerPercent,
                      value: '$secondsLeft',
                      label: isResting ? 'REST' : 'WORKOUT',
                      color: isResting ? Colors.blue.shade400 : goldColor,
                      isDarkMode: isDarkMode,
                    ),
                    
                    // Sets indicator 
                    _buildProgressCircle(
                      key: _setsCircleKey,
                      pct: _pct(currentSet, ex.sets),
                      value: '$currentSet/${ex.sets}',
                      label: 'SETS',
                      color: goldColor,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Control buttons
                Row(
                  children: [
                    if (exIndex > 0)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildControlButton(
                            label: 'Previous',
                            icon: Icons.arrow_back,
                            isDarkMode: isDarkMode,
                            goldColor: goldColor,
                            isOutlined: true,
                            onPressed: _previousExercise,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: exIndex > 0 ? 8.0 : 0),
                        child: _buildControlButton(
                          label: 'Skip',
                          icon: Icons.skip_next,
                          isDarkMode: isDarkMode,
                          goldColor: goldColor,
                          isOutlined: true,
                          onPressed: _skipExercise,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Main action button
                _buildMainActionButton(
                  isResting: isResting,
                  currentSet: currentSet,
                  totalSets: ex.sets,
                  isPaused: isPaused,
                  isDarkMode: isDarkMode,
                  goldColor: goldColor,
                  onPressed: isPaused ? null : () {
                    timer?.cancel();
                    _onPhaseComplete();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressCircle({
    Key? key,
    required double pct,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    return CircularPercentIndicator(
      key: key,
      radius: 55,
      lineWidth: 8,
      animation: true,
      animateFromLastPercent: true,
      animationDuration: 1000,
      percent: pct,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      progressColor: color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required bool isDarkMode,
    required Color goldColor,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: isOutlined ? Border.all(
          color: goldColor,
          width: 2,
        ) : null,
        boxShadow: isOutlined ? null : [
          BoxShadow(
            color: goldColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        gradient: isOutlined ? null : LinearGradient(
          colors: [
            goldColor,
            Color(0xFFD4B995),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isOutlined
                      ? goldColor
                      : Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOutlined
                        ? goldColor
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainActionButton({
    required bool isResting,
    required int currentSet,
    required int totalSets,
    required bool isPaused,
    required bool isDarkMode,
    required Color goldColor,
    required VoidCallback? onPressed,
  }) {
    String buttonText = isResting
        ? 'FINISH REST'
        : currentSet < totalSets
            ? 'COMPLETE SET'
            : 'NEXT EXERCISE';
            
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isPaused 
            ? null 
            : LinearGradient(
                colors: [
                  goldColor,
                  Color(0xFFD4B995),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isPaused 
            ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300)
            : null,
        boxShadow: isPaused 
            ? null
            : [
                BoxShadow(
                  color: goldColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Text(
              buttonText,
              style: TextStyle(
                color: isPaused 
                    ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700)
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, 
    IconData icon, 
    String label, 
    String value, 
    bool isDarkMode,
    Color goldColor
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Color(0xFF3A3225)
                : goldColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon, 
              color: goldColor,
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// New screen for exercise instructions
class ExerciseInstructionsScreen extends StatelessWidget {
  final ExerciseInfo exercise;

  const ExerciseInstructionsScreen({
    required this.exercise,
    Key? key,
  }) : super(key: key);

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(exercise.name)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with improved styling
            Container(
              height: 320,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  exercise.assetGifPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Exercise information with improved styling
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    _capitalize(exercise.name),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Target and equipment info
                  _buildInfoRow(
                    context,
                    Icons.fitness_center,
                    "Target",
                    exercise.target,
                    isDarkMode,
                    goldColor,
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.sports_gymnastics,
                    "Equipment",
                    exercise.equipment,
                    isDarkMode,
                    goldColor,
                  ),
                ],
              ),
            ),

            // Instructions section with improved styling
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Color(0xFF3A3225)
                              : goldColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.format_list_numbered,
                          color: goldColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Instructions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Instructions list
                  if (exercise.instructions.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercise.instructions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step number
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: goldColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),

                              // Instruction text
                              Expanded(
                                child: Text(
                                  exercise.instructions[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Instructions not available.",
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
    Color goldColor,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Color(0xFF3A3225)
                : goldColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: goldColor,
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}