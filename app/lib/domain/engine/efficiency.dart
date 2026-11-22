// "Mínimo esfuerzo, máximo estímulo": el menor conjunto de ejercicios, con
// TUS máquinas, que trabaja todos los músculos.
//
// Importante: no optimizamos "activación" (EMG). La amplitud EMG no predice
// bien la hipertrofia (Vigotsky 2017, PMID 29354060). Optimizamos cobertura
// muscular (principal = 1, secundario = 0,5) por unidad de esfuerzo
// (cada ejercicio cuesta tiempo/ajuste; los multiarticulares y los que cargan
// la columna fatigan más), con un pequeño extra para variantes que entrenan
// el músculo estirado, que es lo que sí tiene respaldo:
//   · curl femoral sentado > tumbado (Maeo 2021, PMID 33009197)
//   · extensión de tríceps por encima de la cabeza > neutra (Maeo 2023, PMID 35819335)
//   · extensión de cuádriceps con énfasis en rodilla flexionada (Pedrosa 2022, PMID 33977835)
//   · gemelo con énfasis en el estiramiento (Kassiano 2023, PMID 37015016)
import '../../data/models/exercise.dart';
import 'muscle_stats.dart' show kSmallMuscles;

class EfficientPick {
  final Exercise exercise;
  final List<String> covers; // músculos que pasa a cubrir (principales)
  final List<String> helps; // músculos que refuerza (secundarios)
  final String why;
  final String? tip; // cómo sacarle más (músculo estirado...)
  const EfficientPick(this.exercise, this.covers, this.helps, this.why, this.tip);
}

class EfficientPlan {
  final List<EfficientPick> picks;
  final Set<String> uncovered; // músculos que no trabaja nada (0)
  final Map<String, double> coverage; // músculo → 0..1
  const EfficientPlan(this.picks, this.uncovered, this.coverage);

  /// Trabajados solo de forma indirecta (0 < cobertura < 1)
  Set<String> get partial => coverage.entries.where((e) => e.value > 0 && e.value < 1).map((e) => e.key).toSet();

  /// Minutos con 2 series por ejercicio (≈ 40 s + 90 s descanso) + 1 min de ajuste.
  int get minutes => (picks.length * (2 * 130 + 60) / 60).round() + 5;
}

/// Consejos con respaldo para entrenar el músculo en posición estirada.
const Map<String, String> kLengthTips = {
  'leg_curl': 'Si hay curl femoral SENTADO, mejor que tumbado: con la cadera flexionada el isquio crece más (Maeo 2021).',
  'leg_extension': 'Controla la parte baja (rodilla doblada): ahí está el estímulo extra (Pedrosa 2022).',
  'standing_calf_raise': 'Baja del todo y pausa 1-2 s abajo, estirado (Kassiano 2023).',
  'seated_calf_raise': 'Baja del todo y pausa abajo; este trabaja sobre todo el sóleo.',
  'cable_tricep_pushdown': 'Alterna con extensión por encima de la cabeza en polea: crece más la porción larga (Maeo 2023).',
  'arm_extension_machine': 'Si puedes, hazlo con el brazo por encima de la cabeza (Maeo 2023).',
  'pec_deck': 'Abre hasta notar estiramiento en el pecho, sin dolor de hombro.',
  'lat_pulldown': 'Deja subir la barra hasta estirar del todo el dorsal en cada rep.',
  'cable_pullover': 'Empieza con los brazos bien arriba para estirar el dorsal.',
};

const Set<String> _spineLoaded = {'hack_squat', 'back_extension', 'standing_calf_raise'};
const Set<String> _lengthBiased = {'leg_curl', 'standing_calf_raise', 'seated_calf_raise', 'cable_pullover', 'pec_deck'};

double effortCost(Exercise e) {
  var c = 1.0; // tiempo, ajuste de máquina, una "estación" más
  if (e.category == 'compound') c += 0.25; // más fatiga sistémica
  if (_spineLoaded.contains(e.id)) c += 0.3;
  return c;
}

const Set<String> _mediumMuscles = {
  'deltoid_lateral', 'deltoid_posterior', 'biceps_brachii', 'triceps_long', 'triceps_lateral',
  'trapezius_middle', 'rectus_abdominis', 'gastrocnemius',
};

/// Prioridad por tamaño: grandes 1 · medianos 0,8 · pequeños 0,6
double muscleWeight(String m) => kSmallMuscles.contains(m) ? 0.6 : (_mediumMuscles.contains(m) ? 0.8 : 1.0);

