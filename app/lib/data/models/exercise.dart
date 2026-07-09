// Modelo de Ejercicio
class Exercise {
  final String id;
  final String nameEs;
  final String nameEn;
  final String category; // compound | isolation
  final String pattern; // squat | hinge | horizontal_push | vertical_push | horizontal_pull | vertical_pull | isolation
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipmentId;
  final String imagePath;
  final List<String> instructionsEs;
  final List<String> instructionsEn;
  final List<String> cuesEs;
  final List<String> cuesEn;
  final String defaultReps;
  final int defaultRestSeconds;
  final int rpeTarget;
  final List<String> contraindications;
  final String tempo;
  final String sourceResearch;

  const Exercise({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.category,
    required this.pattern,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipmentId,
    required this.imagePath,
    required this.instructionsEs,
    required this.instructionsEn,
    required this.cuesEs,
    required this.cuesEn,
    required this.defaultReps,
    required this.defaultRestSeconds,
    required this.rpeTarget,
    required this.contraindications,
    required this.tempo,
    required this.sourceResearch,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    category: j['category'] as String,
    pattern: j['pattern'] as String,
    primaryMuscles: (j['primary_muscles'] as List).cast<String>(),
    secondaryMuscles: (j['secondary_muscles'] as List?)?.cast<String>() ?? [],
    equipmentId: j['equipment_id'] as String,
    imagePath: j['image_path'] as String? ?? '',
    instructionsEs: (j['instructions_es'] as List?)?.cast<String>() ?? [],
    instructionsEn: (j['instructions_en'] as List?)?.cast<String>() ?? [],
    cuesEs: (j['cues_es'] as List?)?.cast<String>() ?? [],
    cuesEn: (j['cues_en'] as List?)?.cast<String>() ?? [],
    defaultReps: j['default_reps'] as String,
    defaultRestSeconds: j['default_rest_seconds'] as int,
    rpeTarget: j['rpe_target'] as int,
    contraindications: (j['contraindications'] as List?)?.cast<String>() ?? [],
    tempo: j['tempo'] as String? ?? '2-1-2-0',
    sourceResearch: j['source_research'] as String? ?? '',
  );

  String localizedName(String locale) =>
      locale == 'en' ? nameEn : nameEs;

  List<String> localizedInstructions(String locale) =>
      locale == 'en' ? instructionsEn : instructionsEs;

  List<String> localizedCues(String locale) =>
      locale == 'en' ? cuesEn : cuesEs;
}
