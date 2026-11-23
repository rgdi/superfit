// Estado de cada músculo: series semanales y recuperación estimada.
//
// - Series semanales: músculo principal = 1 serie, secundario = 0,5
//   ("series fraccionales"; Pelland 2026, PMID 41343037, encontró que este
//   recuento predice mejor la hipertrofia que contar solo las directas).
// - Recuperación: ESTIMACIÓN orientativa. Cada serie deja una "fatiga" que
//   decae exponencialmente (vida media ~24-30 h). No mide daño muscular real.
import 'dart:math' as math;
import '../../data/models/exercise.dart';
import '../../data/models/set_log.dart';
import '../../data/models/user_settings.dart';

/// Músculos pequeños o muy trabajados de forma indirecta: objetivo menor.
const Set<String> kSmallMuscles = {
  'brachialis', 'trapezius_upper', 'obliques', 'rhomboids', 'soleus',
  'gluteus_medius', 'adductors', 'erector_spinae', 'deltoid_anterior',
};

class MuscleStat {
  final String id;
  final double weeklySets; // últimos 7 días (fraccional)
  final double target; // series/semana orientativas
  final DateTime? lastTrained;
  final double recovery; // 0 = muy fatigado, 1 = recuperado
  final Map<String, double> byExercise; // ejercicio → series aportadas (7 d)

  const MuscleStat({
    required this.id,
    required this.weeklySets,
    required this.target,
    required this.lastTrained,
    required this.recovery,
    required this.byExercise,
  });

  /// 0 = nada, 1 = en objetivo, >1 = por encima
  double get ratio => target <= 0 ? 0 : weeklySets / target;

  /// Lumbares, oblicuos, trapecio superior: no exigen series directas.
  bool get optional => kMinorMuscles.contains(id);

  String get status {
    if (optional && ratio < 0.9) return 'Opcional';
    if (weeklySets < 0.5) return 'Sin trabajar';
    if (ratio < 0.5) return 'Poco volumen';
    if (ratio < 0.9) return 'Casi en objetivo';
    if (ratio <= 1.5) return 'En objetivo';
    return 'Mucho volumen';
  }
}

/// Grupo de planificación (prioridades del perfil) al que pertenece un músculo.
String muscleGroupOf(String m) {
  if (m.startsWith('pectoralis')) return 'chest';
  if (m.startsWith('latissimus') || m == 'rhomboids' || m.startsWith('trapezius') || m == 'erector_spinae') return 'back';
  if (m.startsWith('deltoid')) return 'shoulders';
  if (m == 'biceps_brachii' || m == 'brachialis') return 'biceps';
  if (m.startsWith('triceps')) return 'triceps';
  if (m == 'quadriceps') return 'quads';
  if (m == 'hamstrings') return 'hamstrings';
  if (m.startsWith('gluteus') || m == 'adductors') return 'glutes';
  if (m == 'gastrocnemius' || m == 'soleus') return 'calves';
  return 'abs';
}

/// Objetivo semanal ÚNICO (lo usan el generador y el mapa muscular), en
/// series fraccionales (principal 1, secundario 0,5).
double muscleWeeklyTarget(String m, UserLevel level,
    {UserGoal goal = UserGoal.hypertrophy, Set<String> priorities = const {}}) {
  var t = weeklyTargetFor(m, level);
  t *= switch (goal) {
    UserGoal.maintenance => 1 / 3, // Bickel 2011: ~1/3 del volumen mantiene
    UserGoal.strength => 0.8, // menos volumen, más intensidad
    _ => 1.0,
  };
  if (priorities.contains(muscleGroupOf(m))) t *= 1.35;
  return t < 2 ? 2 : t;
}

/// Músculos que reciben mucho trabajo indirecto y rara vez necesitan series
/// directas en un programa general (lumbares, oblicuos, trapecio superior).
const Set<String> kMinorMuscles = {'erector_spinae', 'obliques', 'trapezius_upper'};

double weeklyTargetFor(String muscle, UserLevel level) {
  final base = switch (level) {
    UserLevel.beginner => 8.0,
    UserLevel.intermediate => 12.0,
    UserLevel.advanced => 16.0,
  };
  if (kMinorMuscles.contains(muscle)) return base * 0.35;
  return kSmallMuscles.contains(muscle) ? base * 0.6 : base;
}

Map<String, MuscleStat> computeMuscleStats({
  required List<SetLog> sets,
  required Map<String, Exercise> catalog,
  required Iterable<String> muscleIds,
  required UserLevel level,
  UserGoal goal = UserGoal.hypertrophy,
  Set<String> priorities = const {},
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final weekAgo = t.subtract(const Duration(days: 7));
  final weekly = <String, double>{};
  final byEx = <String, Map<String, double>>{};
  final last = <String, DateTime>{};
  final fatigue = <String, double>{};
  for (final s in sets) {
    if (!s.completed || s.isWarmup || s.performedAt.isAfter(t)) continue;
    final ex = catalog[s.exerciseId];
    if (ex == null) continue;
    final hours = t.difference(s.performedAt).inMinutes / 60.0;
    void add(String m, double w) {
      if (!s.performedAt.isBefore(weekAgo)) {
        weekly[m] = (weekly[m] ?? 0) + w;
        final e = byEx.putIfAbsent(m, () => {});
        e[ex.id] = (e[ex.id] ?? 0) + w;
      }
      final prev = last[m];
      if (prev == null || s.performedAt.isAfter(prev)) last[m] = s.performedAt;
      final halfLife = kSmallMuscles.contains(m) ? 20.0 : 28.0;
      // Series cerca del fallo fatigan más
      final rpeFactor = s.rpe == null ? 1.0 : (0.6 + 0.4 * ((s.rpe! - 5).clamp(0, 5) / 5));
      fatigue[m] = (fatigue[m] ?? 0) + w * rpeFactor * math.pow(0.5, hours / halfLife);
    }

    for (final m in ex.primaryMuscles) {
      add(m, 1);
    }
    for (final m in ex.secondaryMuscles) {
      add(m, 0.5);
    }
  }
  return {
    for (final m in muscleIds)
      m: MuscleStat(
        id: m,
        weeklySets: weekly[m] ?? 0,
        target: muscleWeeklyTarget(m, level, goal: goal, priorities: priorities),
        lastTrained: last[m],
        // ~6 series duras recientes ≈ 0 % recuperado
        recovery: (1 - (fatigue[m] ?? 0) / 6).clamp(0.0, 1.0),
        byExercise: byEx[m] ?? const {},
      ),
  };
}