EfficientPlan planMinimalCircuit({
  required List<Exercise> catalog,
  required Iterable<String> muscleIds,
  Set<String>? availableTypes, // null = todas las máquinas
  Set<String> exclude = const {}, // ejercicios a evitar (molestias)
  bool essential = false, // true = solo lo que más rinde (grupos grandes)
  int? maxExercises,
}) {
  final maxN = maxExercises ?? (essential ? 6 : 12);
  // Esencial: solo añade un ejercicio si aporta mucho (≈ un músculo grande entero)
  final minGain = essential ? 0.6 : 0.35;
  double w(String m) => essential ? muscleWeight(m) * muscleWeight(m) : muscleWeight(m);
  final muscles = muscleIds.toSet();
  final cands = catalog
      .where((e) => !exclude.contains(e.id) && (availableTypes == null || e.usableWith(availableTypes)))
      .toList();
  final cov = {for (final m in muscles) m: 0.0};
  final picks = <Exercise>[];

  double gainOf(Exercise e) {
    var g = 0.0;
    final bonus = _lengthBiased.contains(e.id) ? 1.15 : 1.0;
    void add(String m, double amount) {
      if (!cov.containsKey(m)) return;
      final now = cov[m]!;
      g += w(m) * ((now + amount).clamp(0, 1) - now);
    }

    for (final m in e.primaryMuscles) {
      add(m, 1.0 * bonus);
    }
    for (final m in e.secondaryMuscles) {
      add(m, 0.5);
    }
    return g / effortCost(e);
  }

  while (picks.length < maxN) {
    Exercise? best;
    var bestGain = 0.0;
    for (final e in cands) {
      if (picks.contains(e)) continue;
      final g = gainOf(e);
      if (g > bestGain + 1e-9 || (best != null && (g - bestGain).abs() < 1e-9 && e.id.compareTo(best.id) < 0)) {
        bestGain = g;
        best = e;
      }
    }
    // Parar si ya no aporta casi nada (p. ej. solo un 0,5 de un músculo pequeño)
    if (best == null || bestGain < minGain) break;
    picks.add(best);
    for (final m in best.primaryMuscles) {
      if (cov.containsKey(m)) cov[m] = 1.0;
    }
    for (final m in best.secondaryMuscles) {
      if (cov.containsKey(m)) cov[m] = (cov[m]! + 0.5).clamp(0, 1);
    }
  }

  // Poda: quita ejercicios redundantes (los demás ya cubren sus músculos)
  Map<String, double> coverageOf(List<Exercise> list) {
    final c = {for (final m in muscles) m: 0.0};
    for (final e in list) {
      for (final m in e.primaryMuscles) {
        if (c.containsKey(m)) c[m] = 1.0;
      }
      for (final m in e.secondaryMuscles) {
        if (c.containsKey(m)) c[m] = (c[m]! + 0.5).clamp(0, 1);
      }
    }
    return c;
  }

  double total(Map<String, double> c) => c.entries.fold(0.0, (a, e) => a + muscleWeight(e.key) * e.value);
  var changed = true;
  while (changed) {
    changed = false;
    final full = total(coverageOf(picks));
    for (final e in List.of(picks.reversed)) {
      final without = List.of(picks)..remove(e);
      if (total(coverageOf(without)) >= full - 1e-9) {
        picks.remove(e);
        changed = true;
        break;
      }
    }
  }

  // Explicación por ejercicio, en orden (multiarticulares primero)
  picks.sort((a, b) => (a.category == 'compound' ? 0 : 1).compareTo(b.category == 'compound' ? 0 : 1));
  final seen = <String>{};
  final out = <EfficientPick>[];
  for (final e in picks) {
    final covers = e.primaryMuscles.where((m) => muscles.contains(m) && !seen.contains(m)).toList();
    final helps = e.secondaryMuscles.where(muscles.contains).toList();
    seen.addAll(e.primaryMuscles);
    final n = e.primaryMuscles.length + e.secondaryMuscles.length;
    final why = e.category == 'compound'
        ? 'Multiarticular: trabaja $n músculos a la vez.'
        : 'Cubre lo que los multiarticulares no llegan a trabajar.';
    out.add(EfficientPick(e, covers, helps, why, kLengthTips[e.id]));
  }
  final finalCov = coverageOf(picks);
  return EfficientPlan(out, finalCov.entries.where((e) => e.value <= 0).map((e) => e.key).toSet(), finalCov);
}
