// Convierte tu historial (SQLite + "¿cómo llegas hoy?") en datos de
// entrenamiento y entrena el modelo local.
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/exercise.dart';
import '../../data/models/set_log.dart';
import '../../data/repositories/set_repo.dart';
import 'performance_model.dart';

const kReadinessPrefix = 'readiness_';

int readinessValue(String? name) => switch (name) {
      'low' => -1,
      'high' => 1,
      _ => 0,
    };

class AiService {
  /// Pasa las series a observaciones (descarta aproximaciones).
  static List<TrainingObs> toObservations(
    List<SetLog> sets,
    Map<String, Exercise> catalog,
    Map<String, int> readinessBySession,
  ) {
    final out = <TrainingObs>[];
    final groups = groupBy<SetLog, String>(
        sets.where((s) => s.completed && !s.isWarmup), (s) => '${s.sessionId}|${s.exerciseId}');
    for (final g in groups.values) {
      g.sort((a, b) => a.performedAt.compareTo(b.performedAt));
      var idx = 0;
      for (final s in g) {
        final ex = catalog[s.exerciseId];
        out.add(TrainingObs(
          exerciseId: s.exerciseId,
          machineId: s.machineId,
          compound: ex?.category == 'compound',
          sessionId: s.sessionId,
          at: s.performedAt,
          weight: s.weight,
          reps: s.reps,
          rpe: s.rpe,
          setIndex: idx,
          readiness: readinessBySession[s.sessionId] ?? 0,
          isDrop: s.technique == 'drop',
        ));
        if (s.technique != 'drop') idx++;
      }
    }
    return out;
  }

  static Future<PerformanceModel> train(SetRepo repo, List<Exercise> exercises) async {
    final sets = await repo.allCompleted();
    final prefs = await SharedPreferences.getInstance();
    final readiness = <String, int>{
      for (final id in sets.map((s) => s.sessionId).toSet())
        id: readinessValue(prefs.getString('$kReadinessPrefix$id')),
    };
    return PerformanceModel.fit(toObservations(sets, {for (final e in exercises) e.id: e}, readiness));
  }
}
