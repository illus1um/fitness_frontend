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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFC7A97F);

    final List<dynamic>? instructions = exercise["instructions"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _capitalize(exercise["name"] ?? "Exercise"),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with improved styling
            Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: isDarkMode ? 0 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  exercise["gif"] ?? "assets/images/placeholder.png",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Exercise information with improved styling
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: isDarkMode ? 0 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    _capitalize(exercise["name"] ?? "Unknown Exercise"),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Target muscle info in styled row
                  _buildInfoRow(
                    context,
                    Icons.fitness_center,
                    "Target",
                    exercise["target"] ?? "Unknown",
                    isDarkMode,
                    goldColor,
                  ),
                  
                  // Add equipment info if available
                  if (exercise["equipment"] != null) 
                    const SizedBox(height: 12),
                    
                  if (exercise["equipment"] != null)
                    _buildInfoRow(
                      context,
                      Icons.sports_gymnastics,
                      "Equipment",
                      exercise["equipment"],
                      isDarkMode,
                      goldColor,
                    ),
                ],
              ),
            ),

            // Instructions section with improved styling
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: isDarkMode ? 0 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF3A3225)
                              : goldColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.format_list_numbered,
                          color: goldColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Instructions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Instructions list with styled numbering
                  if (instructions != null && instructions.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: instructions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step number in gold circle
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: goldColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Instruction text with theme-aware styling
                              Expanded(
                                child: Text(
                                  instructions[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    // Styled placeholder for missing instructions
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Instructions not available.",
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Добавляем дополнительную информацию, если она есть
            if (exercise["bodyPart"] != null || exercise["secondaryMuscles"] != null)
              const SizedBox(height: 24),
              
            if (exercise["bodyPart"] != null || exercise["secondaryMuscles"] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: isDarkMode ? 0 : 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF3A3225)
                                : goldColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: goldColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Additional Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Body part
                    if (exercise["bodyPart"] != null) 
                      _buildInfoRow(
                        context,
                        Icons.accessibility_new,
                        "Body Part",
                        exercise["bodyPart"],
                        isDarkMode,
                        goldColor,
                      ),
                    
                    if (exercise["bodyPart"] != null && exercise["secondaryMuscles"] != null) 
                      const SizedBox(height: 12),
                    
                    // Secondary muscles
                    if (exercise["secondaryMuscles"] != null)
                      _buildInfoRow(
                        context,
                        Icons.list_alt,
                        "Secondary Muscles",
                        exercise["secondaryMuscles"],
                        isDarkMode,
                        goldColor,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
    Color goldColor,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF3A3225)
                : goldColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: goldColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
