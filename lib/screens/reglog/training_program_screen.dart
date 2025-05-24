import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'training_location_screen.dart';

class TrainingProgramScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const TrainingProgramScreen({Key? key, required this.registrationData}) : super(key: key);

  @override
  _TrainingProgramScreenState createState() => _TrainingProgramScreenState();
}

class _TrainingProgramScreenState extends State<TrainingProgramScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Map<String, String>> programs = [
    {"name": "Weight loss", "image": "assets/images/weight_loss.jpg", "description": "Burn fat and get lean"},
    {"name": "Endurance", "image": "assets/images/endurance.jpg", "description": "Build stamina and strength"},
    {"name": "Full body", "image": "assets/images/full_body.jpg", "description": "Complete body workout"},
    {"name": "Gain Muscle mass", "image": "assets/images/gain_muscle.jpg", "description": "Build muscle and size"},
    {"name": "Legs", "image": "assets/images/legs.jpg", "description": "Focus on lower body"},
    {"name": "Wide back", "image": "assets/images/wide_back.jpg", "description": "Build a stronger back"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectProgram(String program) {
    setState(() {
      widget.registrationData.trainingProgram = program;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingLocationScreen(registrationData: widget.registrationData),
      ),
    );
  }

  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF1A1A1A)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF5F5F5)],
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Choose Your Path",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a training program that matches your fitness goals",
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  physics: BouncingScrollPhysics(),
                  itemCount: programs.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return _buildProgramCard(
                      program["name"]!,
                      program["image"]!,
                      program["description"]!,
                      index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(String name, String imagePath, String description, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Colors.white;
    final accentColor = Color.fromARGB(255, 199, 169, 127);
    
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => selectProgram(name),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Dark Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Select Program',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

