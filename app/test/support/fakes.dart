// Repositorios en memoria y datos de ejemplo para tests y capturas.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:superfit/data/models/body_metric.dart';
import 'package:superfit/data/models/exercise.dart';
import 'package:superfit/data/models/generated_program.dart';
import 'package:superfit/data/models/gym_machine.dart';
import 'package:superfit/data/models/progress_photo.dart';
import 'package:superfit/data/models/set_log.dart';
import 'package:superfit/data/models/training_profile.dart';
import 'package:superfit/data/models/user_settings.dart';
import 'package:superfit/data/models/workout_session.dart';
import 'package:superfit/data/repositories/body_metric_repo.dart';
import 'package:superfit/data/repositories/photo_repo.dart';
import 'package:superfit/data/repositories/session_repo.dart';
import 'package:superfit/data/repositories/set_repo.dart';
import 'package:superfit/domain/engine/program_generator.dart';

class FakeSessionRepo extends SessionRepo {
  final List<WorkoutSession> sessions = [];
  int finished = 0;

  @override
  Future<WorkoutSession> startSession(String routineId) async {
    final s = WorkoutSession(id: 'live${sessions.length}', routineId: routineId, startedAt: DateTime.now());
    sessions.add(s);
    return s;
  }

  @override
  Future<void> finishSession(String id,
      {int? perceivedExertion, String? notes, int? totalSets, double? totalVolume}) async {
    finished++;
    final i = sessions.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final s = sessions[i];
    sessions[i] = WorkoutSession(
      id: s.id,
      routineId: s.routineId,
      startedAt: s.startedAt,
      finishedAt: DateTime.now(),
      perceivedExertion: perceivedExertion,
      totalSets: totalSets,
      totalVolume: totalVolume,
    );
  }

  @override
  Future<WorkoutSession?> sessionById(String id) async => sessions.where((s) => s.id == id).firstOrNull;
  @override
  Future<WorkoutSession?> activeSession() async => sessions.where((s) => s.finishedAt == null).lastOrNull;
  @override
  Future<List<WorkoutSession>> recentSessions({int limit = 20}) async =>
      (sessions.where((s) => s.finishedAt != null).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt)))
          .take(limit)
          .toList();
  @override
  Future<List<WorkoutSession>> sessionsInRange(DateTime from, DateTime to) async =>
      sessions.where((s) => !s.startedAt.isBefore(from) && !s.startedAt.isAfter(to)).toList();
  @override
  Future<int> totalCompletedSessions() async => sessions.where((s) => s.finishedAt != null).length;
}

class FakeSetRepo extends SetRepo {
  final List<SetLog> sets = [];
  int _n = 0;

  @override
  Future<SetLog> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    int? rpe,
    int? restTakenSeconds,
    String? technique,
    String? tempoNotes,
    bool completed = true,
    String? machineId,
  }) async {
    final s = SetLog(
      id: 'x${_n++}',
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rpe: rpe,
      completed: completed,
      performedAt: DateTime.now().add(Duration(seconds: _n)),
      technique: technique,
      machineId: machineId,
    );
    sets.add(s);
    return s;
  }

  @override
  Future<void> updateSet(SetLog s) async => sets[sets.indexWhere((x) => x.id == s.id)] = s;
  @override
  Future<void> deleteSet(String id) async => sets.removeWhere((x) => x.id == id);
  @override
  Future<List<SetLog>> setsForSession(String sessionId) async => sets.where((s) => s.sessionId == sessionId).toList();
  @override
  Future<List<SetLog>> setsForExercise(String exerciseId, {int limit = 50}) async =>
      (sets.where((s) => s.exerciseId == exerciseId && s.completed).toList()
            ..sort((a, b) => b.performedAt.compareTo(a.performedAt)))
          .take(limit)
          .toList();
  @override
  Future<List<SetLog>> allCompleted() async =>
      sets.where((s) => s.completed).toList()..sort((a, b) => a.performedAt.compareTo(b.performedAt));
  @override
  Future<List<SetLog>> setsForMachine(String machineId) async =>
      sets.where((s) => s.machineId == machineId).toList()..sort((a, b) => a.performedAt.compareTo(b.performedAt));
  @override
  Future<List<SetLog>> effectiveSetsInLastDays(int days) async {
    final cut = DateTime.now().subtract(Duration(days: days));
    return sets.where((s) => s.performedAt.isAfter(cut) && (s.rpe ?? 0) >= 7).toList();
  }

  @override
  Future<double?> averageRpeLastDays(int days) async {
    final cut = DateTime.now().subtract(Duration(days: days));
    final r = sets.where((s) => s.performedAt.isAfter(cut) && s.rpe != null).map((s) => s.rpe!).toList();
    return r.isEmpty ? null : r.reduce((a, b) => a + b) / r.length;
  }

  @override
  Future<double> volumeForExerciseLastDays(String exerciseId, int days) async {
    final cut = DateTime.now().subtract(Duration(days: days));
    return sets
        .where((s) => s.exerciseId == exerciseId && s.performedAt.isAfter(cut))
        .fold<double>(0, (a, s) => a + s.weight * s.reps);
  }

  @override
  Future<double?> estimated1RM(String exerciseId) async {
    final ss = sets.where((s) => s.exerciseId == exerciseId).toList();
    if (ss.isEmpty) return null;
    return ss.map((s) => s.weight * (1 + s.reps / 30)).reduce(math.max);
  }
}

class FakeBodyMetricRepo extends BodyMetricRepo {
  final List<BodyMetric> items = [];
  @override
  Future<List<BodyMetric>> all() async => List.of(items);
  @override
  Future<BodyMetric?> latest() async => items.isEmpty ? null : items.last;
}

