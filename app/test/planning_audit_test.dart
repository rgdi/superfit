import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/data/models/training_profile.dart';
import 'package:superfit/data/models/user_settings.dart';
import 'package:superfit/domain/engine/muscle_stats.dart';
import 'package:superfit/domain/engine/program_generator.dart';
import 'dart:convert';
import 'dart:io';
import 'support/fakes.dart';

void main() {
  test('auditoría de planificación: 180 perfiles', () {
    final cat = loadCatalog();
    final byId = {for (final e in cat) e.id: e};
    final muscles = (jsonDecode(File('assets/data/muscles.json').readAsStringSync()) as List).map((m) => m['id'] as String).toList();
    final demoTypes = kDemoMachines.expand((m) => m.typeIds).toSet();
    final rows = <String>[];
    final agg = <String, List<double>>{};
    for (final days in [2, 3, 4, 5, 6]) {
      for (final mins in [35, 50, 75]) {
        for (final level in UserLevel.values) {
          for (final goal in [UserGoal.hypertrophy, UserGoal.strength]) {
            for (final types in [null, demoTypes]) {
              final p = ProgramGenerator(catalog: cat, availableTypes: types,
                  profile: TrainingProfile(daysPerWeek: days, sessionMinutes: mins), level: level, goal: goal).generate();
              final vol = {for (final m in muscles) m: 0.0};
              final freq = {for (final m in muscles) m: 0};
              var push = 0.0, pull = 0.0;
              for (final r in p.routines) {
                final hit = <String>{};
                for (final it in r.workout) {
                  final e = byId[it.exerciseId]!;
                  for (final m in e.primaryMuscles) { vol[m] = vol[m]! + it.sets; hit.add(m); }
                  for (final m in e.secondaryMuscles) { vol[m] = vol[m]! + it.sets * 0.5; hit.add(m); }
                  // Empuje/tirón por músculo principal (no por etiqueta de patrón)
                  const pushM = {'pectoralis_major_sternal', 'pectoralis_major_clavicular', 'deltoid_anterior', 'triceps_long', 'triceps_lateral'};
                  const pullM = {'latissimus_dorsi', 'rhomboids', 'trapezius_middle', 'deltoid_posterior', 'biceps_brachii'};
                  if (e.primaryMuscles.any(pushM.contains)) push += it.sets;
                  if (e.primaryMuscles.any(pullM.contains)) pull += it.sets;
                }
                for (final m in hit) freq[m] = freq[m]! + 1;
              }
              final ratio = {for (final m in muscles) m: vol[m]! / weeklyTargetFor(m, level)};
              final zero = muscles.where((m) => vol[m] == 0).toList();
              final low = muscles.where((m) => ratio[m]! > 0 && ratio[m]! < 0.5).length;
              final high = muscles.where((m) => ratio[m]! > 1.6).toList();
              final maxMin = p.routines.map((r) => r.estimatedMinutes).reduce((a, b) => a > b ? a : b);
              for (final m in muscles) { agg.putIfAbsent(m, () => []).add(ratio[m]!); }
              rows.add('d$days m$mins ${level.name.substring(0,3)} ${goal.name.substring(0,4)} ${types == null ? 'all' : 'demo'} | '
                  'cero=${zero.length} bajo=${low} alto=${high.length} maxMin=$maxMin/$mins push/pull=${(push / (pull == 0 ? 1 : pull)).toStringAsFixed(2)} '
                  'freqCuads=${freq['quadriceps']} freqPecho=${freq['pectoralis_major_sternal']}${zero.isNotEmpty ? ' cero:${zero.join(',')}' : ''}${high.isNotEmpty ? ' alto:${high.join(',')}' : ''}');
            }
          }
        }
      }
    }
    // Umbrales de calidad (si el generador empeora, este test falla)
    final bigZero = rows.where((r) => RegExp(r'cero:.*(quadriceps|hamstrings|latissimus_dorsi|pectoralis_major_sternal|gluteus_maximus)').hasMatch(r)).length;
    final unbalanced = rows.where((r) {
      final x = double.parse(RegExp(r'push/pull=([\d.]+)').firstMatch(r)!.group(1)!);
      return x > 1.6 || x < 0.5;
    }).length;
    final overTime = rows.where((r) {
      final m = RegExp(r'maxMin=(\d+)/(\d+)').firstMatch(r)!;
      return int.parse(m.group(1)!) > int.parse(m.group(2)!);
    }).length;
    expect(bigZero, lessThanOrEqualTo(2), reason: 'músculos grandes a cero');
    expect(unbalanced, lessThanOrEqualTo(18), reason: 'empuje:tirón desequilibrado');
    expect(overTime, 0, reason: 'sesiones más largas que el tiempo disponible');
    expect(agg['deltoid_posterior']!.where((x) => x == 0).length, 0);
    expect(agg['adductors']!.where((x) => x == 0).length, 0);
    if (Platform.environment['AUDIT_PRINT'] == null) return;
    for (final r in rows) { print(r); }
    print('--- media ratio volumen/objetivo por músculo (todas las combinaciones)');
    final avg = agg.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    for (final e in (avg.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))) {
      print('${e.key.padRight(28)} ${e.value.toStringAsFixed(2)}  cero en ${agg[e.key]!.where((x) => x == 0).length}/${agg[e.key]!.length}');
    }
  });
}
