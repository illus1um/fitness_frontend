// lib/screens/workout/workout_session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';
import '../../models/progress_entry.dart';
import '../../services/api_service.dart';

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
  
  // Для отслеживания веса/нагрузки
  TextEditingController _weightController = TextEditingController(text: '0');
  Map<String, String> _exerciseWeights = {};
  
  // Для отображения подсказок
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    exIndex = widget.startIndex;
    _loadCurrentProgress();
    _loadPreviousWeights();
  }
  
  Future<void> _loadPreviousWeights() async {
    // Здесь можно загрузить веса из предыдущих тренировок
    // Это заглушка, которую можно заменить на реальную загрузку из БД/API
    setState(() {
      _exerciseWeights = {};
      for (var ex in widget.day.exercises) {
        _exerciseWeights[ex.id] = '0';
      }
    });
    
    // Устанавливаем текущий вес для упражнения
    final ex = widget.day.exercises[exIndex];
    _weightController.text = _exerciseWeights[ex.id] ?? '0';
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
    
    // Сохраняем вес/нагрузку для текущего упражнения
    _exerciseWeights[ex.id] = _weightController.text;
    
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
        title: Text('Пропустить упражнение?'),
        content: Text('Вы действительно хотите пропустить текущее упражнение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextExercise();
            },
            child: Text('Пропустить'),
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
        _showInstructions = false;
      });
      
      // Устанавливаем вес для нового упражнения
      final ex = widget.day.exercises[exIndex];
      _weightController.text = _exerciseWeights[ex.id] ?? '0';
      
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
        _showInstructions = false;
      });
      _loadCurrentProgress();
      
      // Устанавливаем вес для предыдущего упражнения
      final ex = widget.day.exercises[exIndex];
      _weightController.text = _exerciseWeights[ex.id] ?? '0';
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Поздравляем!'),
        content: Text('Тренировка дня ${widget.day.dayIndex + 1} завершена.'),
        actions: [
          TextButton(
            onPressed: () async {
              // Вызываем коллбэк завершения
              if (widget.onComplete != null) {
                await widget.onComplete!();
              }
              Navigator.pop(context); // Закрываем диалог
              Navigator.pop(context); // Возвращаемся на экран дня
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _weightController.dispose();
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
                title: Text('Завершить тренировку?'),
                content: Text('Ваш прогресс будет сохранен, но тренировка не будет завершена.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрываем диалог
                      Navigator.pop(context); // Возвращаемся на экран дня
                    },
                    child: Text('Выйти'),
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Изображение упражнения
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.asset(
                      ex.assetGifPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                  
                  // Информация об упражнении
                  ExpansionPanelList(
                    elevation: 0,
                    expandedHeaderPadding: EdgeInsets.zero,
                    expansionCallback: (_, isExpanded) {
                      setState(() {
                        _showInstructions = !_showInstructions;
                      });
                    },
                    children: [
                      ExpansionPanel(
                        headerBuilder: (context, isExpanded) {
                          return ListTile(
                            title: Text('Инструкции по выполнению', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                            leading: Icon(Icons.info_outline),
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Целевая группа мышц: ${ex.target}'),
                              SizedBox(height: 8),
                              Text('Оборудование: ${ex.equipment}'),
                              SizedBox(height: 16),
                              if (ex.instructions.isNotEmpty) ...[
                                Text('Как выполнять:', 
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                ...ex.instructions.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${entry.key + 1}. ', 
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                        Expanded(child: Text(entry.value)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ] else
                                Text('Нет подробных инструкций для этого упражнения.'),
                            ],
                          ),
                        ),
                        isExpanded: _showInstructions,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Панель с весом/нагрузкой
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: Text('Вес/нагрузка:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffix: Text('кг'),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
                  footer: Text(isResting ? 'Отдых' : 'Секунд'),
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
                  footer: const Text('Подходов'),
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
                            child: Text('Предыдущее'),
                            style: OutlinedButton.styleFrom(minimumSize: Size(0, 40)),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton(
                          onPressed: _skipExercise,
                          child: Text('Пропустить'),
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
                        ? 'ЗАВЕРШИТЬ ОТДЫХ'
                        : currentSet < ex.sets
                            ? 'ЗАВЕРШИТЬ ПОДХОД'
                            : 'СЛЕДУЮЩЕЕ УПРАЖНЕНИЕ',
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
