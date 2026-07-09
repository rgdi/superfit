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

  String? localizedNotes(String locale) =>
      locale == 'en' ? notesEn : notesEs;
}
