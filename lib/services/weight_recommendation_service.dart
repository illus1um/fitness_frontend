import 'package:fitness_app/models/exercise_info.dart';

class WeightRecommendationService {
  static double calculateRecommendedWeight({
    required ExerciseInfo exercise,
    required double userWeight,
    required double userHeight,
    required int userAge,
    required String experience,
    required bool isMale,
  }) {
    double baseMultiplier = _getBaseMultiplier(exercise.equipment);
    
    double experienceMultiplier = _getExperienceMultiplier(experience);
    
    double ageFactor = userAge <= 30 ? 1.0 : 1.0 - ((userAge - 30) * 0.01);
    
    double genderFactor = isMale ? 1.0 : 0.8;
    
    double weightFactor = userWeight / 70.0;
    
    double heightFactor = userHeight / 170.0;
    
    double baseWeight = userWeight * baseMultiplier;
    
    double recommendedWeight = baseWeight * 
        experienceMultiplier * 
        ageFactor * 
        genderFactor * 
        weightFactor * 
        heightFactor;
    
    return _roundToNearestWeight(recommendedWeight);
  }
  
  static double _getBaseMultiplier(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return 0.8; 
      case 'dumbbell':
        return 0.3; 
      case 'kettlebell':
        return 0.4;
      case 'weighted':
        return 0.5;
      case 'cable':
        return 0.4; 
      case 'smith machine':
        return 0.7; 
      default:
        return 0.0; 
    }
  }
  
  static double _getExperienceMultiplier(String experience) {
    switch (experience.toLowerCase()) {
      case 'no experience':
        return 0.5;
      case 'beginner':
        return 0.7;
      case 'experienced':
        return 0.9;
      case 'pro':
        return 1.0;
      default:
        return 0.7;
    }
  }
  
  static double _roundToNearestWeight(double weight) {
    return (weight / 2.5).round() * 2.5;
  }
  
  static bool needsWeightRecommendation(String equipment) {
    final weightedEquipment = [
      'barbell',
      'dumbbell',
      'kettlebell',
      'weighted',
      'cable',
      'smith machine'
    ];
    return weightedEquipment.contains(equipment.toLowerCase());
  }
} 