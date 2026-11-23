import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/data/models/exercise.dart';
import 'package:superfit/data/models/generated_program.dart';
import 'package:superfit/data/models/training_profile.dart';
import 'package:superfit/data/models/user_settings.dart';
import 'package:superfit/domain/engine/load_engine.dart';
import 'package:superfit/domain/engine/machine_matcher.dart';
import 'package:superfit/domain/engine/program_coach.dart';
import 'package:superfit/domain/engine/program_generator.dart';

List<Exercise> _catalog() {
  final raw = File('assets/data/exercises.json').readAsStringSync();
  return (jsonDecode(raw) as List).map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
}

List<SetRecord> _session(String id, DateTime at, double w, List<int> reps, int? rpe) => [
      for (int i = 0; i < reps.length; i++)
        SetRecord(sessionId: id, weight: w, reps: reps[i], rpe: rpe, at: at.add(Duration(minutes: 3 * i))),
    ];

void main() {
  final stack = MachineSpec(minWeight: 5, maxWeight: 100, increment: 5);

  group('LoadEngine', () {
    test('e1RM con RIR: 100 kg × 5 a RPE 8 ≈ 100×(1+7/30)', () {
      expect(LoadEngine.e1rm(100, 5, 8), closeTo(123.3, 0.1));
      expect(LoadEngine.loadFor(LoadEngine.e1rm(100, 5, 8), 5, 8), closeTo(100, 0.01));
    });

    test('redondea a las placas de la máquina', () {
      expect(LoadEngine.roundTo(42, stack), 40);
      expect(LoadEngine.roundTo(43, stack), 45);
      expect(LoadEngine.roundTo(43, stack, mode: RoundMode.down), 40);
      expect(LoadEngine.roundTo(140, stack), 100);
      expect(LoadEngine.roundTo(1, stack), 5);
    });

    test('lista de pesos escrita a mano', () {
      expect(parseWeightList('5, 10, 15, 22,5'), [5, 10, 15, 22.5]);
      expect(parseWeightList('5 10 22.5'), [5, 10, 22.5]);
      expect(parseWeightList('5,10,15'), [5, 10, 15]);
      expect(parseWeightList('5; 10; 12,5'), [5, 10, 12.5]);
      expect(parseWeightList('  '), isEmpty);
    });

    test('pila irregular + microcargas', () {
      final m = MachineSpec(stack: [5, 10, 15, 22.5, 30], addOns: [2.5]);
      expect(m.weights, [5, 7.5, 10, 12.5, 15, 17.5, 22.5, 25, 30, 32.5]);
      expect(m.up(17.5), 22.5);
      expect(m.down(22.5), 17.5);
      expect(m.round(20), 17.5); // empate → hacia abajo (más seguro)
      expect(m.round(21), 22.5);
      expect(m.round(20, mode: RoundMode.up), 22.5);
      final p = LoadEngine.nextSession(
          history: _session('s', DateTime(2026, 1, 1), 15, [14, 14, 14], 8),
          repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 10, machine: m);
      expect(p.weight, 17.5); // siguiente peso real, no 15 + "salto"
    });

    test('sin historial → calibración con peso conservador redondeado hacia abajo', () {
      final p = LoadEngine.nextSession(
          history: const [], repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 33, machine: stack);
      expect(p.action, LoadAction.calibrate);
      expect(p.weight, 30);
    });

    test('todas las series al tope del rango a buen RPE → sube carga', () {
      final h = _session('s1', DateTime(2026, 1, 10), 40, [12, 12, 12], 8);
      final p = LoadEngine.nextSession(
          history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: MachineSpec(increment: 2.5));
      expect(p.action, LoadAction.increase);
      expect(p.weight, 42.5);
      expect(p.targetReps, 8);
    });

    test('salto de placa demasiado grande: amplía el rango antes de subir', () {
      // 40 kg × 12 a RPE 8 → e1RM ≈ 58,7. Con 45 kg a RPE 8 harían ~7 reps (< 8)
      final h = _session('s1', DateTime(2026, 1, 10), 40, [12, 12, 12], 8);
      final big = MachineSpec(minWeight: 5, maxWeight: 100, increment: 5);
      final p = LoadEngine.nextSession(history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: big);
      expect(p.action, LoadAction.addReps);
      expect(p.weight, 40);
      expect(p.targetReps, 13);
      expect(p.reason, contains('salto grande'));
      // Con microcarga de 2,5 kg sí sube (42,5 → ~9 reps)
      final micro = MachineSpec(minWeight: 5, maxWeight: 100, increment: 5, addOns: [2.5]);
      final q = LoadEngine.nextSession(history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: micro);
      expect(q.action, LoadAction.increase);
      expect(q.weight, 42.5);
      // Cuando ya hace 14 reps, sube aunque el salto sea grande
      final h2 = _session('s2', DateTime(2026, 1, 20), 40, [14, 14, 14], 8);
      final r = LoadEngine.nextSession(history: h2, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: big);
      expect(r.action, LoadAction.increase);
      expect(r.weight, 45);
    });

    test('las sesiones de descarga no sirven de referencia', () {
      final h = [
        ..._session('a', DateTime(2026, 1, 1), 50, [12, 11, 10], 9),
        // descarga: 45 kg, pocas series, RPE bajo
        ...[for (final r in _session('d', DateTime(2026, 1, 8), 45, [10, 10], 6))
          SetRecord(sessionId: r.sessionId, weight: r.weight, reps: r.reps, rpe: r.rpe, at: r.at, deload: true)],
      ];
      final p = LoadEngine.nextSession(history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20,
          machine: MachineSpec(increment: 2.5));
      expect(p.previousWeight, 50); // referencia = última sesión normal
      expect(p.weight, 50);
    });

    test('top set + back-off: el peso de trabajo es el del top set', () {
      final h = [
        SetRecord(sessionId: 's', weight: 50, reps: 10, rpe: 8, at: DateTime(2026, 1, 1, 10), technique: 'work'),
        SetRecord(sessionId: 's', weight: 45, reps: 10, rpe: 8, at: DateTime(2026, 1, 1, 10, 3), technique: 'backoff'),
        SetRecord(sessionId: 's', weight: 45, reps: 10, rpe: 8, at: DateTime(2026, 1, 1, 10, 6), technique: 'backoff'),
      ];
      final p = LoadEngine.nextSession(history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20,
          machine: MachineSpec(increment: 2.5));
      expect(p.weight, 50); // antes bajaba a 45 cada vez
    });

    test('demasiado fácil (RPE ≥2 por debajo): sube sin esperar al tope del rango', () {
      final h = _session('s', DateTime(2026, 1, 1), 40, [10, 10, 10], 5);
      final p = LoadEngine.nextSession(history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20,
          machine: MachineSpec(increment: 2.5));
      expect(p.action, LoadAction.increase);
      expect(p.weight, greaterThan(40));
    });

    test('salto enorme (+50 %): no sube, progresa por reps y tempo', () {
      final h = _session('s', DateTime(2026, 1, 1), 5, [15, 15, 15], 8);
      final p = LoadEngine.nextSession(history: h, repMin: 10, repMax: 15, rpeTarget: 8, coldStartWeight: 5,
          machine: MachineSpec(minWeight: 5, maxWeight: 50, increment: 2.5));
      expect(p.weight, 5);
      expect(p.reason, contains('demasiado salto'));
    });

    test('dentro del rango → mismo peso, +1 rep', () {
      final h = _session('s1', DateTime(2026, 1, 10), 40, [10, 9, 9], 8);
      final p = LoadEngine.nextSession(
          history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: stack);
      expect(p.action, LoadAction.addReps);
      expect(p.weight, 40);
      expect(p.targetReps, 10);
    });

    test('no llega al mínimo de reps → baja', () {
      final h = _session('s1', DateTime(2026, 1, 10), 60, [7, 6, 5], 10);
      final p = LoadEngine.nextSession(
          history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: stack);
      expect(p.action, LoadAction.decrease);
      expect(p.weight, lessThan(60));
    });

    test('en el máximo de la pila → maxedOut', () {
      final h = _session('s1', DateTime(2026, 1, 10), 100, [12, 12, 12], 7);
      final p = LoadEngine.nextSession(
          history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: stack);
      expect(p.action, LoadAction.maxedOut);
      expect(p.weight, 100);
    });

    test('meseta: 4 sesiones en ≥18 días sin mejorar e1RM', () {
      final h = [
        ..._session('a', DateTime(2026, 1, 1), 40, [10, 10], 8),
        ..._session('b', DateTime(2026, 1, 8), 40, [10, 10], 8),
        ..._session('c', DateTime(2026, 1, 15), 40, [10, 10], 8),
        ..._session('d', DateTime(2026, 1, 22), 40, [10, 10], 8),
      ];
      final p = LoadEngine.nextSession(
          history: h, repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 20, machine: stack);
      expect(p.plateau, isTrue);
    });

    test('calibración: 1ª serie demasiado fácil → sube la siguiente', () {
      final next = LoadEngine.adjustNextSet(
          weight: 20, reps: 12, rpe: 5, repMin: 8, repMax: 12, rpeTarget: 8, calibrating: true);
      expect(next, isNotNull);
      expect(next!, greaterThan(20));
    });

    test('sesión normal: desviación pequeña de RPE no cambia el peso', () {
      final next = LoadEngine.adjustNextSet(
          weight: 40, reps: 10, rpe: 9, repMin: 8, repMax: 12, rpeTarget: 8, machine: stack);
      expect(next, isNull);
    });
  });

  group('MachineMatcher', () {
    test('reconoce nombres Technogym', () {
      expect(MachineMatcher.guessTypes('Technogym Selection 700 Chest Press'), ['chest_press']);
      expect(MachineMatcher.guessTypes('Technogym Pure Strength Incline Chest Press'), ['incline_chest_press']);
      expect(MachineMatcher.guessTypes('Technogym Selection Low Row'), ['seated_row']);
      expect(MachineMatcher.guessTypes('Technogym Multi Hip'), contains('hip_adductor'));
      expect(MachineMatcher.guessTypes('Selection 900 Leg Curl'), ['leg_curl']);
      expect(MachineMatcher.guessTypes('Lateral Raise'), ['lateral_raise']);
      expect(MachineMatcher.guessTypes('Lat Machine'), ['lat_pulldown']);
    });
    test('reconoce nombres en español', () {
      expect(MachineMatcher.guessTypes('Prensa de piernas'), ['leg_press']);
      expect(MachineMatcher.guessTypes('Polea de jalón al pecho'), ['lat_pulldown']);
      expect(MachineMatcher.guessTypes('Remo con apoyo de pecho'), ['seated_row']);
      expect(MachineMatcher.guessTypes('Press de pecho'), ['chest_press']);
      expect(MachineMatcher.guessTypes('Máquina de femoral tumbado'), ['leg_curl']);
      expect(MachineMatcher.guessTypes('cosa rara'), isEmpty);
    });
    test('autocompletado', () {
      expect(MachineMatcher.suggestions('chest').first, contains('Chest Press'));
    });
  });

  group('ProgramGenerator', () {
    final catalog = _catalog();

    test('4 días → Torso/Pierna con 4 rutinas y todos los ejercicios existen', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 4, sessionMinutes: 60),
        level: UserLevel.intermediate,
        goal: UserGoal.hypertrophy,
      ).generate(now: DateTime(2026, 1, 5));
      expect(g.routines, hasLength(4));
      expect(g.splitName, contains('Torso'));
      final ids = catalog.map((e) => e.id).toSet();
      for (final r in g.routines) {
        expect(r.workout, isNotEmpty);
        for (final it in r.workout) {
          expect(ids, contains(it.exerciseId));
        }
        expect(r.estimatedMinutes, lessThanOrEqualTo(60));
      }
    });

    test('respeta máquinas disponibles', () {
      final types = {'chest_press', 'lat_pulldown', 'leg_press', 'leg_curl', 'shoulder_press'};
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: types,
        profile: const TrainingProfile(daysPerWeek: 3, sessionMinutes: 60),
        level: UserLevel.beginner,
        goal: UserGoal.hypertrophy,
      ).generate();
      for (final r in g.routines) {
        for (final it in r.workout) {
          final ex = catalog.firstWhere((e) => e.id == it.exerciseId);
          expect(ex.usableWith(types), isTrue, reason: ex.id);
        }
      }
      expect(g.rationale.join(' '), contains('Sin ninguna máquina para'));
    });

    test('excluye ejercicios contraindicados por lesión de rodilla', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 4, injuries: {'knee'}),
        level: UserLevel.intermediate,
        goal: UserGoal.hypertrophy,
      ).generate();
      final used = g.routines.expand((r) => r.workout).map((i) => i.exerciseId).toSet();
      expect(used, isNot(contains('leg_extension')));
      expect(used, isNot(contains('hack_squat')));
      // leg_press solo está contraindicado en casos graves → se permite con nota
      final lp = g.routines.expand((r) => r.workout).where((i) => i.exerciseId == 'leg_press');
      expect(lp, isNotEmpty);
      expect(lp.first.notesEs, contains('sin dolor'));
    });

    test('molestia de hombro no elimina todo el pecho', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 4, injuries: {'shoulder'}),
        level: UserLevel.intermediate,
        goal: UserGoal.hypertrophy,
      ).generate();
      expect(g.weeklySets['chest'] ?? 0, greaterThan(0));
      final used = g.routines.expand((r) => r.workout).map((i) => i.exerciseId).toSet();
      expect(used, isNot(contains('pec_deck'))); // shoulder_impingement (no grave) → fuera
    });

    test('isquios: curl femoral antes que extensión lumbar', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 4, sessionMinutes: 90),
        level: UserLevel.intermediate,
        goal: UserGoal.hypertrophy,
      ).generate();
      // El isquio se entrena con curl femoral (no solo con extensión lumbar)
      final lower = g.routines[1].workout.map((i) => i.exerciseId).toList();
      expect(lower, contains('leg_curl'));
    });

    test('poco tiempo recorta series pero mantiene ≥2 por ejercicio', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 2, sessionMinutes: 35),
        level: UserLevel.advanced,
        goal: UserGoal.hypertrophy,
      ).generate();
      for (final r in g.routines) {
        expect(r.estimatedMinutes, lessThanOrEqualTo(36));
        expect(r.workout.every((i) => i.sets >= 2), isTrue);
      }
    });

    test('prioridad aumenta series del grupo', () {
      GeneratedProgram gen(Set<String> pr) => ProgramGenerator(
            catalog: catalog,
            availableTypes: null,
            profile: TrainingProfile(daysPerWeek: 4, sessionMinutes: 120, priorities: pr),
            level: UserLevel.intermediate,
            goal: UserGoal.hypertrophy,
          ).generate();
      expect(gen({'glutes'}).weeklySets['glutes']!, greaterThan(gen({}).weeklySets['glutes']!));
    });

    test('serializa y deserializa', () {
      final g = ProgramGenerator(
        catalog: catalog,
        availableTypes: null,
        profile: const TrainingProfile(daysPerWeek: 5),
        level: UserLevel.intermediate,
        goal: UserGoal.strength,
      ).generate();
      final back = GeneratedProgram.decode(g.encode())!;
      expect(back.routines.length, g.routines.length);
      expect(back.rotation, g.rotation);
      expect(back.routines.first.workout.first.repsTarget, g.routines.first.workout.first.repsTarget);
    });
  });

  group('ProgramCoach', () {
    final catalog = _catalog();
    final program = ProgramGenerator(
      catalog: catalog,
      availableTypes: null,
      profile: const TrainingProfile(daysPerWeek: 4, mesocycleWeeks: 5),
      level: UserLevel.intermediate,
      goal: UserGoal.hypertrophy,
    ).generate(now: DateTime(2026, 1, 5));
    final coach = ProgramCoach(program);

    test('semana del ciclo correcta en el cambio de hora (lunes)', () {
      final p = GeneratedProgram.decode(program.copyWith(startDate: DateTime(2026, 3, 23)).encode())!;
      expect(p.weekFor(DateTime(2026, 3, 30)), 2); // lunes tras el cambio de hora de primavera
      expect(p.weekFor(DateTime(2026, 3, 29)), 1); // domingo anterior
    });

    test('RPE sube por semana y la última es descarga', () {
      expect(coach.rpeForWeek(1), 7);
      expect(coach.rpeForWeek(4), 9);
      expect(coach.rpeForWeek(5), 6);
      expect(program.isDeloadWeek(DateTime(2026, 2, 2)), isTrue); // semana 5
    });

    test('rotación: tras gen_1 toca gen_2; si faltas días no se salta', () {
      final r = coach.nextRoutine([FinishedSessionInfo(program.rotation[0], DateTime(2026, 1, 5), 8)]);
      expect(r.id, program.rotation[1]);
      expect(coach.nextRoutine([FinishedSessionInfo(program.rotation[3], DateTime(2026, 1, 5), 8)]).id, program.rotation[0]);
      expect(coach.nextRoutine(const []).id, program.rotation[0]);
    });

    test('descarga: mitad de series; cansado: −1 serie y RPE −1', () {
      final r = program.routines.first;
      final d = coach.adapt(r, date: DateTime(2026, 2, 2));
      expect(d.workout.first.sets, (r.workout.first.sets / 2).ceil());
      expect(d.workout.first.rpeTarget, 6);
      final low = coach.adapt(r, date: DateTime(2026, 1, 20), readiness: Readiness.low);
      expect(low.workout.first.sets, r.workout.first.sets > 2 ? r.workout.first.sets - 1 : 2);
      expect(low.workout.first.rpeTarget, coach.rpeForWeek(3) - 1);
    });

    test('rotación robusta: si cambias el orden, no se salta ninguna sesión', () {
      final recent = [
        FinishedSessionInfo(program.rotation[2], DateTime(2026, 1, 7), 8), // hizo la 3 antes que la 2
        FinishedSessionInfo(program.rotation[0], DateTime(2026, 1, 5), 8),
      ];
      expect(coach.nextRoutine(recent).id, program.rotation[1]);
    });

    test('si los músculos de la sesión siguiente siguen fatigados, propone otra', () {
      final cat = {for (final e in catalog) e.id: e.primaryMuscles};
      final next = coach.nextRoutine(const []); // gen_1 = Torso A
      final fatigued = {
        for (final it in next.workout)
          for (final m in cat[it.exerciseId]!) m: 0.2,
      };
      final rec = {
        for (final m in ['quadriceps', 'hamstrings', 'gluteus_maximus', 'gastrocnemius', 'soleus', 'adductors',
          'gluteus_medius', 'rectus_abdominis', 'obliques', 'erector_spinae']) m: 1.0,
        ...fatigued,
      };
      final a = coach.adviseToday(now: DateTime(2026, 1, 6), recent: const [], daysPerWeek: 4, recovery: rec, primaryOf: cat);
      expect(a.routine!.nameEs, startsWith('Pierna'));
      expect(a.notes.join(' '), contains('recuperando'));
    });

    test('semana completada → sugiere descanso', () {
      final now = DateTime(2026, 1, 9); // viernes
      final recent = [
        for (int d = 5; d <= 8; d++) FinishedSessionInfo(program.rotation[d - 5], DateTime(2026, 1, d, 18), 8),
      ].reversed.toList();
      final a = coach.adviseToday(now: now, recent: recent, daysPerWeek: 4);
      expect(a.suggestRest, isTrue);
    });
  });
}
