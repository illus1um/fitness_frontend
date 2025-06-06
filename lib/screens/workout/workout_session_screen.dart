import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import '../../models/exercise_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_summary_screen.dart';
import '../../services/plan_cache.dart';
import '../../services/gif_service.dart';
import '../../services/weight_recommendation_service.dart';

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
  final GlobalKey<State<StatefulWidget>> _progressCircleKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _setsCircleKey = GlobalKey();
  Map<String, int> _completedSets = {};
  bool _loading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    exIndex = widget.startIndex;
    _pageController = PageController(initialPage: exIndex);
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    
    final userData = await ApiService.getUserProfile();
    if (userData != null) {
      setState(() {
        _userData = userData;
      });
    }
    
    await _loadCurrentProgress();
    setState(() => _loading = false);
  }

  Future<void> _loadCurrentProgress() async {
    final ex = widget.day.exercises[exIndex];
    final progress = await ApiService.getDayProgress(widget.day.dayIndex);
    
    final exProgress = progress.firstWhere(
      (p) => p.exerciseId == ex.id,
      orElse: () => ProgressEntry(
        dayIndex: widget.day.dayIndex,
        exerciseId: ex.id,
        setsCompleted: 0,
        completedAt: DateTime.now(),
      ),
    );
    
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
      
      _pageController.animateToPage(
        exIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _loadCurrentProgress();
    }
  }

  void _showFinishDialog() async {
    // Получаем данные о завершенной тренировке
    final completedWorkout = await Future.wait(
      widget.day.exercises.map((ex) async {
        final progress = await _getExerciseProgress(ex.id);
        return {
          'exercise': ex,
          'sets_completed': progress,
        };
      })
    );
    
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
            if (widget.onComplete != null) {
              await widget.onComplete!();
            }
            
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
  
  Future<int> _getExerciseProgress(String exerciseId) async {
    final progress = await ApiService.getDayProgress(widget.day.dayIndex);
    
    if (widget.day.exercises[exIndex].id == exerciseId) {
      return currentSet;
    }
    
    final exerciseProgress = progress.firstWhere(
      (p) => p.exerciseId == exerciseId,
      orElse: () => ProgressEntry(
        dayIndex: widget.day.dayIndex,
        exerciseId: exerciseId,
        setsCompleted: 0,
        completedAt: DateTime.now(),
      ),
    );
    
    return exerciseProgress.setsCompleted;
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Workout'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(goldColor),
          ),
        ),
      );
    }

    final currentEx = widget.day.exercises[exIndex];
    final done = _completedSets[currentEx.id] ?? 0;
    final totalSets = currentEx.sets;
    final progress = done / totalSets;
    final phaseTotal = isResting ? currentEx.restSec : currentEx.durationSec;
    final phaseDone = phaseTotal - secondsLeft;
    final timerPercent = _pct(phaseDone, phaseTotal);

    return WillPopScope(
      onWillPop: () async {
        timer?.cancel();
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(isDarkMode, goldColor),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: GifService.loadAnimatedGif(
                              gifName: currentEx.gifFileName,
                              fit: BoxFit.contain,
                              errorWidget: Center(
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 80,
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                              Center(
                                child: Text(
                                  _capitalize(currentEx.name),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 20),
                              
                              _buildDetailRow(
                                context,
                                Icons.fitness_center,
                                "Target",
                                currentEx.target,
                                isDarkMode,
                                goldColor,
                              ),
                              SizedBox(height: 12),
                              
                              _buildDetailRow(
                                context,
                                Icons.sports_gymnastics,
                                "Equipment",
                                currentEx.equipment,
                                isDarkMode,
                                goldColor,
                              ),

                              _buildRecommendedWeight(currentEx, isDarkMode, goldColor),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProgressCircle(
                        key: _progressCircleKey,
                        pct: timerPercent,
                        value: '$secondsLeft',
                        label: isResting ? 'REST' : 'WORKOUT',
                        color: isResting ? Colors.blue.shade400 : goldColor,
                        isDarkMode: isDarkMode,
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF23201A) : goldColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: goldColor.withOpacity(0.25)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat, color: goldColor, size: 22),
                            SizedBox(height: 2),
                            Text(
                              '${currentEx.reps} reps',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildProgressCircle(
                        key: _setsCircleKey,
                        pct: _pct(currentSet, currentEx.sets),
                        value: '$currentSet/${currentEx.sets}',
                        label: 'SETS',
                        color: goldColor,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
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
                  
                  _buildMainActionButton(
                    isResting: isResting,
                    currentSet: currentSet,
                    totalSets: currentEx.sets,
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
    final ex = widget.day.exercises[exIndex];
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

  Widget _buildRecommendedWeight(ExerciseInfo exercise, bool isDarkMode, Color goldColor) {
    if (_userData == null || !WeightRecommendationService.needsWeightRecommendation(exercise.equipment)) {
      return SizedBox.shrink();
    }

    final recommendedWeight = WeightRecommendationService.calculateRecommendedWeight(
      exercise: exercise,
      userWeight: _userData!['weight'].toDouble(),
      userHeight: _userData!['height'].toDouble(),
      userAge: _userData!['age'],
      experience: _userData!['training_experience'],
      isMale: _userData!['gender'],
    );

    if (recommendedWeight <= 0) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 12),
        _buildDetailRow(
          context,
          Icons.fitness_center,
          "Recommended Weight",
          "${recommendedWeight.toStringAsFixed(1)} kg",
          isDarkMode,
          goldColor,
        ),
      ],
    );
  }

  AppBar _buildAppBar(bool isDarkMode, Color goldColor) {
    return AppBar(
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
                    Navigator.pop(context); 
                    Navigator.pop(context); 
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
      title: Text('${exIndex + 1}/${widget.day.exercises.length} ${_capitalize(widget.day.exercises[exIndex].name)}'),
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
                child: GifService.loadAnimatedGif(
                  gifName: exercise.gifFileName,
                  fit: BoxFit.contain,
                  errorWidget: Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),

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
                  SizedBox(height: 12),
                ],
              ),
            ),

            // Instructions section
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