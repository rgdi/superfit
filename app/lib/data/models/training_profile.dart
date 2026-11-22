// Perfil de entrenamiento: lo que el sistema necesita para personalizar.
import 'dart:convert';

enum Sex { male, female, unspecified }

/// Zonas con molestias/lesión. Se cruzan con `contraindications` de cada ejercicio.
const Map<String, String> kInjuryLabels = {
  'shoulder': 'Hombro',
  'knee': 'Rodilla',
  'lower_back': 'Zona lumbar',
  'elbow': 'Codo',
  'hip': 'Cadera',
  'neck': 'Cuello / cervical',
  'achilles': 'Tendón de Aquiles',
};

/// Grupos musculares para planificar volumen semanal.
const Map<String, String> kMuscleGroupLabels = {
  'chest': 'Pecho',
  'back': 'Espalda',
  'shoulders': 'Hombros',
  'biceps': 'Bíceps',
  'triceps': 'Tríceps',
  'quads': 'Cuádriceps',
  'hamstrings': 'Isquios',
  'glutes': 'Glúteos',
  'calves': 'Gemelos',
  'abs': 'Abdomen',
};

class TrainingProfile {
  final Sex sex;
  final int? age;
  final double? bodyweightKg;
  final int daysPerWeek; // 2..6
  final int sessionMinutes; // 30..90
  final Set<String> injuries; // claves de kInjuryLabels
  final Set<String> priorities; // claves de kMuscleGroupLabels
  final int mesocycleWeeks; // 4..6 (la última es descarga)

  const TrainingProfile({
    this.sex = Sex.unspecified,
    this.age,
    this.bodyweightKg,
    this.daysPerWeek = 4,
    this.sessionMinutes = 50,
    this.injuries = const {},
    this.priorities = const {},
    this.mesocycleWeeks = 5,
  });

  TrainingProfile copyWith({
    Sex? sex,
    int? age,
    double? bodyweightKg,
    int? daysPerWeek,
    int? sessionMinutes,
    Set<String>? injuries,
    Set<String>? priorities,
    int? mesocycleWeeks,
  }) =>
      TrainingProfile(
        sex: sex ?? this.sex,
        age: age ?? this.age,
        bodyweightKg: bodyweightKg ?? this.bodyweightKg,
        daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        injuries: injuries ?? this.injuries,
        priorities: priorities ?? this.priorities,
        mesocycleWeeks: mesocycleWeeks ?? this.mesocycleWeeks,
      );

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'bodyweight_kg': bodyweightKg,
        'days_per_week': daysPerWeek,
        'session_minutes': sessionMinutes,
        'injuries': injuries.toList(),
        'priorities': priorities.toList(),
        'mesocycle_weeks': mesocycleWeeks,
      };

  factory TrainingProfile.fromJson(Map<String, dynamic> j) => TrainingProfile(
        sex: Sex.values.firstWhere((s) => s.name == j['sex'],
            orElse: () => Sex.unspecified),
        age: j['age'] as int?,
        bodyweightKg: (j['bodyweight_kg'] as num?)?.toDouble(),
        daysPerWeek: (j['days_per_week'] as int? ?? 4).clamp(2, 6),
        sessionMinutes: (j['session_minutes'] as int? ?? 50).clamp(25, 120),
        injuries: ((j['injuries'] as List?)?.cast<String>() ?? const []).toSet(),
        priorities:
            ((j['priorities'] as List?)?.cast<String>() ?? const []).toSet(),
        mesocycleWeeks: (j['mesocycle_weeks'] as int? ?? 5).clamp(3, 8),
      );

  String encode() => jsonEncode(toJson());

  static TrainingProfile decode(String? raw) {
    if (raw == null || raw.isEmpty) return const TrainingProfile();
    try {
      return TrainingProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TrainingProfile();
    }
  }
}
