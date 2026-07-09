// Recomendación de rutina del día basada en plan + adherencia
import '../../data/models/routine.dart';
import '../../data/repositories/session_repo.dart';
import 'cycle_planner.dart';

class RoutineRecommendation {
  final Routine? routine;
  final String? reason;
  final bool shouldRest;

  const RoutineRecommendation({this.routine, this.reason, this.shouldRest = false});
}

class RoutineRecommender {
  final CyclePlanner planner;
  final SessionRepo sessionRepo;

  RoutineRecommender(this.planner, this.sessionRepo);

  Future<RoutineRecommendation> recommendForToday(List<Routine> allRoutines) async {
    final today = DateTime.now();
    final planned = planner.sessionFor(today);

    if (planned == null) {
      return const RoutineRecommendation(
        routine: null,
        reason: 'Plan no iniciado. Configura tu plan en ajustes.',
      );
    }

    // Chequear si entrenó ayer mismo grupo → sugerir descanso
    final yesterdaySessions = await sessionRepo.sessionsInRange(
      today.subtract(const Duration(days: 1)),
      today,
    );
    if (yesterdaySessions.isNotEmpty) {
      // revisar si misma rutina
      final sameRoutine = yesterdaySessions.any((s) => s.routineId == planned.routineId);
      if (sameRoutine && !planner.isDeloadWeek(today)) {
        return const RoutineRecommendation(
          routine: null,
          reason: 'Ayer hiciste esta misma rutina. Descansa hoy para recuperar.',
          shouldRest: true,
        );
      }
    }

    // Si deload: usar la rutina deload
    if (planner.isDeloadWeek(today)) {
      final deload = allRoutines.firstWhere(
        (r) => r.id == 'deload',
        orElse: () => allRoutines.first,
      );
      return RoutineRecommendation(
        routine: deload,
        reason: 'Semana 4: deload. Reduce 50% volumen, RPE 6-7.',
      );
    }

    final planned_routine = allRoutines.firstWhere(
      (r) => r.id == planned.routineId,
      orElse: () => allRoutines.first,
    );
    return RoutineRecommendation(
      routine: planned_routine,
      reason: 'Plan semana ${planned.weekIndex}: ${planned.nameEs}',
    );
  }
}
