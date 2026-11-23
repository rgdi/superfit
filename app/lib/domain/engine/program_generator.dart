// Generador de programa v2 — asignación de volumen POR MÚSCULO.
//
// v1 planificaba por grandes grupos con plantillas fijas y recortaba a ciegas
// para caber en el tiempo. La auditoría (180 perfiles) mostró que dejaba a
// cero aductores, deltoide posterior, abdomen… en la mitad de los casos,
// con un ratio empuje:tirón de hasta 8:1. v2 lo resuelve como un problema de
// optimización:
//
//  1. Objetivo semanal por músculo = el MISMO que usa el mapa muscular
//     (muscleWeeklyTarget: nivel, objetivo, prioridades), en series
//     fraccionales (principal 1, secundario 0,5; Pelland 2026, PMID 41343037).
//  2. Cada sesión tiene músculos "elegibles" según el split (torso, pierna,
//     empuje, tirón, cuerpo completo).
//  3. Asignación voraz: en cada paso se añade la serie (o el ejercicio nuevo,
//     con 2 series) que más reduce el déficit ponderado POR MINUTO, con:
//       · tope de ~10 series por músculo y sesión (más rinde poco),
//       · bonificación por repartir cada músculo en ≥2 sesiones/semana
//         (Schoenfeld 2016, PMID 27102172),
//       · rendimiento decreciente al pasar del objetivo,
//       · solo máquinas del usuario y sin contraindicaciones.
//  4. Se para al agotar los minutos de la sesión o cuando ya no compensa.
//
// Descansos ≥2 min en multiarticulares (Schoenfeld 2016, PMID 26605807).
import 'dart:math' as math;
import '../../data/models/exercise.dart';
import '../../data/models/generated_program.dart';
import '../../data/models/routine.dart';
import '../../data/models/training_profile.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/workout_item.dart';
import 'efficiency.dart' show kLengthTips, muscleWeight;
import 'muscle_stats.dart';

/// Grupo de planificación de un ejercicio (para sustituciones en el entreno).
String groupOf(Exercise e) {
  switch (e.id) {
    case 'back_extension':
      return 'hamstrings';
    case 'face_pull':
    case 'reverse_pec_deck':
      return 'shoulders';
  }
  final m = e.primaryMuscles.isEmpty ? '' : e.primaryMuscles.first;
  if (m.startsWith('pectoralis')) return 'chest';
  if (m.startsWith('latissimus') || m.startsWith('rhomboid') || m.startsWith('trapezius')) return 'back';
  if (m.startsWith('deltoid')) return 'shoulders';
  if (m.startsWith('biceps') || m == 'brachialis') return 'biceps';
  if (m.startsWith('triceps')) return 'triceps';
  if (m == 'quadriceps') return 'quads';
  if (m == 'hamstrings' || m == 'erector_spinae') return 'hamstrings';
  if (m.startsWith('gluteus') || m == 'adductors') return 'glutes';
  if (m == 'gastrocnemius' || m == 'soleus') return 'calves';
  if (m == 'rectus_abdominis' || m == 'obliques') return 'abs';
  return 'other';
}

/// Lesión → prefijos de contraindicación que excluye.
const Map<String, List<String>> _injuryContra = {
  'shoulder': ['shoulder'],
  'knee': ['knee', 'patellar'],
  'lower_back': ['lower_back', 'disc'],
  'elbow': ['elbow'],
  'hip': ['hip'],
  'neck': ['cervical'],
  'achilles': ['achilles'],
};

/// ¿Excluir este ejercicio por las molestias del usuario? (las contraindicaciones
/// marcadas solo para casos "_severe" se permiten con precaución)
bool contraindicatedFor(Exercise e, Set<String> injuries) => e.contraindications.any((c) =>
    !c.endsWith('_severe') && injuries.any((inj) => (_injuryContra[inj] ?? [inj]).any(c.startsWith)));

// ---------------------------------------------------------------- sesiones

