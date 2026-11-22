// Item de workout (un ejercicio en una rutina)
class WorkoutItem {
  final String exerciseId;
  final int sets;
  final String repsTarget;
  final int rpeTarget;
  final int restSeconds;
  final String tempo;
  final String? notesEs;
  final String? notesEn;
  final String? supersetWith;

  const WorkoutItem({
    required this.exerciseId,
    required this.sets,
    required this.repsTarget,
    required this.rpeTarget,
    required this.restSeconds,
    required this.tempo,
    this.notesEs,
    this.notesEn,
    this.supersetWith,
  });

  factory WorkoutItem.fromJson(Map<String, dynamic> j) => WorkoutItem(
    exerciseId: j['exercise_id'] as String,
    sets: j['sets'] as int,
    repsTarget: j['reps_target'] as String,
    rpeTarget: j['rpe_target'] as int,
    restSeconds: j['rest_seconds'] as int,
    tempo: j['tempo'] as String? ?? '2-1-2-0',
    notesEs: j['notes_es'] as String?,
    notesEn: j['notes_en'] as String?,
    supersetWith: j['superset_with'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'sets': sets,
    'reps_target': repsTarget,
    'rpe_target': rpeTarget,
    'rest_seconds': restSeconds,
    'tempo': tempo,
    'notes_es': notesEs,
    'notes_en': notesEn,
    'superset_with': supersetWith,
  };

  WorkoutItem copyWith({String? exerciseId, int? sets, int? rpeTarget, String? notesEs}) => WorkoutItem(
    exerciseId: exerciseId ?? this.exerciseId,
    sets: sets ?? this.sets,
    repsTarget: repsTarget,
    rpeTarget: rpeTarget ?? this.rpeTarget,
    restSeconds: restSeconds,
    tempo: tempo,
    notesEs: notesEs ?? this.notesEs,
    notesEn: notesEn,
    supersetWith: supersetWith,
  );

  /// (min, max) del rango de reps "8-12" → (8, 12); "10" → (10, 10)
  (int, int) get repRange {
    final parts = repsTarget.split('-').map((p) => int.tryParse(p.trim())).toList();
    final lo = parts.isNotEmpty ? parts.first ?? 8 : 8;
    final hi = parts.length > 1 ? parts[1] ?? lo : lo;
    return (lo, hi < lo ? lo : hi);
  }

  String? localizedNotes(String locale) =>
      locale == 'en' ? notesEn : notesEs;
}