class FakePhotoRepo extends PhotoRepo {
  @override
  Future<List<ProgressPhoto>> all({String? pose}) async => const [];
  @override
  Future<ProgressPhoto?> byId(String id) async => null;
}

List<Exercise> loadCatalog() => (jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as List)
    .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
    .toList();

/// Gimnasio de ejemplo (Technogym) para capturas.
const List<GymMachine> kDemoMachines = [
  GymMachine(id: 'm_cp', name: 'Technogym Artis Chest Press', typeIds: ['chest_press'], stack: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70], addOns: [2.5], setupNotes: 'Asiento 4'),
  GymMachine(id: 'm_lp', name: 'Technogym Artis Leg Press', typeIds: ['leg_press'], minWeight: 10, maxWeight: 200, increment: 10, addOns: [5], setupNotes: 'Respaldo 3'),
  GymMachine(id: 'm_lat', name: 'Technogym Artis Lat Machine', typeIds: ['lat_pulldown'], minWeight: 5, maxWeight: 100, increment: 5, addOns: [2.5]),
  GymMachine(id: 'm_row', name: 'Technogym Artis Low Row', typeIds: ['seated_row'], minWeight: 5, maxWeight: 100, increment: 5),
  GymMachine(id: 'm_sp', name: 'Technogym Artis Shoulder Press', typeIds: ['shoulder_press'], minWeight: 5, maxWeight: 80, increment: 5),
  GymMachine(id: 'm_lc', name: 'Technogym Artis Leg Curl', typeIds: ['leg_curl'], minWeight: 5, maxWeight: 100, increment: 5),
  GymMachine(id: 'm_le', name: 'Technogym Artis Leg Extension', typeIds: ['leg_extension'], minWeight: 5, maxWeight: 100, increment: 5),
  GymMachine(id: 'm_pec', name: 'Technogym Artis Pectoral', typeIds: ['pec_deck', 'rear_delt'], minWeight: 5, maxWeight: 80, increment: 5),
  GymMachine(id: 'm_dap', name: 'Technogym Dual Adjustable Pulley', typeIds: ['functional_trainer', 'cable_pulley'], minWeight: 2.5, maxWeight: 50, increment: 2.5),
  GymMachine(id: 'm_mh', name: 'Technogym Multi Hip', typeIds: ['hip_abductor', 'hip_adductor', 'glute_machine'], minWeight: 5, maxWeight: 60, increment: 5),
  GymMachine(id: 'm_calf', name: 'Technogym Calf', typeIds: ['calf_raise'], minWeight: 10, maxWeight: 150, increment: 10),
  GymMachine(id: 'm_ab', name: 'Technogym Abdominal Crunch', typeIds: ['abdominal_crunch'], minWeight: 5, maxWeight: 80, increment: 5),
  GymMachine(id: 'm_curl', name: 'Technogym Arm Curl', typeIds: ['arm_curl'], minWeight: 5, maxWeight: 60, increment: 2.5),
];

/// Llena los repos con ~4 semanas de un programa de 4 días, progresando.
GeneratedProgram seedDemo(FakeSessionRepo sessions, FakeSetRepo sets, List<Exercise> catalog, {DateTime? now}) {
  final t = now ?? DateTime.now();
  final types = kDemoMachines.expand((m) => m.typeIds).toSet();
  final program = ProgramGenerator(
    catalog: catalog,
    availableTypes: types,
    profile: const TrainingProfile(daysPerWeek: 4, sessionMinutes: 55, bodyweightKg: 78, sex: Sex.male, age: 32),
    level: UserLevel.intermediate,
    goal: UserGoal.hypertrophy,
  ).generate(now: t.subtract(const Duration(days: 26)));
  final byId = {for (final e in catalog) e.id: e};
  final rnd = math.Random(4);
  var day = 0;
  for (int k = 0; k < 14; k++) {
    day += [2, 1, 2, 2][k % 4];
    final start = t.subtract(Duration(days: 28 - day, hours: 4));
    final r = program.routines[k % program.routines.length];
    final sid = 'demo$k';
    var minute = 0;
    var total = 0.0, n = 0;
    for (final it in r.workout) {
      final ex = byId[it.exerciseId]!;
      final m = kDemoMachines.where((m) => m.typeIds.contains(ex.equipmentId) || ex.altEquipment.any(m.typeIds.contains)).firstOrNull;
      final base = (ex.category == 'compound' ? 45.0 : 22.5) * (ex.id == 'leg_press' ? 2.6 : 1);
      final w = ((base * (1 + 0.012 * k)) / 2.5).round() * 2.5;
      for (int i = 1; i <= it.sets; i++) {
        final reps = 11 - i + (k ~/ 4) - rnd.nextInt(2);
        sets.sets.add(SetLog(
          id: '$sid-${it.exerciseId}-$i',
          sessionId: sid,
          exerciseId: it.exerciseId,
          setNumber: i,
          weight: w,
          reps: reps.clamp(6, 15),
          rpe: 7 + i ~/ 2 + rnd.nextInt(2),
          completed: true,
          performedAt: start.add(Duration(minutes: minute += 3)),
          machineId: m?.id,
          technique: 'work',
        ));
        total += w * reps;
        n++;
      }
    }
    sessions.sessions.add(WorkoutSession(
      id: sid,
      routineId: r.id,
      startedAt: start,
      finishedAt: start.add(Duration(minutes: minute + 5)),
      perceivedExertion: 7 + rnd.nextInt(2),
      totalSets: n,
      totalVolume: total,
    ));
  }
  return program;
}
