// Renderiza las pantallas nuevas para detectar errores de layout/estado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superfit/core/providers.dart';
import 'package:superfit/features/gym/gym_machines_screen.dart';
import 'package:superfit/features/gym/program_screen.dart';
import 'package:superfit/features/gym/training_profile_screen.dart';
import 'package:superfit/features/settings/how_it_works_screen.dart';

Future<void> _pump(WidgetTester t, Widget w, [ProviderContainer? c]) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.6;
  addTearDown(t.view.reset);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c ?? ProviderContainer(),
    child: MaterialApp(theme: ThemeData.dark(), home: w),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Mis máquinas: vacío → circuito Technogym → lista', (t) async {
    final c = ProviderContainer();
    await _pump(t, const GymMachinesScreen(), c);
    expect(find.text('Añade las máquinas de tu gimnasio'), findsOneWidget);
    await t.tap(find.text('Añadir un circuito Technogym'));
    await t.pumpAndSettle();
    await t.tap(find.text('Chest Press'));
    await t.tap(find.text('Incline Chest Press'));
    await t.pumpAndSettle();
    await t.tap(find.text('Añadir 2'));
    await t.pumpAndSettle();
    expect(c.read(gymMachinesProvider), hasLength(2));
    expect(find.text('Selection 700 Chest Press'), findsOneWidget);
  });

  testWidgets('Editor de máquina detecta el tipo por el nombre', (t) async {
    final c = ProviderContainer();
    await _pump(t, const MachineEditScreen(), c);
    await t.enterText(find.byType(TextField).first, 'Technogym Selection 700 Leg Curl');
    await t.pumpAndSettle();
    expect(find.text('detectado'), findsOneWidget);
    await t.ensureVisible(find.text('Guardar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();
    final m = c.read(gymMachinesProvider).single;
    expect(m.typeIds, ['leg_curl']);
  });

  testWidgets('Perfil y programa se generan sin errores', (t) async {
    final c = ProviderContainer();
    await _pump(t, const TrainingProfileScreen(), c);
    await t.tap(find.text('Rodilla'));
    await t.pumpAndSettle();
    expect(c.read(trainingProfileProvider).injuries, contains('knee'));

    await _pump(t, const ProgramScreen(), c);
    await t.ensureVisible(find.text('Generar'));
    await t.tap(find.text('Generar'));
    await t.pumpAndSettle();
    expect(c.read(programProvider), isNotNull);
    expect(find.text('Por qué este programa'), findsOneWidget);
  });

  testWidgets('Cómo decide la app', (t) async {
    await _pump(t, const HowItWorksScreen());
    expect(find.textContaining('PMID'), findsWidgets);
  });
}
