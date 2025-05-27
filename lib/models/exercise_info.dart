class ExerciseInfo {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String gifUrl;
  final String target;
  final List<String> secondaryTargets;
  final List<String> instructions;
  final List<String> programs;
  final List<String> locations;
  final List<String> experienceLevels;
  final int sets;
  final int reps;
  final int durationSec;
  final int restSec;

  ExerciseInfo({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.gifUrl,
    required this.target,
    required this.secondaryTargets,
    required this.instructions,
    required this.programs,
    required this.locations,
    required this.experienceLevels,
    required this.sets,
    required this.reps,
    required this.durationSec,
    required this.restSec,
  });

  /// Создаёт объект из JSON-карты
  factory ExerciseInfo.fromJson(Map<String, dynamic> j) => ExerciseInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        bodyPart: j['bodyPart'] as String,
        equipment: j['equipment'] as String,
        gifUrl: j['gifUrl'] as String,
        target: j['target'] as String,
        secondaryTargets: List<String>.from(j['secondaryTargets'] ?? <String>[]),
        instructions: List<String>.from(j['instructions'] ?? <String>[]),
        programs: List<String>.from(j['programs'] as List<dynamic>),
        locations: List<String>.from(j['locations'] as List<dynamic>),
        experienceLevels:
            List<String>.from(j['experienceLevels'] as List<dynamic>),
        sets: j['sets'] as int,
        reps: j['reps'] as int,
        durationSec: j['durationSec'] as int,
        restSec: j['restSec'] as int,
      );


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'gifUrl': gifUrl,
        'target': target,
        'secondaryTargets': secondaryTargets,
        'instructions': instructions,
        'programs': programs,
        'locations': locations,
        'experienceLevels': experienceLevels,
        'sets': sets,
        'reps': reps,
        'durationSec': durationSec,
        'restSec': restSec,
  };

  /// Чтение из prefs
  factory ExerciseInfo.fromStorage(Map<String, dynamic> j) =>
      ExerciseInfo.fromJson(j);

  /// Получает путь к гифке для загрузки с сервера
  String get assetGifPath {

    final fileName = gifUrl.split('/').last;
    final nameWithExt =
        fileName.toLowerCase().endsWith('.gif') ? fileName : '$fileName.gif';
    return 'gifs/$nameWithExt';
  }

  /// Получает имя файла гифки для загрузки через GifService
  String get gifFileName {
    final fileName = gifUrl.split('/').last;
    return fileName.toLowerCase().endsWith('.gif') ? fileName : '$fileName.gif';
  }

  /// Получает путь для превью (обычно статичная картинка)
  String get assetPreviewPath {
    final fileName = gifUrl.split('/').last;
    // убираем возможный .gif
    final base = fileName.toLowerCase().endsWith('.gif')
      ? fileName.substring(0, fileName.length - 4)
      : fileName;
    return 'gifs/$base.png';
  }
}