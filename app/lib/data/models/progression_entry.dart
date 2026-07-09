// Modelo del historial de progresión de un ejercicio (para detección de mesetas)
class ProgressionEntry {
  final String exerciseId;
  final double weight;
  final int reps;
  final int rpe;
  final DateTime date;

  const ProgressionEntry({
    required this.exerciseId,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.date,
  });
}
