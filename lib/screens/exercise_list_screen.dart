import 'package:flutter/material.dart';
import 'exercise_detail_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  final String muscleGroup;
  final List<Map<String, dynamic>> exercises;

  ExerciseListScreen({required this.muscleGroup, required this.exercises});

  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<Map<String, dynamic>> filteredExercises = [];
  TextEditingController searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  Color _borderColor = Colors.grey; // Цвет границы по умолчанию

  @override
  void initState() {
    super.initState();
    _filterExercises(""); // Инициализация списка

    // Добавляем слушатель на изменение фокуса
    _searchFocusNode.addListener(() {
      setState(() {
        _borderColor = _searchFocusNode.hasFocus
            ? Color.fromARGB(255, 219, 200, 173) // Цвет при фокусе
            : Colors.grey; // Цвет по умолчанию
      });
    });
  }

  // 🔍 Фильтр поиска
  void _filterExercises(String query) {
    setState(() {
      filteredExercises = widget.exercises
          .where((exercise) =>
              (exercise["name"] ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.muscleGroup),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,      
      ),
      body: Column(
        children: [
          // 🔹 Поле поиска с уменьшенной высотой и эффектом фокуса
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SizedBox(
              height: 40, // Уменьшаем высоту поля поиска
              child: TextField(
                controller: searchController,
                focusNode: _searchFocusNode, // Добавляем focusNode
                onChanged: _filterExercises, // Фильтруем список при вводе
                decoration: InputDecoration(
                  hintText: "Search exercise...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _borderColor), // Динамический цвет границы
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey), // Граница без фокуса
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 219, 200, 173), width: 2), // Цвет при фокусе
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Уменьшаем внутренние отступы
                ),
              ),
            ),
          ),

          // 🔹 Список упражнений
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(child: Text("No exercises found"))
                : ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];

                      // 🔹 Заменяем путь к GIF на статичное изображение (например, PNG)
                      String staticImagePath =
                          exercise["gif"]?.replaceAll(".gif", ".png") ??
                          "assets/placeholder.png";

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            staticImagePath, // ✅ Отображаем статичное изображение вместо GIF
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                        title: Text(exercise["name"] ?? "No Name",
                            style: TextStyle(fontSize: 18)),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExerciseDetailScreen(exercise),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
