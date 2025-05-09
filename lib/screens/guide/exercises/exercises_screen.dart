import 'package:flutter/material.dart';
import 'data_provider.dart';
import 'exercise_list_screen.dart';

class ExercisesScreen extends StatefulWidget {
  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  Map<String, List<Map<String, dynamic>>> groupedExercises = {};
  List<String> filteredMuscleGroups = [];
  TextEditingController searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  Color _borderColor = Colors.grey; // Цвет границы по умолчанию

  @override
  void initState() {
    super.initState();
    _loadData();

    // Добавляем слушатель на изменение фокуса
    _searchFocusNode.addListener(() {
      setState(() {
        _borderColor = _searchFocusNode.hasFocus
            ? Color.fromARGB(255, 219, 200, 173) // Цвет при фокусе
            : Colors.grey; // Цвет по умолчанию
      });
    });
  }

  void _loadData() async {
    var data = await DataProvider.loadExercises();
    setState(() {
      groupedExercises = data;
      filteredMuscleGroups = groupedExercises.keys.toList();
    });
  }

  // 🔍 Фильтр поиска
  void _filterGroups(String query) {
    setState(() {
      filteredMuscleGroups = groupedExercises.keys
          .where((group) => group.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text("Muscle Groups"),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
      body: Column(
        children: [
          // 🔹 Поле поиска с уменьшенной высотой и динамической границей
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SizedBox(
              height: 40, // Уменьшенная высота поля поиска
              child: TextField(
                controller: searchController,
                focusNode: _searchFocusNode, // Добавляем focusNode
                onChanged: _filterGroups, // Вызываем фильтр при вводе
                decoration: InputDecoration(
                  hintText: "Search muscle group...",
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
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Компактный стиль
                ),
              ),
            ),
          ),

          // 🔹 Список групп мышц с увеличенными элементами
          Expanded(
            child: groupedExercises.isEmpty
                ? Center(child: CircularProgressIndicator()) // Показываем загрузку
                : ListView.builder(
                    itemCount: filteredMuscleGroups.length,
                    itemBuilder: (context, index) {
                      String muscleGroup = filteredMuscleGroups[index];

                      // 🔹 Путь к изображению группы мышц
                      String imagePath = "assets/muscle_groups/${muscleGroup.toLowerCase()}.png";

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8), // Скругляем углы
                              child: Image.asset(
                                imagePath,
                                width: 70, // Увеличенный размер изображения
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset("assets/placeholder.png", width: 70, height: 70),
                              ),
                            ),
                            title: Text(
                              _capitalize(muscleGroup),
                              style: TextStyle(fontSize: 20),
                            ),
                            trailing: Icon(Icons.chevron_right, size: 28),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExerciseListScreen(
                                    muscleGroup: muscleGroup,
                                    exercises: groupedExercises[muscleGroup]!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
