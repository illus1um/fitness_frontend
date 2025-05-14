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
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await DataProvider.loadExercises();
    setState(() {
      groupedExercises = data;
      filteredMuscleGroups = groupedExercises.keys.toList();
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = 12.0;
    final borderRadius = BorderRadius.circular(12.0);
    final cardColor = theme.cardColor;
    final shadowColor = theme.shadowColor.withOpacity(0.1);
    final titleStyle = theme.textTheme.headlineSmall!
        .copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(
        title: Text('Muscle Groups'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: groupedExercises.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(theme.primaryColor),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(padding),
                    child: GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: padding,
                        mainAxisSpacing: padding,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredMuscleGroups.length,
                      itemBuilder: (context, index) {
                        final muscleGroup =
                            filteredMuscleGroups[index];
                        final imagePath =
                            'assets/muscle_groups/${muscleGroup.toLowerCase()}.png';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseListScreen(
                                  muscleGroup: muscleGroup,
                                  exercises:
                                      groupedExercises[muscleGroup]!,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: cardColor,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius,
                            ),
                            shadowColor: shadowColor,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) =>
                                          Container(
                                        color: theme.dividerColor,
                                        child: Icon(Icons.image_not_supported,
                                            size: 48,
                                            color: theme.disabledColor),
                                      ),
                                    ),
                                  ),
                                ),
                                // Label
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _capitalize(muscleGroup),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
