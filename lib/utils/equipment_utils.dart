/// Утилиты для работы с оборудованием
class EquipmentUtils {
  /// Список оборудования, доступного для домашних тренировок
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

  /// Проверяет, можно ли использовать данное оборудование для домашних тренировок
  static bool isHomeEquipment(String equipment) {
    final String equip = equipment.toLowerCase();
    return homeEquipment.any((e) => equip.contains(e));
  }

  /// Список оборудования, которое требуется только для тренировок в зале
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

  /// Проверяет, требует ли данное оборудование тренировки только в зале
  static bool isGymOnlyEquipment(String equipment) {
    final String equip = equipment.toLowerCase();
    return gymOnlyEquipment.any((e) => equip.contains(e));
  }
} 