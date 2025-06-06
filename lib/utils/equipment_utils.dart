class EquipmentUtils {
  static const List<String> homeEquipment = [
    'body weight',
    'band',
    'resistance band',
    'medicine ball',
    'dumbbell',
    'kettlebell',
    'stability ball',
    'foam roller',
    'yoga mat',
    'weighted',
    'wheel roller',
    'rope',
    'assisted',
    'cable',
    'exercise band',
    'suspension',
  ];

  static bool isHomeEquipment(String equipment) {
    final String equip = equipment.toLowerCase();
    return homeEquipment.any((e) => equip.contains(e));
  }

  static const List<String> gymOnlyEquipment = [
    'barbell',
    'leverage machine',
    'smith machine',
    'sled machine',
    'upper body ergometer',
    'stationary bike',
    'elliptical machine',
    'hammer',
    'trap bar',
    'hack squat machine',
    'leg curl machine',
    'leg extension machine',
    'pec deck machine',
    'seated row machine',
    'pull-down machine',
    'fly machine',
    'cable crossover',
    'power rack',
    'squat rack',
  ];

  static bool isGymOnlyEquipment(String equipment) {
    final String equip = equipment.toLowerCase();
    return gymOnlyEquipment.any((e) => equip.contains(e));
  }
} 