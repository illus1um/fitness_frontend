import 'package:flutter/material.dart';
import 'exercise_detail_screen.dart';
import '../../../services/gif_service.dart';

class ExerciseListScreen extends StatefulWidget {
  final String muscleGroup;
  final List<Map<String, dynamic>> exercises;

  const ExerciseListScreen({
    Key? key,
    required this.muscleGroup,
    required this.exercises,
  }) : super(key: key);

  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  late List<Map<String, dynamic>> filteredExercises;
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredExercises = widget.exercises;
    _filterExercises('');
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterExercises(String query) {
    setState(() {
      filteredExercises = widget.exercises.where((exercise) {
        final name = (exercise['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12.0);
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;
    final iconColor = theme.iconTheme.color;
    final bodyStyle = theme.textTheme.bodyMedium;
    final titleStyle = theme.textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(widget.muscleGroup)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                focusNode: _searchFocusNode,
                onChanged: _filterExercises,
                style: bodyStyle,
                decoration: InputDecoration(
                  hintText: 'Search exercise...',
                  hintStyle: bodyStyle,
                  prefixIcon: Icon(Icons.search, color: iconColor),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide:
                        BorderSide(color: theme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
          ),

          // Exercises list
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: bodyStyle,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      final gifFileName = exercise['gifFileName'] as String?;
                      final useAsset = gifFileName == null;
                      
                      final imagePath = useAsset 
                          ? 'images/placeholder.png'
                          : 'gifs/${gifFileName.replaceAll('.gif', '.png')}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: borderRadius,
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.1),
                                blurRadius: 6,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: useAsset 
                                ? Icon(Icons.fitness_center, 
                                    size: 50, 
                                    color: Theme.of(context).primaryColor)
                                : GifService.loadNetworkGif(
                                    gifName: gifFileName.replaceAll('.gif', '.png'),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorWidget: Icon(Icons.image_not_supported,
                                        size: 50, color: iconColor),
                                  ),
                            ),
                            title: Text(
                              _capitalize(exercise['name'] ?? ''),
                              style: titleStyle,
                            ),
                            trailing:
                                Icon(Icons.chevron_right, color: iconColor),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExerciseDetailScreen(exercise),
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
