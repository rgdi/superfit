// Flujo completo de la pantalla de entrenamiento con repositorios en memoria.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superfit/core/providers.dart';
import 'package:superfit/data/models/gym_machine.dart';
import 'package:superfit/data/models/set_log.dart';
import 'package:superfit/data/models/workout_session.dart';
import 'package:superfit/data/repositories/catalog_repo.dart';
import 'package:superfit/data/repositories/session_repo.dart';
import 'package:superfit/data/repositories/set_repo.dart';
import 'package:superfit/domain/ai/ai_service.dart';
import 'package:superfit/domain/ai/performance_model.dart';
import 'package:superfit/features/ai/ai_screen.dart';
import 'package:superfit/features/gym/machine_history_screen.dart';
import 'package:superfit/features/workout/workout_screen.dart';
import 'package:superfit/widgets/set_row.dart';

class FakeSessionRepo extends SessionRepo {
  final session = WorkoutSession(id: 'sess1', routineId: 'upper_a', startedAt: DateTime(2026, 3, 2, 18));
  int finished = 0;
  @override
  Future<WorkoutSession?> sessionById(String id) async => id == session.id ? session : null;
  @override
  Future<void> finishSession(String id, {int? perceivedExertion, String? notes, int? totalSets, double? totalVolume}) async =>
      finished++;
  @override
  Future<WorkoutSession?> activeSession() async => session;
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
      performedAt: DateTime(2026, 3, 2, 18, _n),
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
      sets.where((s) => s.exerciseId == exerciseId).toList().reversed.toList();
  @override
  Future<List<SetLog>> allCompleted() async => List.of(sets);
  @override
  Future<List<SetLog>> setsForMachine(String machineId) async => sets.where((s) => s.machineId == machineId).toList();
}

