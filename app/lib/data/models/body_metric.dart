// Métrica corporal (peso, grasa, perímetros)
class BodyMetric {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPct;
  // Measurements en cm, opcionalmente
  final double? chestCm;
  final double? waistCm;
  final double? armCm;
  final double? thighCm;

  const BodyMetric({
    required this.id,
    required this.date,
    this.weightKg,
    this.bodyFatPct,
    this.chestCm,
    this.waistCm,
    this.armCm,
    this.thighCm,
  });

  factory BodyMetric.fromMap(Map<String, dynamic> m) => BodyMetric(
    id: m['id'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    weightKg: (m['weight_kg'] as num?)?.toDouble(),
    bodyFatPct: (m['body_fat_pct'] as num?)?.toDouble(),
    chestCm: (m['chest_cm'] as num?)?.toDouble(),
    waistCm: (m['waist_cm'] as num?)?.toDouble(),
    armCm: (m['arm_cm'] as num?)?.toDouble(),
    thighCm: (m['thigh_cm'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'weight_kg': weightKg,
    'body_fat_pct': bodyFatPct,
    'chest_cm': chestCm,
    'waist_cm': waistCm,
    'arm_cm': armCm,
    'thigh_cm': thighCm,
  };
}
