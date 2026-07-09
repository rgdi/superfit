// Set individual registrado
class SetLog {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final int? rpe;
  final int? restTakenSeconds;
  final String? tempoNotes;
  final bool completed;
  final DateTime performedAt;
  final String? technique; // rest_pause | drop_set | myo_reps | null

  const SetLog({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.restTakenSeconds,
    this.tempoNotes,
    required this.completed,
    required this.performedAt,
    this.technique,
  });

  factory SetLog.fromMap(Map<String, dynamic> m) => SetLog(
    id: m['id'] as String,
    sessionId: m['session_id'] as String,
    exerciseId: m['exercise_id'] as String,
    setNumber: m['set_number'] as int,
    weight: (m['weight'] as num).toDouble(),
    reps: m['reps'] as int,
    rpe: m['rpe'] as int?,
    restTakenSeconds: m['rest_taken_seconds'] as int?,
    tempoNotes: m['tempo_notes'] as String?,
    completed: (m['completed'] as int) == 1,
    performedAt: DateTime.fromMillisecondsSinceEpoch(m['performed_at'] as int),
    technique: m['technique'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'set_number': setNumber,
    'weight': weight,
    'reps': reps,
    'rpe': rpe,
    'rest_taken_seconds': restTakenSeconds,
    'tempo_notes': tempoNotes,
    'completed': completed ? 1 : 0,
    'performed_at': performedAt.millisecondsSinceEpoch,
    'technique': technique,
  };

  double get volume => weight * reps;
  bool get isEffective {
    if (!completed) return false;
    if (rpe == null) return true; // si no reportó RPE, asumimos
    return rpe! >= 7;
  }
}
