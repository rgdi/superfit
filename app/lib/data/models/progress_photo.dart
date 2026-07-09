// Foto de progreso corporal
class ProgressPhoto {
  final String id;
  final DateTime date;
  final String imagePath; // ruta local absoluta
  final double? weightKg;
  final double? bodyFatPct;
  final String? notes;
  final String pose; // front | side | back

  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.imagePath,
    this.weightKg,
    this.bodyFatPct,
    this.notes,
    required this.pose,
  });

  factory ProgressPhoto.fromMap(Map<String, dynamic> m) => ProgressPhoto(
    id: m['id'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    imagePath: m['image_path'] as String,
    weightKg: (m['weight_kg'] as num?)?.toDouble(),
    bodyFatPct: (m['body_fat_pct'] as num?)?.toDouble(),
    notes: m['notes'] as String?,
    pose: m['pose'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'image_path': imagePath,
    'weight_kg': weightKg,
    'body_fat_pct': bodyFatPct,
    'notes': notes,
    'pose': pose,
  };
}
