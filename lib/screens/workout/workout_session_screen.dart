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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Exercise?'),
        content: Text('Do you really want to skip the current exercise?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextExercise();
            },
            child: Text('Skip'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('End Workout?'),
                content: Text('Your progress will be saved, but the workout will not be completed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрываем диалог
                      Navigator.pop(context); // Возвращаемся на экран дня
                    },
                    child: Text('Exit'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text('${exIndex + 1}/${widget.day.exercises.length} ${ex.name}'),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() => isPaused = !isPaused);
              if (!isPaused) _startTimer();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.day.exercises.length,
              physics: const NeverScrollableScrollPhysics(), // Отключаем свайп для контроля через кнопки
              onPageChanged: (index) {
                if (index != exIndex) {
                  // Если страница изменилась через PageView (например через жест), 
                  // синхронизируем exIndex и загружаем прогресс
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
                      // Изображение упражнения и кнопка информации
                      Stack(
                        children: [
                          Container(
                            height: 250,
                            width: double.infinity,
                            child: Image.asset(
                              currentEx.assetGifPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 64),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => ExerciseInstructionsScreen(exercise: currentEx),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Exercise details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Exercise name
                            Container(
                              width: double.infinity,
                              child: Text(
                                currentEx.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // Target muscle
                            Row(
                              children: [
                                Icon(Icons.fitness_center, color: theme.iconTheme.color),
                                SizedBox(width: 8),
                                Text(
                                  "Target: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  currentEx.target,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            
                            // Equipment
                            Row(
                              children: [
                                Icon(Icons.sports_gymnastics, color: theme.iconTheme.color),
                                SizedBox(width: 8),
                                Text(
                                  "Equipment: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  currentEx.equipment,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Индикаторы прогресса
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 6,
                  percent: _pct(phaseDone, phaseTotal),
                  center: Text(
                    '$secondsLeft',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  footer: Text(isResting ? 'Rest' : 'Seconds'),
                  progressColor: isResting ? Colors.blue : Theme.of(context).primaryColor,
                ),
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 6,
                  percent: _pct(currentSet, ex.sets),
                  center: Text(
                    '$currentSet/${ex.sets}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  footer: const Text('Sets'),
                  progressColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          
          // Кнопки управления
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (exIndex > 0)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: OutlinedButton(
                            onPressed: _previousExercise,
                            child: Text('Previous'),
                            style: OutlinedButton.styleFrom(minimumSize: Size(0, 40)),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton(
                          onPressed: _skipExercise,
                          child: Text('Skip'),
                          style: OutlinedButton.styleFrom(minimumSize: Size(0, 40)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isPaused ? null : () {
                    timer?.cancel();
                    _onPhaseComplete();
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: Text(
                    isResting
                        ? 'FINISH REST'
                        : currentSet < ex.sets
                            ? 'COMPLETE SET'
                            : 'NEXT EXERCISE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    final headerStyle = theme.textTheme.titleMedium!
        .copyWith(fontWeight: FontWeight.bold);
    final numberStyle = textStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onPrimary,
    );
    final circleColor = Color.fromARGB(255, 199, 169, 127);
    final placeholderStyle = textStyle.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.disabledColor,
    );
    final nameStyle = theme.textTheme.headlineSmall!
        .copyWith(fontWeight: FontWeight.bold);
    final targetLabelStyle = textStyle;
    final targetValueStyle = textStyle.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _capitalize(exercise.name),
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GIF или изображение
            Center(
              child: Image.asset(
                exercise.assetGifPath,
                height: 350,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: theme.iconTheme.color,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Название упражнения
            Text(
              _capitalize(exercise.name),
              style: nameStyle,
            ),
            const SizedBox(height: 10),

            // Основная мышца
            Row(
              children: [
                Icon(Icons.fitness_center, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text("Target: ", style: targetLabelStyle),
                Text(
                  exercise.target,
                  style: targetValueStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Оборудование
            Row(
              children: [
                Icon(Icons.sports_gymnastics, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text("Equipment: ", style: targetLabelStyle),
                Text(
                  exercise.equipment,
                  style: targetValueStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Заголовок секции инструкций
            Text("Instructions", style: headerStyle),
            const SizedBox(height: 10),

            if (exercise.instructions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercise.instructions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Номер шага
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: numberStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Текст инструкции
                        Expanded(
                          child: Text(
                            exercise.instructions[index],
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Center(
                child: Text(
                  "Instructions not available.",
                  style: placeholderStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}