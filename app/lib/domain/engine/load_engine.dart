// Motor de cargas: decide el peso de cada serie.
//
// Qué hace (y qué NO es "ciencia"):
// - Doble progresión dentro de un rango de reps: subir reps hasta el tope
//   del rango y, cuando todas las series llegan al tope sin pasarte de RPE,
//   subir carga. Es el método estándar en manuales de fuerza (NSCA) — no hay
//   un ensayo que demuestre que sea "el mejor", es una regla práctica sensata.
// - e1RM con Epley corregido por repeticiones en reserva (RIR = 10 − RPE,
//   escala de Zourdos et al. 2016, PMID 26049792). Es una ESTIMACIÓN: el
//   error crece por encima de ~12 reps y en máquinas varía según el modelo.
// - Redondeo a las placas reales de la máquina del usuario (mín/máx/salto).
// - Calibración: sin historial, propone un peso conservador y reajusta las
//   siguientes series a partir de la primera (RPE declarado).
import 'dart:math' as math;
import 'machine_spec.dart';
export 'machine_spec.dart';

class SetRecord {
  final String sessionId;
  final double weight;
  final int reps;
  final int? rpe;
  final DateTime at;
  final String? technique; // work | backoff | drop | warmup
  final bool deload; // hecha en semana de descarga
  const SetRecord({
    required this.sessionId,
    required this.weight,
    required this.reps,
    this.rpe,
    required this.at,
    this.technique,
    this.deload = false,
  });
}


enum LoadAction { calibrate, increase, addReps, hold, decrease, maxedOut }

class LoadPrescription {
  final double weight;
  final int targetReps;
  final int repMin;
  final int repMax;
  final int rpeTarget;
  final LoadAction action;
  final String reason;
  final double? e1rm;
  final bool plateau; // e1RM sin mejorar en ~4 sesiones / 3+ semanas
  final bool performanceDrop; // última sesión claramente por debajo
  final double? previousWeight; // peso de trabajo de la última sesión válida

  const LoadPrescription({
    required this.weight,
    required this.targetReps,
    required this.repMin,
    required this.repMax,
    required this.rpeTarget,
    required this.action,
    required this.reason,
    this.e1rm,
    this.plateau = false,
    this.performanceDrop = false,
    this.previousWeight,
  });

  LoadPrescription copyWith({double? weight, int? targetReps, String? reason, LoadAction? action}) => LoadPrescription(
        weight: weight ?? this.weight,
        targetReps: targetReps ?? this.targetReps,
        repMin: repMin,
        repMax: repMax,
        rpeTarget: rpeTarget,
        action: action ?? this.action,
        reason: reason ?? this.reason,
        e1rm: e1rm,
        plateau: plateau,
        performanceDrop: performanceDrop,
        previousWeight: previousWeight,
      );
}

class LoadEngine {
  /// RPE no indicado → asumimos RIR 2 (zona de trabajo típica).
  static double rir(int? rpe) => rpe == null ? 2.0 : (10 - rpe).clamp(0, 6).toDouble();

