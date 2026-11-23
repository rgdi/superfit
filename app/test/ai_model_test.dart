import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/domain/ai/performance_model.dart';
import 'package:superfit/domain/engine/machine_spec.dart';

/// Atleta simulado con parámetros conocidos:
///  - fuerza base 100 kg que crece 1 %/semana
///  - pierde 4 % por serie (más que el prior del 1,5 %)
///  - curva de reps k = 1/24 (hace MÁS reps que Epley con el mismo %)
///  - "a tope" +3 %
List<TrainingObs> simulateForPrint({int weeks = 12, int seed = 7, double fatigue = 0.04, double k = 1 / 24}) => _simulate(weeks: weeks, seed: seed, fatigue: fatigue, k: k);

List<TrainingObs> _simulate({int weeks = 12, int seed = 7, double fatigue = 0.04, double k = 1 / 24}) {
  final rnd = math.Random(seed);
  final out = <TrainingObs>[];
  final start = DateTime(2026, 1, 5, 18);
  var s = 0;
  for (int w = 0; w < weeks; w++) {
    for (final dow in [0, 2, 4]) {
      final at = start.add(Duration(days: w * 7 + dow));
      final strength = 100 * math.pow(1.01, w + dow / 7);
      final readiness = rnd.nextInt(3) - 1;
      // Peso variado para que haya reps distintas (identifica k)
      final weight = (strength * (0.55 + rnd.nextDouble() * 0.25) / 2.5).round() * 2.5;
      for (int i = 0; i < 3; i++) {
        final rir = 1 + rnd.nextInt(3);
        final noise = (rnd.nextDouble() - 0.5) * 0.03;
        final sEff = strength * math.exp(-fatigue * i + 0.03 * readiness + noise);
        final reps = ((sEff / weight - 1) / k - rir).floor();
        if (reps < 1) continue;
        out.add(TrainingObs(
          exerciseId: 'leg_press',
          machineId: 'm1',
          compound: true,
          sessionId: 's$s',
          at: at.add(Duration(minutes: 3 * i)),
          weight: weight.toDouble(),
          reps: reps,
          rpe: 10 - rir,
          setIndex: i,
          readiness: readiness,
        ));
      }
      s++;
    }
  }
  return out;
}

void main() {
  test('sin datos: no inventa', () {
    final m = PerformanceModel.fit(const []);
    expect(m.knows('x', null), isFalse);
    expect(m.recommendWeight('x', null, true, 10, 8), isNull);
    expect(m.insights!.observations, 0);
  });

  test('aprende fatiga por serie, curva de reps y mejora a la fórmula genérica', () {
    final m = PerformanceModel.fit(_simulate());
    final ins = m.insights!;
    // Fatiga real 4 %: debe alejarse claramente del prior (1,5 %)
    expect(ins.fatiguePerSet, greaterThan(0.025));
    expect(ins.fatiguePerSet, lessThan(0.06));
    // Curva personal: k real 1/24 > Epley 1/30
    expect(ins.slopeCompound, greaterThan(1 / 30));
    // Readiness positivo
    expect(ins.readinessEffect, greaterThan(0));
    // Backtest honesto: mejor que Epley genérico
    expect(ins.backtestN, greaterThan(10));
    expect(ins.maeModel!, lessThan(ins.maeBaseline!));
  });

  test('sigue la fuerza y su tendencia', () {
    final m = PerformanceModel.fit(_simulate());
    final st = m.strength('leg_press', 'm1', at: DateTime(2026, 3, 29))!;
    final truth = 100 * math.pow(1.01, 12);
    expect(st.oneRm, closeTo(truth, truth * 0.08));
    expect(st.trendPerWeek, greaterThan(0));
    expect(st.usable, isTrue);
  });

  test('recomienda pesos reales de la máquina y coherentes', () {
    final m = PerformanceModel.fit(_simulate());
    final spec = MachineSpec(stack: [for (var w = 10.0; w <= 200; w += 10) w], addOns: [5]);
    final w10 = m.recommendWeight('leg_press', 'm1', true, 10, 8, spec: spec)!;
    final w6 = m.recommendWeight('leg_press', 'm1', true, 6, 8, spec: spec)!;
    expect(spec.weights, contains(w10));
    expect(w6, greaterThan(w10)); // menos reps → más peso
    // Más fatiga en la serie 3 → menos reps previstas con el mismo peso
    final r0 = m.predictReps('leg_press', 'm1', true, w10)!;
    final r2 = m.predictReps('leg_press', 'm1', true, w10, setIndex: 2)!;
    expect(r2, lessThan(r0));
  });

  test('máquinas distintas no se mezclan', () {
    final data = [
      ..._simulate(),
      ..._simulate(seed: 3).map((o) => TrainingObs(
            exerciseId: o.exerciseId, machineId: 'm2', compound: true, sessionId: '${o.sessionId}b',
            at: o.at.add(const Duration(hours: 2)), weight: o.weight * 2, reps: o.reps, rpe: o.rpe,
            setIndex: o.setIndex, readiness: o.readiness)),
    ];
    final m = PerformanceModel.fit(data);
    final a = m.strength('leg_press', 'm1')!.oneRm;
    final b = m.strength('leg_press', 'm2')!.oneRm;
    expect(b / a, closeTo(2, 0.25)); // la m2 "pesa" el doble en su escala
  });

  test('confianza por sesiones: con una sola sesión no se usa', () {
    final one = _simulate(weeks: 1).where((o) => o.sessionId == 's0').toList();
    final m = PerformanceModel.fit(one);
    final st = m.strength('leg_press', 'm1')!;
    expect(st.sessions, 1);
    expect(st.usable, isFalse);
    expect(st.confidence, 'baja');
  });

  test('actualización en vivo mueve la estimación', () {
    final m = PerformanceModel.fit(_simulate(weeks: 4));
    final before = m.strength('leg_press', 'm1')!.oneRm;
    m.observeLive(TrainingObs(
        exerciseId: 'leg_press', machineId: 'm1', compound: true, sessionId: 'live',
        at: DateTime(2026, 2, 3, 18), weight: before * 0.8, reps: 12, rpe: 8, setIndex: 0));
    expect(m.strength('leg_press', 'm1')!.oneRm, greaterThan(before));
  });
}
