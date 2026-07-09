// Sesión de entrenamiento (registro de una visita al gym)
class WorkoutSession {
  final String id;
  final String routineId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? perceivedExertion; // RPE global de la sesión 1-10
  final String? notes;
  final int? totalSets; // calculable
  final double? totalVolume; // kg*reps acumulado

  const WorkoutSession({
    required this.id,
    required this.routineId,
    required this.startedAt,
    this.finishedAt,
    this.perceivedExertion,
    this.notes,
    this.totalSets,
    this.totalVolume,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> m) => WorkoutSession(
    id: m['id'] as String,
    routineId: m['routine_id'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
    finishedAt: m['finished_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['finished_at'] as int)
        : null,
    perceivedExertion: m['perceived_exertion'] as int?,
    notes: m['notes'] as String?,
    totalSets: m['total_sets'] as int?,
    totalVolume: m['total_volume'] as double?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'routine_id': routineId,
    'started_at': startedAt.millisecondsSinceEpoch,
    'finished_at': finishedAt?.millisecondsSinceEpoch,
    'perceived_exertion': perceivedExertion,
    'notes': notes,
    'total_sets': totalSets,
    'total_volume': totalVolume,
  };

  Duration? get duration =>
      finishedAt == null ? null : finishedAt!.difference(startedAt);

  bool get isActive => finishedAt == null;
}
