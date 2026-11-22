// Generador de programa a medida.
//
// Entradas: perfil (días, minutos, lesiones, prioridades), nivel, objetivo
// y las máquinas que hay en TU gimnasio.
// Salida: rutinas + rotación + mesociclo, con una lista de "por qués".
//
// Base de las decisiones (ver docs/EVIDENCIA.md):
// - Frecuencia ≥2×/semana por músculo (Schoenfeld 2016, PMID 27102172).
// - Más series semanales → más hipertrofia con rendimientos decrecientes
//   (Schoenfeld 2017, PMID 27805470; Pelland 2026, PMID 41343037). Los
//   números concretos (8/12/16) son un punto de partida práctico, NO un
//   umbral demostrado.
// - Descansos ≥2 min en multiarticulares (Schoenfeld 2016, PMID 26605807;
//   Grgic 2018, PMID 28933024 — este último solo mide fuerza).
// - Mantenimiento con ~1/3 del volumen (Bickel 2011, PMID 21131862).
import 'dart:math' as math;
import '../../data/models/exercise.dart';
import '../../data/models/generated_program.dart';
import '../../data/models/routine.dart';
import '../../data/models/training_profile.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/workout_item.dart';

/// Grupo de planificación de un ejercicio.
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

class _Slot {
  final String group;
  final String? focus; // press | side | rear | upper | null
  const _Slot(this.group, [this.focus]);
}

class _DayTemplate {
  final String nameEs;
  final String nameEn;
  final List<_Slot> slots;
  const _DayTemplate(this.nameEs, this.nameEn, this.slots);
}