/// Historial previo de chest press en la máquina m1: 4 sesiones.
List<SetLog> _history() => [
      for (int d = 0; d < 4; d++)
        for (int i = 1; i <= 3; i++)
          SetLog(
            id: 'h$d$i',
            sessionId: 'old$d',
            exerciseId: 'chest_press_machine',
            setNumber: i,
            weight: 40,
            reps: 10 + (d > 1 ? 1 : 0) - (i - 1),
            rpe: 8,
            completed: true,
            performedAt: DateTime(2026, 2, 2 + d * 3, 18, i * 3),
            machineId: 'm1',
            technique: 'work',
          ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSetRepo setRepo;
  late ProviderContainer c;

  // Precarga los assets fuera del reloj simulado de testWidgets (rootBundle cachea).
  setUpAll(() async {
    await CatalogRepo().exercises();
    await CatalogRepo().routines();
    await CatalogRepo().machines();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'gym_machines_v1': GymMachine.encodeList([
        const GymMachine(
          id: 'm1',
          name: 'Technogym Artis Chest Press',
          typeIds: ['chest_press'],
          stack: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
          addOns: [2.5],
          setupNotes: 'Asiento 4',
        ),
      ]),
    });
    setRepo = FakeSetRepo()..sets.addAll(_history());
    c = ProviderContainer(overrides: [
      sessionRepoProvider.overrideWithValue(FakeSessionRepo()),
      setRepoProvider.overrideWithValue(setRepo),
    ]);
  });

  /// Avanza ~3 s de animaciones (hay animaciones en bucle: no usar pumpAndSettle).
  Future<void> settle(WidgetTester t) async {
    for (int i = 0; i < 30; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(theme: ThemeData.dark(), home: w),
    ));
    await settle(t);
  }

  test('observaciones: sin aproximaciones, drops fuera del índice', () {
    final sets = [
      SetLog(id: 'a', sessionId: 's', exerciseId: 'leg_press', setNumber: -1, weight: 50, reps: 8, completed: true,
          performedAt: DateTime(2026, 1, 1, 10, 0), technique: 'warmup'),
      SetLog(id: 'b', sessionId: 's', exerciseId: 'leg_press', setNumber: 1, weight: 100, reps: 10, rpe: 8,
          completed: true, performedAt: DateTime(2026, 1, 1, 10, 3)),
      SetLog(id: 'c', sessionId: 's', exerciseId: 'leg_press', setNumber: 101, weight: 70, reps: 12, completed: true,
          performedAt: DateTime(2026, 1, 1, 10, 6), technique: 'drop'),
      SetLog(id: 'd', sessionId: 's', exerciseId: 'leg_press', setNumber: 2, weight: 100, reps: 9, rpe: 9,
          completed: true, performedAt: DateTime(2026, 1, 1, 10, 9)),
    ];
    final obs = AiService.toObservations(sets, {}, {'s': 1});
    expect(obs, hasLength(3));
    expect(obs.where((o) => !o.isDrop).map((o) => o.setIndex), [0, 1]);
    expect(obs.first.readiness, 1);
  });

  testWidgets('entreno: peso de la pila real, serie guardada con máquina, aproximación y drop', (t) async {
    await pump(t, const WorkoutScreen(sessionId: 'sess1'));
    await c.read(gymMachinesProvider.notifier).reload();
    expect(find.text('Technogym Artis Chest Press'), findsOneWidget);
    expect(find.textContaining('Asiento 4'), findsOneWidget);
    // Hizo 11-10-9 a 40 → mismo peso o subida a un peso real de la pila
    final rows = t.widgetList<SetRow>(find.byType(SetRow)).toList();
    expect(rows, isNotEmpty);
    final spec = c.read(gymMachinesProvider).single.spec;
    for (final r in rows) {
      expect(spec.weights, contains(r.weight), reason: 'peso ${r.weight} no existe en la máquina');
    }
    // Completar la 1ª serie
    await t.tap(find.byIcon(Icons.radio_button_unchecked).first);
    await settle(t);
    final logged = setRepo.sets.where((s) => s.sessionId == 'sess1').toList();
    expect(logged, hasLength(1));
    expect(logged.single.machineId, 'm1');
    expect(logged.single.technique, 'work');
    // Desmarcar la borra
    await t.tap(find.byIcon(Icons.check_circle).first);
    await settle(t);
    expect(setRepo.sets.where((s) => s.sessionId == 'sess1'), isEmpty);
    // Aproximación (2 series) y drop
    await t.ensureVisible(find.text('+ Aproximación'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('+ Aproximación'));
    await settle(t);
    await t.ensureVisible(find.text('+ Drop set'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('+ Drop set'));
    await settle(t);
    await t.ensureVisible(find.text('A1'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    await t.ensureVisible(find.text('D'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('D'), findsOneWidget);
    // Top + back-off
    await t.ensureVisible(find.text('Series rectas'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Series rectas'));
    await settle(t);
    await t.tap(find.text('Top set + back-off (−10 %)'));
    await settle(t);
    final kinds = t.widgetList<SetRow>(find.byType(SetRow)).map((r) => r.kind).toList();
    expect(kinds, contains(SetKind.backoff));
    // Siguiente ejercicio (animación de transición)
    await t.dragUntilVisible(find.text('Siguiente'), find.byType(ListView).first, const Offset(0, -250));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Siguiente'));
    await settle(t);
    expect(find.text('Jalón al pecho (polea)'), findsWidgets);
  });

  testWidgets('pantalla Mi IA con datos', (t) async {
    await pump(t, const AiScreen());
    expect(find.textContaining('series aprendidas'), findsOneWidget);
    expect(find.text('Lo que ha aprendido de ti'), findsOneWidget);
  });

  testWidgets('historial de máquina con gráfica', (t) async {
    await c.read(gymMachinesProvider.notifier).reload();
    await pump(t, MachineHistoryScreen(machine: c.read(gymMachinesProvider).single));
    expect(find.text('Press de pecho en máquina'), findsOneWidget);
    expect(find.textContaining('1RM estimado por la IA'), findsOneWidget);
  });

  test('modelo entrenado con el historial falso conoce la máquina', () async {
    final m = await c.read(performanceModelProvider.future);
    expect(m.knows('chest_press_machine', 'm1'), isTrue);
    expect(m, isA<PerformanceModel>());
  });
}
