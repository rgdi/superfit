// Modelo de Máquina
class Machine {
  final String id;
  final String nameEs;
  final String nameEn;
  final String descriptionEs;
  final String descriptionEn;
  final String imagePath;
  final List<String> primaryMuscles;
  final List<String> adjustments;

  const Machine({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.imagePath,
    required this.primaryMuscles,
    required this.adjustments,
  });

  factory Machine.fromJson(Map<String, dynamic> j) => Machine(
    id: j['id'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    descriptionEs: j['description_es'] as String? ?? '',
    descriptionEn: j['description_en'] as String? ?? '',
    imagePath: j['image_path'] as String,
    primaryMuscles: (j['primary_muscles'] as List?)?.cast<String>() ?? [],
    adjustments: (j['adjustments'] as List?)?.cast<String>() ?? [],
  );

  String localizedName(String locale) =>
      locale == 'en' ? nameEn : nameEs;

  String localizedDescription(String locale) =>
      locale == 'en' ? descriptionEn : descriptionEs;
}
