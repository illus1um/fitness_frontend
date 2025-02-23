import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitness_app/services/api_service.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> workoutExercises = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// 📌 **Загрузка данных профиля**
  void loadUserData() async {
    var data = await ApiService.getUserProfile();

    if (data != null) {
      print("🔹 Полученные данные профиля: $data");
      setState(() {
        userData = data;
      });
      await loadExercises();
    } else {
      print("🔺 Ошибка загрузки данных профиля");
    }
  }

  /// 📌 **Загрузка и фильтрация упражнений**
  Future<void> loadExercises() async {
    String jsonString = await rootBundle.loadString('assets/ideal.json');
    List<dynamic> jsonList = json.decode(jsonString);

    List<Map<String, dynamic>> filteredExercises = [];

    if (userData != null) {
      String goal = userData!["training_program"];
      String location = userData!["training_location"];
      String experience = userData!["training_experience"];

      print("📌 Фильтрация упражнений для: $goal, $location, $experience");

      for (var exercise in jsonList) {
        if (exercise["Training Program"] == goal &&
            exercise["Training Location"] == location &&
            exercise["Training Experience"] == experience) {
          
          String gifUrl = exercise["GIF URL"];
          String gifFileName = gifUrl.split('/').last; // Получаем последнее имя файла

          // 🔥 Добавляем проверку расширения
          if (!gifFileName.endsWith(".gif")) {
            gifFileName = "$gifFileName.gif";
          }

          String previewFileName = gifFileName.replaceAll('.gif', '.png'); // Делаем превью

          // ✅ Правильные пути
          String gifPath = "assets/gifs/$gifFileName";
          String previewPath = "assets/gifs/$previewFileName";

          filteredExercises.add({
            "name": exercise["Exercise Name"],
            "bodyPart": exercise["Body Part"],
            "target": exercise["Target Muscle"],
            "equipment": exercise["Equipment"],
            "gif": gifPath, // 🔹 Используем локальную гифку
            "preview": previewPath, // 🔹 Превью для списка
            "instructions": exercise["Instructions"] ?? [],
          });
        }
      }
    }

    setState(() {
      workoutExercises = filteredExercises;
    });

    print("✅ Найдено ${workoutExercises.length} упражнений.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Plan"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, 
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 20),
                    Text("Recommended Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 199, 169, 127))),
                    SizedBox(height: 10),
                    workoutExercises.isEmpty
                        ? Center(child: Text("No exercises found for your selection."))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: workoutExercises.length,
                            itemBuilder: (context, index) {
                              var exercise = workoutExercises[index];
                              return _buildExerciseTile(exercise);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 📌 **Карточка с информацией о пользователе**
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(Icons.flag, "Goal", userData?["training_program"] ?? "Not selected"),
          _buildInfoTile(Icons.location_on, "Location", userData?["training_location"] ?? "Not selected"),
          _buildInfoTile(Icons.emoji_events, "Experience", userData?["training_experience"] ?? "Not selected"),
        ],
      ),
    );
  }

  /// 📌 **Отображение информации о пользователе**
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }

  /// 📌 **Карточка упражнения с навигацией**
  Widget _buildExerciseTile(Map<String, dynamic> exercise) {
    return Card(
      color: Colors.white, 
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Image.asset(
          exercise["preview"],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("⚠ Ошибка загрузки превью: ${exercise["preview"]}");
            return Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
          },
        ),

        title: Text(
          exercise["name"],
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Target: ${exercise["target"]}\nEquipment: ${exercise["equipment"]}",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise)),
          );
        },
      ),
    );
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;

  ExerciseDetailScreen(this.exercise);

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  List<dynamic>? instructions;

  @override
  void initState() {
    super.initState();
    loadInstructions();
  }

  /// 📌 **Загружаем инструкции из `exercises.json`**
  Future<void> loadInstructions() async {
    try {
      String jsonString = await rootBundle.loadString('assets/exercises.json');
      List<dynamic> exercisesList = json.decode(jsonString);

      // 🔹 Ищем упражнение по названию
      var matchedExercise = exercisesList.firstWhere(
        (ex) => ex["name"].toLowerCase() == widget.exercise["name"].toLowerCase(),
        orElse: () => {},
      );

      setState(() {
        instructions = matchedExercise.isNotEmpty ? matchedExercise["instructions"] : [];
      });

      print("✅ Инструкции загружены: ${instructions?.length} шагов");
    } catch (e) {
      print("❌ Ошибка загрузки инструкций: $e");
      setState(() {
        instructions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise["name"] ?? "Exercise"),
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
              // 🔹 GIF изображения
              Center(
                child: Image.asset(
                  widget.exercise["gif"] ?? "assets/images/placeholder.png",
                  height: 350,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("⚠ Ошибка загрузки гифки: ${widget.exercise["gif"]}");
                    return Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                  },
                ),
              ),
              SizedBox(height: 20),

              // 🔹 Название упражнения
              Text(
                widget.exercise["name"] ?? "Unknown Exercise",
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
                    widget.exercise["target"] ?? "Unknown",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 🔹 Заголовок перед инструкциями
              Text(
                "Instructions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // 🔹 Проверяем, есть ли инструкции
              if (instructions != null && instructions!.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true, // ✅ Отключаем бесконечную прокрутку
                  physics: NeverScrollableScrollPhysics(), // ✅ Используем общий скролл
                  itemCount: instructions!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Кружок с номером шага
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
                              instructions![index],
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
                    "Instructions not available.",
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