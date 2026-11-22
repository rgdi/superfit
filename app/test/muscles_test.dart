import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/data/models/exercise.dart';
import 'package:superfit/data/models/set_log.dart';
import 'package:superfit/data/models/user_settings.dart';
import 'package:superfit/domain/engine/efficiency.dart';
import 'package:superfit/domain/engine/muscle_stats.dart';

List<Exercise> _cat() => (jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as List)
    .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
    .toList();
List<String> _muscles() => (jsonDecode(File('assets/data/muscles.json').readAsStringSync()) as List)
    .map((m) => m['id'] as String)
    .toList();

SetLog _s(String ex, DateTime at, {int? rpe = 8, String? technique}) => SetLog(
    id: '$ex$at', sessionId: 's', exerciseId: ex, setNumber: 1, weight: 40, reps: 10, rpe: rpe,
    completed: true, performedAt: at, technique: technique);

void main() {
  final cat = _cat();
  final byId = {for (final e in cat) e.id: e};
  final muscles = _muscles();
  final now = DateTime(2026, 3, 10, 20);

  test('series fraccionales: principal 1, secundario 0,5; aproximaciones no cuentan', () {
    final sets = [
      for (int i = 0; i < 3; i++) _s('chest_press_machine', now.subtract(Duration(hours: 2, minutes: i))),
      _s('chest_press_machine', now.subtract(const Duration(hours: 3)), technique: 'warmup'),
      _s('chest_press_machine', now.subtract(const Duration(days: 9))), // fuera de la semana
    ];
    final st = computeMuscleStats(sets: sets, catalog: byId, muscleIds: muscles, level: UserLevel.intermediate, now: now);
    expect(st['pectoralis_major_sternal']!.weeklySets, 3);
    expect(st['triceps_lateral']!.weeklySets, 1.5);
    expect(st['quadriceps']!.weeklySets, 0);
    expect(st['quadriceps']!.status, 'Sin trabajar');
  });

  test('recuperación: baja justo después y se recupera con los días', () {
    final sets = [for (int i = 0; i < 5; i++) _s('leg_press', now.subtract(Duration(minutes: 10 + i)), rpe: 9)];
    double rec(DateTime t) => computeMuscleStats(
            sets: sets, catalog: byId, muscleIds: muscles, level: UserLevel.intermediate, now: t)['quadriceps']!
        .recovery;
    expect(rec(now), lessThan(0.4));
    expect(rec(now.add(const Duration(hours: 48))), greaterThan(rec(now.add(const Duration(hours: 12)))));
    expect(rec(now.add(const Duration(days: 4))), greaterThan(0.9));
  });

  test('circuito mínimo con todas las máquinas: pocos ejercicios y cubre casi todo', () {
    final plan = planMinimalCircuit(catalog: cat, muscleIds: muscles);
    // ignore: avoid_print
    for (final p in plan.picks) print('${p.exercise.id} → ${p.covers.join(", ")}');
    // ignore: avoid_print
    print('sin cubrir: ${plan.uncovered} · ~${plan.minutes} min');
    expect(plan.picks.length, lessThanOrEqualTo(12));
    expect(plan.uncovered, isEmpty);
    expect(plan.picks.first.exercise.category, 'compound');
    final ids = plan.picks.map((p) => p.exercise.id).toSet();
    expect(ids.length, plan.picks.length);
  });

  test('esencial: ≤6 ejercicios, multiarticulares y grupos grandes', () {
    final plan = planMinimalCircuit(catalog: cat, muscleIds: muscles, essential: true);
    // ignore: avoid_print
    for (final p in plan.picks) print('ESENCIAL ${p.exercise.id} → ${p.covers.join(", ")}');
    // ignore: avoid_print
    print('esencial sin cubrir: ${plan.uncovered} · parcial: ${plan.partial} · ~${plan.minutes} min');
    expect(plan.picks.length, lessThanOrEqualTo(6));
    final ids = plan.picks.map((p) => p.exercise.id).toSet();
    expect(ids, containsAll(['leg_press', 'chest_press_machine']));
    expect(plan.coverage['latissimus_dorsi'], 1);
    expect(plan.coverage['hamstrings'], 1); // grande: entra antes que deltoide posterior/abdomen
  });

  test('con pocas máquinas: solo usa las tuyas y dice qué queda sin cubrir', () {
    final types = {'leg_press', 'chest_press', 'lat_pulldown'};
    final plan = planMinimalCircuit(catalog: cat, muscleIds: muscles, availableTypes: types);
    for (final p in plan.picks) {
      expect(p.exercise.usableWith(types), isTrue);
    }
    expect(plan.coverage['hamstrings']!, lessThan(1)); // solo indirecto (prensa)
    expect(plan.uncovered.union(plan.partial), contains('hamstrings'));
  });

  test('excluye ejercicios por molestias', () {
    final plan = planMinimalCircuit(catalog: cat, muscleIds: muscles, exclude: {'leg_press', 'hack_squat'});
    expect(plan.picks.map((p) => p.exercise.id), isNot(contains('leg_press')));
  });
}
