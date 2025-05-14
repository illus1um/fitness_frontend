import 'package:flutter/material.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailScreen(this.exercise, {Key? key}) : super(key: key);

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
    final circleColor =Color.fromARGB(255, 199, 169, 127);
    final placeholderStyle = textStyle.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.disabledColor,
    );
    final nameStyle = theme.textTheme.headlineSmall!
        .copyWith(fontWeight: FontWeight.bold);
    final targetLabelStyle = textStyle;
    final targetValueStyle = textStyle.copyWith(fontWeight: FontWeight.w600);

    final List<dynamic>? instructions = exercise["instructions"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _capitalize(exercise["name"] ?? "Exercise"),
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
                exercise["gif"] ?? "assets/images/placeholder.png",
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
              _capitalize(exercise["name"] ?? "Unknown Exercise"),
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
                  exercise["target"] ?? "Unknown",
                  style: targetValueStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Заголовок секции инструкций
            Text("Instructions", style: headerStyle),
            const SizedBox(height: 10),

            if (instructions != null && instructions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: instructions.length,
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
                            instructions[index],
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