const Set<String> _upperM = {
  'pectoralis_major_clavicular', 'pectoralis_major_sternal', 'deltoid_anterior', 'deltoid_lateral',
  'deltoid_posterior', 'biceps_brachii', 'brachialis', 'triceps_long', 'triceps_lateral', 'latissimus_dorsi',
  'trapezius_upper', 'trapezius_middle', 'rhomboids',
};
const Set<String> _lowerM = {
  'quadriceps', 'hamstrings', 'gluteus_maximus', 'gluteus_medius', 'adductors', 'gastrocnemius', 'soleus',
  'erector_spinae', 'rectus_abdominis', 'obliques',
};
const Set<String> _pushM = {
  'pectoralis_major_clavicular', 'pectoralis_major_sternal', 'deltoid_anterior', 'deltoid_lateral',
  'triceps_long', 'triceps_lateral',
};
const Set<String> _pullM = {
  'latissimus_dorsi', 'trapezius_upper', 'trapezius_middle', 'rhomboids', 'deltoid_posterior',
  'biceps_brachii', 'brachialis', 'rectus_abdominis', 'obliques',
};

class _SessionType {
  final String nameEs, nameEn;
  final Set<String> muscles;
  /// Patrones básicos que la sesión DEBE incluir (músculo principal), en orden.
  final List<String> core;
  const _SessionType(this.nameEs, this.nameEn, this.muscles, this.core);
}

const _full = _SessionType('Cuerpo completo', 'Full body', {..._upperM, ..._lowerM},
    ['quadriceps', 'pectoralis_major_sternal', 'latissimus_dorsi', 'hamstrings', 'deltoid_lateral']);
const _upper = _SessionType('Torso', 'Upper', _upperM,
    ['pectoralis_major_sternal', 'latissimus_dorsi', 'deltoid_lateral', 'trapezius_middle', 'deltoid_posterior']);
const _lower = _SessionType('Pierna', 'Lower', _lowerM,
    ['quadriceps', 'hamstrings', 'gluteus_maximus', 'gastrocnemius', 'rectus_abdominis']);
const _push = _SessionType('Empuje', 'Push', _pushM,
    ['pectoralis_major_sternal', 'deltoid_lateral', 'triceps_long']);
const _pull = _SessionType('Tirón', 'Pull', _pullM,
    ['latissimus_dorsi', 'trapezius_middle', 'deltoid_posterior', 'biceps_brachii']);

/// Días recomendados (1 = lunes) para repartir la recuperación.
const Map<int, List<int>> kScheduleDays = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
};

class _Item {
  final Exercise ex;
  int sets;
  _Item(this.ex, this.sets);
}

class ProgramGenerator {
  final List<Exercise> catalog;
  final Set<String>? availableTypes; // null = no ha configurado máquinas
  final TrainingProfile profile;
  final UserLevel level;
  final UserGoal goal;

  ProgramGenerator({
    required this.catalog,
    required this.availableTypes,
    required this.profile,
    required this.level,
    required this.goal,
  });

  static const int _warmupSec = 5 * 60;
  static const int _setupSec = 60; // cambiar/ajustar máquina
  static const int _workSec = 40; // duración de una serie
  static const double _sessionCap = 10; // series fraccionales por músculo y sesión
  static const int _maxSetsPerExercise = 5;

