import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'data_provider.dart';

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

  /// 📌 **Load User Data & Fetch Exercises**
  void loadUserData() async {
    var data = await ApiService.getUserProfile();

    if (data != null) {
      print("🔹 Retrieved Profile Data: $data");
      setState(() {
        userData = data;
      });

      await loadExercises();
    } else {
      print("🔺 Error Loading Profile Data");
    }
  }

  /// 📌 **Fetch & Filter Exercises**
  Future<void> loadExercises() async {
    var allExercises = await DataProvider.loadExercises();
    List<Map<String, dynamic>> filteredExercises = [];

    if (userData != null) {
      String goal = userData!["training_program"];
      String location = userData!["training_location"];
      String experience = userData!["training_experience"];

      print("📌 Filtering Exercises for: $goal, $location, $experience");

      allExercises.forEach((muscleGroup, exercises) {
        for (var exercise in exercises) {
          if (_matchesCriteria(exercise, goal, location, experience)) {
            filteredExercises.add(exercise);
          }
        }
      });
    }

    setState(() {
      workoutExercises = filteredExercises;
    });

    print("✅ ${workoutExercises.length} exercises found.");
  }

  /// 📌 **Filter Exercises Based on User Selections**
  bool _matchesCriteria(Map<String, dynamic> exercise, String goal, String location, String experience) {
    Map<String, List<String>> goalTargets = {
      "Full Body": ["abs", "core", "legs", "chest", "back", "shoulders"],
      "Legs": ["quadriceps", "hamstrings", "calves"],
      "Weight Loss": ["cardio", "full body"],
      "Endurance": ["cardio", "core", "legs"],
      "Gain Muscle Mass": ["chest", "back", "legs", "arms", "shoulders"],
      "Wide Back": ["back", "lats"]
    };

    Map<String, List<String>> locationEquipment = {
      "At home": ["bodyweight", "calisthenics", "stretching"],
      "In the gym": ["barbell", "dumbbell", "cable", "machine"]
    };

    bool isForGoal = goalTargets[goal]?.contains(exercise["target"].toLowerCase()) ?? false;
    bool isForLocation = locationEquipment[location]?.contains(exercise["equipment"]) ?? false;
    bool isForExperience = experience != "No experience";

    return isForGoal && isForLocation && isForExperience;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Plan"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
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
                    Text("Recommended Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    workoutExercises.isEmpty
                        ? Center(child: Text("No exercises found for your selection."))
                        : ListView.builder(
                            shrinkWrap: true, // ✅ Позволяет `ListView` встроиться в `Column`
                            physics: NeverScrollableScrollPhysics(), // ✅ Отключает отдельный скролл
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

  /// 📌 **Build User Info Card**
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
          _buildInfoTile(Icons.fitness_center, "Experience", userData?["training_experience"] ?? "Not selected"),
        ],
      ),
    );
  }

  /// 📌 **Display User Info**
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }

  /// 📌 **Build Exercise Tile**
  Widget _buildExerciseTile(Map<String, dynamic> exercise) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Image.asset(
          exercise["gif"].replaceAll(".gif", ".png"),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
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
          // Navigation to exercise details
        },
      ),
    );
  }
}