  /// 1RM estimado (Epley) contando las reps que quedaban en reserva.
  static double e1rm(double weight, int reps, int? rpe) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * (1 + (reps + rir(rpe)) / 30.0);
  }

  /// Carga que corresponde a `reps` dejando (10 − rpe) en reserva.
  static double loadFor(double e1rm, int reps, num rpe) {
    final r = reps + (10 - rpe).clamp(0, 6);
    return e1rm / (1 + r / 30.0);
  }

  /// Redondea a un peso que exista en la máquina.
  static double roundTo(double w, MachineSpec m, {RoundMode mode = RoundMode.nearest}) => m.round(w, mode: mode);

  /// Prescripción para la próxima sesión de un ejercicio.
  static LoadPrescription nextSession({
    required List<SetRecord> history,
    required int repMin,
    required int repMax,
    required int rpeTarget,
    required double coldStartWeight,
    MachineSpec? machine,
  }) {
    machine ??= MachineSpec.generic;
    if (history.isEmpty) {
      final w = roundTo(coldStartWeight, machine, mode: RoundMode.down);
      return LoadPrescription(
        weight: w,
        targetReps: repMin,
        repMin: repMin,
        repMax: repMax,
        rpeTarget: rpeTarget,
        action: LoadAction.calibrate,
        reason: 'Primera vez: peso conservador. Haz la 1ª serie, marca el RPE '
            'y ajusto las siguientes.',
      );
    }

    // Las sesiones de descarga no son referencia (peso y series rebajados a
    // propósito): se ignoran si hay otras. Tampoco cuentan aproximaciones/drops.
    final valid = history.where((s) => s.technique != 'warmup' && s.technique != 'drop').toList();
    final normal = valid.where((s) => !s.deload).toList();
    final sessions = _bySession(normal.isNotEmpty ? normal : (valid.isNotEmpty ? valid : history));
    final last = sessions.first;
    // Peso de trabajo: el de las series principales (no las back-off, que son −10 %)
    final mainSets = last.where((s) => s.technique != 'backoff').toList();
    final lastWeight = _workingWeight(mainSets.isEmpty ? last : mainSets);
    final work = (mainSets.isEmpty ? last : mainSets).where((s) => (s.weight - lastWeight).abs() < 0.01).toList();
    final minReps = work.map((s) => s.reps).reduce(math.min);
    final rpes = work.where((s) => s.rpe != null).map((s) => s.rpe!).toList();
    final avgRpe = rpes.isEmpty ? null : rpes.reduce((a, b) => a + b) / rpes.length;
    final lastE1rm = last.map((s) => e1rm(s.weight, s.reps, s.rpe)).reduce(math.max);

    // Tendencias
    final sessionE1rms = sessions.map((ss) => ss.map((s) => e1rm(s.weight, s.reps, s.rpe)).reduce(math.max)).toList();
    final plateau = _isPlateau(sessions, sessionE1rms);
    final drop = sessionE1rms.length >= 3 &&
        sessionE1rms.first < 0.95 * sessionE1rms.skip(1).take(3).reduce(math.max);

    LoadPrescription build(double w, int reps, LoadAction a, String why) => LoadPrescription(
          weight: w,
          targetReps: reps.clamp(math.min(reps, repMin), repMax),
          repMin: repMin,
          repMax: repMax,
          rpeTarget: rpeTarget,
          action: a,
          reason: why +
              (plateau ? ' · Llevas varias sesiones sin mejorar: prueba una variante.' : '') +
              (drop ? ' · Rendimiento más bajo de lo normal: ¿sueño/estrés?' : ''),
          e1rm: lastE1rm,
          plateau: plateau,
          performanceDrop: drop,
          previousWeight: lastWeight,
        );

    final rpeOk = avgRpe == null || avgRpe <= rpeTarget + 0.5;
    final tooHard = (avgRpe != null && avgRpe >= rpeTarget + 1.5) || minReps < repMin;

    // "Demasiado fácil": dentro del rango pero ≥2 puntos de RPE por debajo → subir ya
    final tooEasy = avgRpe != null && avgRpe <= rpeTarget - 2 && minReps >= repMin;

    // 1) Todas las series al tope del rango sin pasarse de RPE → subir carga
    if ((minReps >= repMax && rpeOk) || tooEasy) {
      var next = machine.up(lastWeight);
      // Si el e1RM dice que vas sobrado, salta más (máx +10%)
      final byE1rm = roundTo(loadFor(lastE1rm, repMin, rpeTarget), machine, mode: RoundMode.down);
      final cap = roundTo(lastWeight * 1.10, machine, mode: RoundMode.down);
      if (byE1rm > next) next = math.min(byE1rm, math.max(cap, next));
      if (next <= lastWeight) {
        return build(lastWeight, repMax, LoadAction.maxedOut,
            'Has llegado al máximo de la máquina. Sube reps, baja el tempo (3 s) o cambia de variante.');
      }
      // ¿Con el siguiente peso real llegarías al mínimo de reps? En pilas con
      // saltos grandes (40 → 45 kg = +12,5 %) muchas veces no: entonces antes
      // de subir se amplía el rango hasta 2 reps por encima del máximo.
      final predicted = (lastE1rm / next - 1) * 30 - (10 - rpeTarget);
      final jumpPct = ((next / lastWeight - 1) * 100).round();
      if (predicted < repMin - 2) {
        // Salto enorme (p. ej. 5 → 7,5 kg = +50 %): subir llevaría a fallar y
        // volver a bajar en bucle. Se progresa por reps y tempo.
        final t = math.min(repMax + 4, minReps + 1);
        return LoadPrescription(
          weight: lastWeight,
          targetReps: t,
          repMin: repMin,
          repMax: repMax + 4,
          rpeTarget: rpeTarget,
          action: LoadAction.addReps,
          reason: 'La siguiente placa (${_fmt(next)} kg, +$jumpPct %) es demasiado salto. Sigue con ${_fmt(lastWeight)} kg: '
              'sube a $t reps y baja en 3 segundos. Con microcarga podrías subir antes.',
          e1rm: lastE1rm,
          plateau: plateau,
          performanceDrop: drop,
        );
      }
      if (predicted < repMin - 0.5) {
        if (minReps < repMax + 2) {
          final t = math.min(repMax + 2, minReps + 1);
          return LoadPrescription(
            weight: lastWeight,
            targetReps: t,
            repMin: repMin,
            repMax: repMax + 2,
            rpeTarget: rpeTarget,
            action: LoadAction.addReps,
            reason: 'La siguiente placa (${_fmt(next)} kg, +$jumpPct %) es un salto grande: con ella harías '
                '~${math.max(0, predicted).floor()} reps. Primero llega a $t reps con ${_fmt(lastWeight)} kg. '
                'Si tu máquina tiene microcarga, añádela en Mis máquinas.',
            e1rm: lastE1rm,
            plateau: plateau,
            performanceDrop: drop,
          );
        }
        final t = math.max(repMin - 2, predicted.floor()).clamp(1, repMax);
        return build(next, t, LoadAction.increase,
            'Ya haces ${repMax + 2} reps: toca subir a ${_fmt(next)} kg (+$jumpPct %). Empieza con $t reps y vuelve a subir.');
      }
      return build(next, repMin, LoadAction.increase, tooEasy && minReps < repMax
          ? 'Te resultó fácil (RPE ${avgRpe.toStringAsFixed(1)} frente a $rpeTarget) → sube a ${_fmt(next)} kg.'
          : 'Completaste $repMax reps en todas las series a RPE ≤ $rpeTarget → sube a ${_fmt(next)} kg y vuelve a $repMin reps.');
    }

    // 2) Demasiado duro → bajar a lo que dice el e1RM para el centro del rango
    if (tooHard) {
      final mid = ((repMin + repMax) / 2).round();
      var next = roundTo(loadFor(lastE1rm, mid, rpeTarget), machine, mode: RoundMode.down);
      if (next >= lastWeight) next = machine.down(lastWeight);
      final why = minReps < repMin
          ? 'No llegaste a $repMin reps → baja a ${_fmt(next)} kg para trabajar en rango.'
          : 'RPE medio ${avgRpe!.toStringAsFixed(1)} (objetivo $rpeTarget) → baja a ${_fmt(next)} kg.';
      return build(next, mid, LoadAction.decrease, why);
    }

    // 3) Dentro del rango → mismo peso, +1 rep
    final target = math.min(repMax, minReps + 1);
    return build(lastWeight, target, LoadAction.addReps,
        'Mismo peso (${_fmt(lastWeight)} kg). Objetivo: $target reps en cada serie.');
  }

  /// Ajuste dentro de la sesión tras completar una serie.
  /// Devuelve el peso sugerido para la siguiente serie (o null si no cambia).
  static double? adjustNextSet({
    required double weight,
    required int reps,
    required int? rpe,
    required int repMin,
    required int repMax,
    required int rpeTarget,
    MachineSpec? machine,
    bool calibrating = false,
  }) {
    machine ??= MachineSpec.generic;
    if (rpe == null) {
      if (reps < repMin) return machine.down(weight);
      return null;
    }
    final diff = rpe - rpeTarget;
    final outOfRange = reps < repMin || reps > repMax + 2;
    // En calibración ajustamos siempre; en sesiones normales solo si nos
    // desviamos ≥2 puntos de RPE o salimos del rango (la fatiga acumulada
    // ya sube el RPE serie a serie, no hay que perseguirla).
    if (!calibrating && diff.abs() < 2 && !outOfRange) return null;
    final target = reps.clamp(repMin, repMax);
    final est = e1rm(weight, reps, rpe);
    final next = roundTo(loadFor(est, target, rpeTarget), machine);
    if ((next - weight).abs() < 1e-6) return null;
    return next;
  }

  // ---------- helpers ----------

  static List<List<SetRecord>> _bySession(List<SetRecord> h) {
    final map = <String, List<SetRecord>>{};
    for (final s in h) {
      map.putIfAbsent(s.sessionId, () => []).add(s);
    }
    final l = map.values.toList();
    for (final ss in l) {
      ss.sort((a, b) => a.at.compareTo(b.at));
    }
    l.sort((a, b) => b.first.at.compareTo(a.first.at));
    return l;
  }

  /// Peso de trabajo = el más usado en la sesión (si empate, el mayor).
  static double _workingWeight(List<SetRecord> s) {
    final counts = <double, int>{};
    for (final x in s) {
      counts[x.weight] = (counts[x.weight] ?? 0) + 1;
    }
    final best = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : b.key.compareTo(a.key));
    return best.first.key;
  }

  static bool _isPlateau(List<List<SetRecord>> sessions, List<double> e1rms) {
    if (e1rms.length < 4) return false;
    final span = sessions.first.first.at.difference(sessions[3].first.at).inDays;
    if (span < 18) return false;
    final recent = math.max(e1rms[0], e1rms[1]);
    final before = math.max(e1rms[2], e1rms[3]);
    return recent <= before * 1.01;
  }

  static String _fmt(double w) => w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
}

