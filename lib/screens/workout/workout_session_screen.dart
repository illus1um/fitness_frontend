// lib/screens/workout/workout_session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/day_info.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final DayInfo day;
  const WorkoutSessionScreen({required this.day, Key? key}) : super(key: key);

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int exIndex = 0;
  int currentSet = 0;
  bool isResting = false;
  Timer? timer;
  int secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startExercise();
  }

  void _startExercise() {
    final ex = widget.day.exercises[exIndex];
    // Если время выполнения не задано, оставляем 0
    secondsLeft = ex.durationSec;
    timer?.cancel();
    if (secondsLeft > 0) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft <= 0) {
          t.cancel();
        } else {
          setState(() => secondsLeft--);
        }
      });
    }
  }

  void _finishSet() {
    timer?.cancel();
    final ex = widget.day.exercises[exIndex];

    if (!isResting) {
      // Завершили подход
      setState(() => currentSet++);
      if (currentSet < ex.sets) {
        // Переходим в отдых
        isResting = true;
        secondsLeft = ex.restSec;
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (secondsLeft <= 0) {
            t.cancel();
          } else {
            setState(() => secondsLeft--);
          }
        });
      } else {
        // Все подходы завершены → следующее упражнение
        _nextExercise();
      }
    } else {
      // Завершили отдых → новый подход
      setState(() => isResting = false);
      _startExercise();
    }
  }

  void _nextExercise() {
    if (exIndex < widget.day.exercises.length - 1) {
      setState(() {
        exIndex++;
        currentSet = 0;
        isResting = false;
      });
      _startExercise();
    } else {
      // Конец дня
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Поздравляем!'),
          content: Text('Тренировка дня ${widget.day.dayIndex} завершена.'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, ModalRoute.withName('/')),
              child: const Text('Готово'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Возвращает процент завершения, либо 0.0 при делении на ноль.
  double pct(int num, int den) => den > 0 ? num / den : 0.0;

  @override
  Widget build(BuildContext context) {
    final ex = widget.day.exercises[exIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${exIndex + 1}/${widget.day.exercises.length} ${ex.name}'),
        actions: [
          IconButton(onPressed: () {/* пауза пока нет */}, icon: const Icon(Icons.pause))
        ],
      ),
      body: Column(
        children: [
          // GIF из локальных assets
          Expanded(
            child: Center(
              child: Image.asset(
                ex.assetGifPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
              ),
            ),
          ),

          // Круговые индикаторы
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Таймер/подход
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 6,
                  percent: isResting
                      ? 0.0
                      : pct(ex.durationSec - secondsLeft, ex.durationSec),
                  center: Text('$secondsLeft', style: const TextStyle(fontSize: 16)),
                  footer: Text(isResting ? 'Отдых' : 'Секунд'),
                ),

                // Отдых
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 6,
                  percent: isResting
                      ? pct(ex.restSec - secondsLeft, ex.restSec)
                      : 0.0,
                  center: isResting
                      ? Text('$secondsLeft', style: const TextStyle(fontSize: 16))
                      : const Icon(Icons.lock),
                  footer: const Text('Отдых'),
                ),

                // Подходы
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 6,
                  percent: pct(currentSet, ex.sets),
                  center: Text('$currentSet/${ex.sets}', style: const TextStyle(fontSize: 16)),
                  footer: const Text('Подходов'),
                ),
              ],
            ),
          ),

          // Кнопка завершения подхода/отдыха
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: secondsLeft == 0 ? _finishSet : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(isResting ? 'Завершить отдых' : 'Завершить подход'),
            ),
          ),
        ],
      ),
    );
  }
}