const _upper = [
  _Slot('chest'), _Slot('back'), _Slot('shoulders', 'press'), _Slot('back'),
  _Slot('chest', 'upper'), _Slot('shoulders', 'side'), _Slot('triceps'), _Slot('biceps'),
];
const _lower = [
  _Slot('quads'), _Slot('hamstrings'), _Slot('glutes'), _Slot('quads'),
  _Slot('hamstrings'), _Slot('calves'), _Slot('abs'),
];
const _push = [
  _Slot('chest'), _Slot('shoulders', 'press'), _Slot('chest', 'upper'),
  _Slot('shoulders', 'side'), _Slot('triceps'), _Slot('triceps'),
];
const _pull = [
  _Slot('back'), _Slot('back'), _Slot('shoulders', 'rear'), _Slot('biceps'),
  _Slot('biceps'), _Slot('abs'),
];
const _legs = [
  _Slot('quads'), _Slot('hamstrings'), _Slot('glutes'), _Slot('quads'),
  _Slot('calves'), _Slot('abs'),
];
const _full = [
  _Slot('quads'), _Slot('chest'), _Slot('back'), _Slot('hamstrings'),
  _Slot('shoulders', 'side'), _Slot('glutes'), _Slot('triceps'), _Slot('biceps'),
  _Slot('calves'), _Slot('abs'),
];

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

  final List<String> _why = [];

  Exercise _byId(String id) => catalog.firstWhere((e) => e.id == id);

  GeneratedProgram generate({DateTime? now}) {
    _why.clear();
    final days = profile.daysPerWeek.clamp(2, 6);
    final (split, templates) = _split(days);

    // --- Ejercicios utilizables ---
    final usable = catalog.where(_isUsable).toList();
    final excludedByInjury = catalog.where((e) =>
        (availableTypes == null || e.usableWith(availableTypes!)) && _contraindicated(e)).toList();
    if (availableTypes != null) {
      _why.add('Solo uso ejercicios que puedes hacer con tus ${availableTypes!.length} tipos de máquina configurados.');
    } else {
      _why.add('No has configurado máquinas: asumo que tu gimnasio tiene todas las del catálogo. '
          'Añádelas en Ajustes → Mis máquinas para afinar.');
    }
    final cautious = catalog.where((e) =>
        (availableTypes == null || e.usableWith(availableTypes!)) && _caution(e)).toList();
    if (cautious.isNotEmpty) {
      _why.add('Con precaución (rango sin dolor): ${cautious.map((e) => e.nameEs).join(', ')}.');
    }
    if (excludedByInjury.isNotEmpty) {
      _why.add('Excluidos por molestias (${profile.injuries.map((i) => kInjuryLabels[i] ?? i).join(', ')}): '
          '${excludedByInjury.map((e) => e.nameEs).join(', ')}.');
    }

    // --- Volumen semanal objetivo por grupo ---
    final weekly = <String, int>{};
    for (final g in kMuscleGroupLabels.keys) {
      weekly[g] = _weeklyTarget(g);
    }

    // Ocurrencias de cada grupo en la semana (cada plantilla = 1 sesión)
    final occurrences = <String, int>{};
    for (final t in templates) {
      for (final s in t.slots) {
        occurrences[s.group] = (occurrences[s.group] ?? 0) + 1;
      }
    }

    // --- Construir rutinas ---
    final routines = <Routine>[];
    final usedByTemplateName = <String, int>{}; // para variar A/B
    for (int d = 0; d < templates.length; d++) {
      final t = templates[d];
      final variant = usedByTemplateName[t.nameEs] ?? 0;
      usedByTemplateName[t.nameEs] = variant + 1;
      final items = <WorkoutItem>[];
      final used = <String>{};
      final missing = <String>{};
      for (final slot in t.slots) {
        final ex = _pick(usable, slot, used, variant);
        if (ex == null) {
          // Sin ejercicio nuevo para este hueco: pasa sus series a otro
          // ejercicio del mismo grupo en la sesión (máx. 5 por ejercicio).
          final perSlot = (weekly[slot.group]! / (occurrences[slot.group] ?? 1)).round();
          final idx = items.indexWhere((it) => groupOf(_byId(it.exerciseId)) == slot.group);
          if (idx >= 0 && items[idx].sets < 5) {
            items[idx] = items[idx].copyWith(sets: (items[idx].sets + perSlot).clamp(2, 5));
          } else if (idx < 0) {
            missing.add(kMuscleGroupLabels[slot.group] ?? slot.group);
          }
          continue;
        }
        used.add(ex.id);
        final occ = occurrences[slot.group] ?? 1;
        final raw = (weekly[slot.group]! / occ).round();
        items.add(_item(ex, raw.clamp(2, 5)));
        // Más de 5 series por slot (p. ej. grupo prioritario) → segundo ejercicio
        if (raw > 5) {
          final extra = _pick(usable, _Slot(slot.group), used, variant);
          if (extra != null) {
            used.add(extra.id);
            items.add(_item(extra, (raw - 5).clamp(2, 5)));
          }
        }
      }
      if (missing.isNotEmpty) {
        _why.add('${t.nameEs}${_suffix(templates, d)}: sin ejercicio disponible para ${missing.join(', ')} '
            '(falta máquina o está excluido por lesión).');
      }
      final fitted = _fitToTime(items, usable);
      final suffix = _suffix(templates, d);
      routines.add(Routine(
        id: 'gen_${d + 1}',
        nameEs: '${t.nameEs}$suffix',
        nameEn: '${t.nameEn}$suffix',
        dayOfWeek: d + 1,
        estimatedMinutes: estimateMinutes(fitted),
        level: level.name,
        goal: goal.name,
        warmup: [
          WarmupItem(
            type: 'mobility',
            nameEs: '5 min de cardio suave (bici, elíptica…)',
            nameEn: '5 min easy cardio',
            durationSeconds: 300,
          ),
          WarmupItem(
            type: 'activation',
            nameEs: '1-2 series de aproximación del primer ejercicio (50% y 75%)',
            nameEn: '1-2 ramp-up sets of the first exercise',
            durationSeconds: 120,
          ),
        ],
        workout: fitted,
        cooldown: const [],
      ));
    }

    // Volumen semanal efectivamente planificado
    final planned = <String, int>{};
    for (final r in routines) {
      for (final it in r.workout) {
        final ex = catalog.firstWhere((e) => e.id == it.exerciseId);
        final g = groupOf(ex);
        planned[g] = (planned[g] ?? 0) + it.sets;
      }
    }

    _why.insert(0, '$days días/semana → $split. ${_freqNote(split)}');
    _why.insert(1, 'Volumen objetivo por grupo: ~${_weeklyTarget('chest')} series/semana '
        '(${_levelEs()}, ${_goalEs()}). Es un punto de partida: el sistema te avisará si te estancas o vas sobrado.');
    if (profile.priorities.isNotEmpty) {
      _why.insert(2, 'Prioridad: ${profile.priorities.map((p) => kMuscleGroupLabels[p]).join(', ')} → +4 series/semana.');
    }
    _why.add('Mesociclo de ${profile.mesocycleWeeks} semanas: el RPE objetivo sube semana a semana '
        'y la última es de descarga (mitad de series). Si detecto fatiga antes, te propongo descargar antes.');

    final start = now ?? DateTime.now();
    return GeneratedProgram(
      createdAt: start,
      startDate: DateTime(start.year, start.month, start.day),
      splitName: split,
      routines: routines,
      rotation: routines.map((r) => r.id).toList(),
      mesocycleWeeks: profile.mesocycleWeeks,
      rationale: List.of(_why),
      weeklySets: planned,
    );
  }

  // ---------------------------------------------------------------------------

  (String, List<_DayTemplate>) _split(int days) {
    switch (days) {
      case 2:
        return ('Cuerpo completo A/B', const [
          _DayTemplate('Cuerpo completo', 'Full body', _full),
          _DayTemplate('Cuerpo completo', 'Full body', _full),
        ]);
      case 3:
        return ('Cuerpo completo A/B/C', const [
          _DayTemplate('Cuerpo completo', 'Full body', _full),
          _DayTemplate('Cuerpo completo', 'Full body', _full),
          _DayTemplate('Cuerpo completo', 'Full body', _full),
        ]);
      case 4:
        return ('Torso / Pierna', const [
          _DayTemplate('Torso', 'Upper', _upper),
          _DayTemplate('Pierna', 'Lower', _lower),
          _DayTemplate('Torso', 'Upper', _upper),
          _DayTemplate('Pierna', 'Lower', _lower),
        ]);
      case 5:
        return ('Torso / Pierna + Empuje / Tirón / Pierna', const [
          _DayTemplate('Torso', 'Upper', _upper),
          _DayTemplate('Pierna', 'Lower', _lower),
          _DayTemplate('Empuje', 'Push', _push),
          _DayTemplate('Tirón', 'Pull', _pull),
          _DayTemplate('Pierna', 'Legs', _legs),
        ]);
      default:
        return ('Empuje / Tirón / Pierna ×2', const [
          _DayTemplate('Empuje', 'Push', _push),
          _DayTemplate('Tirón', 'Pull', _pull),
          _DayTemplate('Pierna', 'Legs', _legs),
          _DayTemplate('Empuje', 'Push', _push),
          _DayTemplate('Tirón', 'Pull', _pull),
          _DayTemplate('Pierna', 'Legs', _legs),
        ]);
    }
  }

  String _suffix(List<_DayTemplate> ts, int d) {
    final same = ts.where((t) => t.nameEs == ts[d].nameEs).length;
    if (same < 2) return '';
    final idx = ts.take(d + 1).where((t) => t.nameEs == ts[d].nameEs).length - 1;
    return ' ${String.fromCharCode(65 + idx)}';
  }

  String _freqNote(String split) => split.startsWith('Cuerpo')
      ? 'Cada músculo se trabaja en todas las sesiones.'
      : 'Cada músculo ~2×/semana (frecuencia ≥2 es al menos tan buena como 1× a igual volumen).';

  int _weeklyTarget(String g) {
    double base = switch (level) {
      UserLevel.beginner => 8,
      UserLevel.intermediate => 12,
      UserLevel.advanced => 16,
    };
    switch (goal) {
      case UserGoal.maintenance:
        base = math.max(4, base / 3).toDouble();
        break;
      case UserGoal.strength:
        base *= 0.8;
        break;
      case UserGoal.hypertrophy:
      case UserGoal.definition:
        break;
    }
    // Grupos pequeños reciben volumen indirecto de los multiarticulares
    if (const {'biceps', 'triceps', 'calves', 'abs'}.contains(g)) base *= 0.6;
    if (g == 'shoulders') base *= 0.8;
    if (profile.priorities.contains(g)) base += 4;
    return base.round().clamp(2, 24);
  }

  /// Contraindicaciones de esta persona que afectan al ejercicio.
  List<String> _hits(Exercise e) => [
        for (final inj in profile.injuries)
          for (final c in e.contraindications)
            if ((_injuryContra[inj] ?? [inj]).any(c.startsWith)) c,
      ];

  /// Excluido si alguna contraindicación NO es solo para casos "_severe".
  /// (Una molestia no es una lesión grave: un press de pecho guiado suele
  /// tolerarse con un rango sin dolor; un pec deck en estiramiento, peor.)
  bool _contraindicated(Exercise e) => _hits(e).any((c) => !c.endsWith('_severe'));

  /// Permitido pero con precaución (solo contraindicado en casos graves).
  bool _caution(Exercise e) => !_contraindicated(e) && _hits(e).isNotEmpty;

  bool _isUsable(Exercise e) {
    if (availableTypes != null && !e.usableWith(availableTypes!)) return false;
    return !_contraindicated(e);
  }

  bool _matchesFocus(Exercise e, String? focus) => switch (focus) {
        'press' => e.pattern == 'vertical_push',
        'side' => e.primaryMuscles.contains('deltoid_lateral'),
        'rear' => e.primaryMuscles.contains('deltoid_posterior'),
        'upper' => e.primaryMuscles.first == 'pectoralis_major_clavicular',
        _ => true,
      };

  Exercise? _pick(List<Exercise> usable, _Slot slot, Set<String> used, int variant) {
    var cands = usable.where((e) => groupOf(e) == slot.group && !used.contains(e.id)).toList();
    if (cands.isEmpty) return null;
    final focused = cands.where((e) => _matchesFocus(e, slot.focus)).toList();
    if (focused.isNotEmpty) cands = focused;
    // Primero los que trabajan el grupo como músculo principal (curl femoral
    // antes que extensión lumbar para isquios), luego multiarticulares.
    int natural(Exercise e) => e.id == 'back_extension' ? 1 : 0;
    cands.sort((a, b) {
      final na = natural(a), nb = natural(b);
      if (na != nb) return na.compareTo(nb);
      final ca = a.category == 'compound' ? 0 : 1;
      final cb = b.category == 'compound' ? 0 : 1;
      if (ca != cb) return ca.compareTo(cb);
      return a.id.compareTo(b.id);
    });
    // Variante B/C → rota el candidato para dar variedad, si hay opciones
    // del mismo tipo (compuesto/aislado) que el primero.
    final sameKind = cands
        .where((e) => e.category == cands.first.category && natural(e) == natural(cands.first))
        .toList();
    return sameKind[variant % sameKind.length];
  }

  WorkoutItem _item(Exercise ex, int sets) {
    final compound = ex.category == 'compound';
    final reps = switch (goal) {
      UserGoal.strength => compound ? '5-8' : '8-12',
      _ => ex.defaultReps,
    };
    final rest = switch (goal) {
      UserGoal.strength => compound ? 180 : 90,
      _ => compound ? 120 : 75,
    };
    return WorkoutItem(
      exerciseId: ex.id,
      sets: sets,
      repsTarget: reps,
      rpeTarget: 8,
      restSeconds: rest,
      tempo: ex.tempo,
      notesEs: _caution(ex)
          ? 'Con tu molestia: usa un rango sin dolor. Si molesta, cámbialo con ⇄.'
          : null,
      notesEn: _caution(ex) ? 'Pain-free range only; swap it if it hurts.' : null,
    );
  }

  /// Minutos estimados: 5 calentamiento + (40 s trabajo + descanso) por serie
  /// + 1 min de cambio/ajuste de máquina por ejercicio.
  static int estimateMinutes(List<WorkoutItem> items) {
    double s = 5 * 60;
    for (final it in items) {
      s += it.sets * (40 + it.restSeconds) + 60;
    }
    return (s / 60).round();
  }

  List<WorkoutItem> _fitToTime(List<WorkoutItem> items, List<Exercise> usable) {
    final out = List<WorkoutItem>.of(items);
    final budget = profile.sessionMinutes;
    bool isPriority(WorkoutItem it) {
      final ex = catalog.firstWhere((e) => e.id == it.exerciseId);
      return profile.priorities.contains(groupOf(ex));
    }

    bool isIsolation(WorkoutItem it) =>
        catalog.firstWhere((e) => e.id == it.exerciseId).category != 'compound';

    var trimmed = false;
    while (estimateMinutes(out) > budget) {
      // 1) quita una serie al ejercicio con más series (aislados no prioritarios primero)
      final candidates = out.where((it) => it.sets > 2).toList()
        ..sort((a, b) {
          int rank(WorkoutItem it) => (isPriority(it) ? 2 : 0) + (isIsolation(it) ? 0 : 1);
          final r = rank(a).compareTo(rank(b));
          return r != 0 ? r : b.sets.compareTo(a.sets);
        });
      if (candidates.isNotEmpty) {
        final c = candidates.first;
        out[out.indexOf(c)] = c.copyWith(sets: c.sets - 1);
        trimmed = true;
        continue;
      }
      // 2) quita el último ejercicio no prioritario
      if (out.length <= 3) break;
      final idx = out.lastIndexWhere((it) => !isPriority(it));
      out.removeAt(idx < 0 ? out.length - 1 : idx);
      trimmed = true;
    }
    if (trimmed && !_why.any((w) => w.startsWith('Ajustado a'))) {
      _why.add('Ajustado a tus $budget min por sesión: he recortado series de ejercicios de aislamiento '
          'no prioritarios. Con más tiempo, el volumen sube automáticamente.');
    }
    return out;
  }

  String _levelEs() => switch (level) {
        UserLevel.beginner => 'principiante',
        UserLevel.intermediate => 'intermedio',
        UserLevel.advanced => 'avanzado',
      };

  String _goalEs() => switch (goal) {
        UserGoal.hypertrophy => 'hipertrofia',
        UserGoal.strength => 'fuerza',
        UserGoal.maintenance => 'mantenimiento',
        UserGoal.definition => 'definición',
      };
}