  GeneratedProgram generate({DateTime? now}) {
    final days = profile.daysPerWeek.clamp(2, 6);
    final (split, sessions) = _split(days);
    final why = <String>[];

    // --- Ejercicios utilizables
    final machineOk = catalog.where((e) => availableTypes == null || e.usableWith(availableTypes!)).toList();
    final usable = machineOk.where((e) => !contraindicatedFor(e, profile.injuries)).toList();
    final excluded = machineOk.where((e) => contraindicatedFor(e, profile.injuries)).toList();
    final cautious = usable.where((e) => _caution(e)).toList();

    // --- Objetivos por músculo (los mismos del mapa muscular)
    final muscles = {..._upperM, ..._lowerM};
    final target = {
      for (final m in muscles)
        m: muscleWeeklyTarget(m, level, goal: goal, priorities: profile.priorities),
    };
    double w(String m) => muscleWeight(m) * (profile.priorities.contains(muscleGroupOf(m)) ? 1.3 : 1.0);

    // --- Estado
    final plan = [for (final _ in sessions) <_Item>[]];
    final used = [for (final _ in sessions) 0.0]; // segundos
    final budget = profile.sessionMinutes * 60.0 - _warmupSec;
    final vol = {for (final m in muscles) m: 0.0};
    final sessVol = [for (final _ in sessions) {for (final m in muscles) m: 0.0}];
    final freq = {for (final m in muscles) m: 0};

    int rest(Exercise e) => _rest(e);
    double setCost(Exercise e) => (_workSec + rest(e)).toDouble();
    Iterable<(String, double)> contrib(Exercise e) sync* {
      for (final m in e.primaryMuscles) {
        if (muscles.contains(m)) yield (m, 1.0);
      }
      for (final m in e.secondaryMuscles) {
        if (muscles.contains(m)) yield (m, 0.5);
      }
    }

    // Valor de tener v series de un músculo: lineal hasta el objetivo,
    // después rendimiento decreciente (15 %) hasta 1,4× y 0 más allá.
    double value(String m, double v) {
      final t = target[m]!;
      if (v <= t) return v;
      if (v <= 1.4 * t) return t + 0.15 * (v - t);
      return t + 0.15 * 0.4 * t;
    }

    double gain(int s, Exercise e, int k) {
      var g = 0.0;
      final bonus = kLengthTips.containsKey(e.id) ? 1.08 : 1.0;
      for (final (m, c) in contrib(e)) {
        // tope por sesión
        final room = math.max(0.0, _sessionCap - sessVol[s][m]!);
        final add = math.min(room, c * k);
        if (add <= 0) continue;
        var dg = value(m, vol[m]! + add) - value(m, vol[m]!);
        // Frecuencia: premiar el primer estímulo del músculo en esta sesión
        // si aún no se trabaja 2 veces por semana
        if (sessVol[s][m]! == 0 && freq[m]! < 2 && sessions.length > 1) dg += 0.35 * c;
        g += w(m) * dg * bonus;
      }
      return g;
    }

    bool eligible(int s, Exercise e) =>
        e.primaryMuscles.isNotEmpty && e.primaryMuscles.every(sessions[s].muscles.contains);

    void apply(int s, Exercise e, int k) {
      for (final (m, c) in contrib(e)) {
        if (sessVol[s][m]! == 0) freq[m] = freq[m]! + 1;
        sessVol[s][m] = sessVol[s][m]! + c * k;
        vol[m] = vol[m]! + c * k;
      }
    }

    // --- Fase 1 (estructura): cada sesión incluye sus patrones básicos.
    // Sin esto, con poco tiempo el optimizador prefiere ejercicios de torso
    // (tocan más músculos) y podía dejar un "cuerpo completo" sin piernas.
    for (int s = 0; s < sessions.length; s++) {
      for (final m in sessions[s].core) {
        if (sessVol[s][m]! > 0) continue;
        Exercise? best;
        var bestSc = 0.0;
        for (final e in usable) {
          if (!eligible(s, e) || !e.primaryMuscles.contains(m) || plan[s].any((it) => it.ex.id == e.id)) continue;
          final cost = _setupSec + 2 * setCost(e);
          if (used[s] + cost > budget) continue;
          final twin = _twinHas(sessions, plan, s, e.id) ? 0.92 : 1.0;
          final sc = gain(s, e, 2) * twin / (cost / 60);
          if (sc > bestSc) {
            bestSc = sc;
            best = e;
          }
        }
        if (best == null) continue;
        plan[s].add(_Item(best, 2));
        used[s] += _setupSec + 2 * setCost(best);
        apply(s, best, 2);
      }
    }

    // --- Fase 2: asignación voraz
    for (var guard = 0; guard < 400; guard++) {
      double bestScore = 0;
      int? bs;
      Exercise? be;
      _Item? bItem;
      for (int s = 0; s < sessions.length; s++) {
        // Ampliar un ejercicio existente (+1 serie)
        for (final it in plan[s]) {
          if (it.sets >= _maxSetsPerExercise) continue;
          final cost = setCost(it.ex);
          if (used[s] + cost > budget) continue;
          final sc = gain(s, it.ex, 1) / (cost / 60);
          if (sc > bestScore + 1e-9) {
            bestScore = sc;
            bs = s;
            be = it.ex;
            bItem = it;
          }
        }
        // Añadir un ejercicio nuevo (2 series)
        for (final e in usable) {
          if (!eligible(s, e) || plan[s].any((it) => it.ex.id == e.id)) continue;
          final cost = _setupSec + 2 * setCost(e);
          if (used[s] + cost > budget) continue;
          // Variedad: ligera penalización si la sesión "gemela" ya lo usa
          final twin = _twinHas(sessions, plan, s, e.id) ? 0.92 : 1.0;
          final sc = gain(s, e, 2) * twin / (cost / 60);
          if (sc > bestScore + 1e-9) {
            bestScore = sc;
            bs = s;
            be = e;
            bItem = null;
          }
        }
      }
      if (bs == null || bestScore < 0.12) break; // ya no compensa
      if (bItem != null) {
        bItem.sets++;
        used[bs] += setCost(be!);
        apply(bs, be, 1);
      } else {
        plan[bs].add(_Item(be!, 2));
        used[bs] += _setupSec + 2 * setCost(be);
        apply(bs, be, 2);
      }
    }

    // --- Rutinas (multiarticulares primero; luego por tamaño de músculo)
    final routines = <Routine>[];
    for (int s = 0; s < sessions.length; s++) {
      final items = plan[s]..sort(_order);
      final workout = [for (final it in items) _item(it.ex, it.sets)];
      final suffix = _suffix(sessions, s);
      routines.add(Routine(
        id: 'gen_${s + 1}',
        nameEs: '${sessions[s].nameEs}$suffix',
        nameEn: '${sessions[s].nameEn}$suffix',
        dayOfWeek: kScheduleDays[days]![s % kScheduleDays[days]!.length],
        estimatedMinutes: estimateMinutes(workout),
        level: level.name,
        goal: goal.name,
        warmup: [
          WarmupItem(type: 'mobility', nameEs: '5 min de cardio suave (bici, elíptica…)', nameEn: '5 min easy cardio', durationSeconds: 300),
          WarmupItem(type: 'activation', nameEs: '1-2 series de aproximación del primer ejercicio', nameEn: '1-2 ramp-up sets', durationSeconds: 120),
        ],
        workout: workout,
        cooldown: const [],
      ));
    }

    // --- Resumen honesto, con cifras reales
    final inTarget = muscles.where((m) => vol[m]! >= 0.9 * target[m]!).length;
    final short = (muscles.where((m) => vol[m]! < 0.6 * target[m]!).toList()
          ..sort((a, b) => (vol[a]! / target[a]!).compareTo(vol[b]! / target[b]!)))
        .toList();
    final zero = muscles.where((m) => vol[m] == 0).toList();
    final twice = muscles.where((m) => freq[m]! >= 2).length;
    const dayNames = ['', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    why.add('$days días/semana → $split. Días sugeridos: '
        '${kScheduleDays[days]!.map((d) => dayNames[d]).join(', ')}.');
    why.add('$inTarget de ${muscles.length} músculos llegan a su objetivo semanal; '
        '$twice se trabajan al menos 2 veces por semana.');
    if (short.isNotEmpty) {
      final reason = availableTypes != null || profile.injuries.isNotEmpty
          ? 'por tiempo, máquinas disponibles o molestias'
          : 'por el tiempo por sesión';
      why.add('Por debajo de objetivo ($reason): ${short.take(5).map(_muscleEs).join(', ')}.');
    }
    if (zero.isNotEmpty && availableTypes != null) {
      why.add('Sin ninguna máquina para: ${zero.map(_muscleEs).join(', ')}. Añádelas en Mis máquinas si las hay.');
    }
    if (excluded.isNotEmpty) {
      why.add('Excluidos por molestias: ${excluded.map((e) => e.nameEs).join(', ')}.');
    }
    if (cautious.isNotEmpty) {
      why.add('Con precaución (rango sin dolor): ${cautious.map((e) => e.nameEs).join(', ')}.');
    }
    if (profile.priorities.isNotEmpty) {
      why.add('Prioridad: ${profile.priorities.map((p) => kMuscleGroupLabels[p]).join(', ')} (+35 % de volumen objetivo).');
    }
    why.add('Mesociclo de ${profile.mesocycleWeeks} semanas: el esfuerzo sube semana a semana y la última es de descarga.');

    // Series directas por grupo (para mostrar)
    final weekly = <String, int>{};
    for (final r in routines) {
      for (final it in r.workout) {
        final e = catalog.firstWhere((x) => x.id == it.exerciseId);
        final groups = e.primaryMuscles.map(muscleGroupOf).toSet();
        for (final g in groups) {
          weekly[g] = (weekly[g] ?? 0) + it.sets;
        }
      }
    }

    final start = now ?? DateTime.now();
    return GeneratedProgram(
      createdAt: start,
      startDate: DateTime(start.year, start.month, start.day),
      splitName: split,
      routines: routines,
      rotation: routines.map((r) => r.id).toList(),
      mesocycleWeeks: profile.mesocycleWeeks,
      rationale: why,
      weeklySets: weekly,
    );
  }

  // ---------------------------------------------------------------- ayudas

  (String, List<_SessionType>) _split(int days) => switch (days) {
        2 => ('Cuerpo completo A/B', const [_full, _full]),
        3 => ('Cuerpo completo A/B/C', const [_full, _full, _full]),
        4 => ('Torso / Pierna', const [_upper, _lower, _upper, _lower]),
        5 => ('Torso / Pierna + Empuje / Tirón / Pierna', const [_upper, _lower, _push, _pull, _lower]),
        _ => ('Empuje / Tirón / Pierna ×2', const [_push, _pull, _lower, _push, _pull, _lower]),
      };

  bool _twinHas(List<_SessionType> ss, List<List<_Item>> plan, int s, String id) {
    for (int i = 0; i < ss.length; i++) {
      if (i != s && identical(ss[i], ss[s]) && plan[i].any((it) => it.ex.id == id)) return true;
    }
    return false;
  }

  String _suffix(List<_SessionType> ss, int s) {
    final same = ss.where((t) => identical(t, ss[s])).length;
    if (same < 2) return '';
    final idx = ss.take(s + 1).where((t) => identical(t, ss[s])).length - 1;
    return ' ${String.fromCharCode(65 + idx)}';
  }

  int _order(_Item a, _Item b) {
    int rank(_Item it) => it.ex.category == 'compound' ? 0 : 1;
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    // Prioritarios antes
    int pri(_Item it) => it.ex.primaryMuscles.any((m) => profile.priorities.contains(muscleGroupOf(m))) ? 0 : 1;
    final p = pri(a).compareTo(pri(b));
    if (p != 0) return p;
    double size(_Item it) => it.ex.primaryMuscles.map(muscleWeight).fold(0.0, math.max);
    return size(b).compareTo(size(a));
  }

  int _rest(Exercise e) {
    final compound = e.category == 'compound';
    return switch (goal) {
      UserGoal.strength => compound ? 180 : 90,
      _ => compound ? 120 : 75,
    };
  }

  /// Molestia: permitido con precaución (solo contraindicado en casos graves).
  bool _caution(Exercise e) => profile.injuries.any((inj) => e.contraindications
      .any((c) => c.endsWith('_severe') && (_injuryContra[inj] ?? [inj]).any(c.startsWith)));

  WorkoutItem _item(Exercise ex, int sets) {
    final compound = ex.category == 'compound';
    final reps = switch (goal) {
      UserGoal.strength => compound ? '5-8' : '8-12',
      _ => ex.defaultReps,
    };
    return WorkoutItem(
      exerciseId: ex.id,
      sets: sets,
      repsTarget: reps,
      rpeTarget: 8,
      restSeconds: _rest(ex),
      tempo: ex.tempo,
      notesEs: _caution(ex) ? 'Con tu molestia: usa un rango sin dolor. Si molesta, cámbialo por otro.' : null,
      notesEn: _caution(ex) ? 'Pain-free range only; swap it if it hurts.' : null,
    );
  }

  static String _muscleEs(String m) => const {
        'pectoralis_major_clavicular': 'pecho alto',
        'pectoralis_major_sternal': 'pecho',
        'deltoid_anterior': 'deltoides anterior',
        'deltoid_lateral': 'deltoides lateral',
        'deltoid_posterior': 'deltoides posterior',
        'biceps_brachii': 'bíceps',
        'brachialis': 'braquial',
        'triceps_long': 'tríceps (larga)',
        'triceps_lateral': 'tríceps (lateral)',
        'latissimus_dorsi': 'dorsal',
        'trapezius_upper': 'trapecio superior',
        'trapezius_middle': 'trapecio medio',
        'rhomboids': 'romboides',
        'rectus_abdominis': 'abdomen',
        'obliques': 'oblicuos',
        'erector_spinae': 'lumbares',
        'quadriceps': 'cuádriceps',
        'hamstrings': 'isquios',
        'gluteus_maximus': 'glúteo mayor',
        'gluteus_medius': 'glúteo medio',
        'adductors': 'aductores',
        'gastrocnemius': 'gemelos',
        'soleus': 'sóleo',
      }[m] ??
      m;

  /// Minutos estimados: 5 calentamiento + (40 s + descanso) por serie + 1 min por ejercicio.
  static int estimateMinutes(List<WorkoutItem> items) {
    double s = _warmupSec.toDouble();
    for (final it in items) {
      s += it.sets * (_workSec + it.restSeconds) + _setupSec;
    }
    return (s / 60).round();
  }
}
