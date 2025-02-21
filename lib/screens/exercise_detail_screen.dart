import 'package:flutter/material.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> exercise;

  ExerciseDetailScreen(this.exercise);

  @override
  Widget build(BuildContext context) {
    List<dynamic>? instructions = exercise["instructions"];

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise["name"] ?? "Exercise"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView( // ✅ Делаем весь экран прокручиваемым
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 GIF
              Center(
                child: Image.asset(
                  exercise["gif"] ?? "assets/images/placeholder.png",
                  height: 350,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),

              // 🔹 Название упражнения
              Text(
                exercise["name"] ?? "Unknown Exercise",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // 🔹 Основная мышца
              Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Target: "),
                  Text(
                    exercise["target"] ?? "Unknown",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 🔹 Инструкция по выполнению
              Text(
                "Instructions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // 🔹 Список инструкций (без Expanded)
              if (instructions != null && instructions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true, // ✅ Отключаем бесконечную прокрутку
                  physics: NeverScrollableScrollPhysics(), // ✅ Используем общий скролл
                  itemCount: instructions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Кружок с номером
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 199, 169, 127),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // 🔹 Текст инструкции
                          Expanded(
                            child: Text(
                              instructions[index],
                              style: TextStyle(fontSize: 16, color: Colors.black87),
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
                    "Инструкции не найдены.",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
