// Capturas de todas las pantallas con fuentes reales y datos de ejemplo.
// Solo se ejecuta si se define SHOTS_DIR:
//   SHOTS_DIR=/ruta flutter test test/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superfit/core/providers.dart';
import 'package:superfit/data/models/gym_machine.dart';
import 'package:superfit/data/models/training_profile.dart';
import 'package:superfit/data/models/workout_session.dart';
import 'package:superfit/data/repositories/catalog_repo.dart';
import 'package:superfit/data/repositories/gym_repo.dart';
import 'package:superfit/main.dart';
import 'support/fakes.dart';

final String? _dir = Platform.environment['SHOTS_DIR'];

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final fontsDir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final inter = FontLoader('Inter');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    inter.addFont(Future.value(ByteData.view(File('assets/fonts/Inter-$f.otf').readAsBytesSync().buffer)));
  }
  await inter.load();
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Black', 'Light']) {
    roboto.addFont(Future.value(ByteData.view(File('$fontsDir/Roboto-$f.ttf').readAsBytesSync().buffer)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(File('$fontsDir/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
  // Emoji: si el sistema tiene Noto Color Emoji, úsala (si no, se verán cuadros)
  for (final p in ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf', '/usr/share/fonts/noto/NotoColorEmoji.ttf']) {
    if (File(p).existsSync()) {
      final e = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.view(File(p).readAsBytesSync().buffer)));
      await e.load();
    }
  }
}

void main() {
  if (_dir == null) {
    test('capturas (desactivado: define SHOTS_DIR)', () {}, skip: true);
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSessionRepo sessions;
  late FakeSetRepo sets;

  setUpAll(() async {
    await _loadFonts();
    await CatalogRepo().exercises();
    await CatalogRepo().routines();
    await CatalogRepo().machines();
    await CatalogRepo().muscles();
  });

  Future<ProviderContainer> setup() async {
    sessions = FakeSessionRepo();
    sets = FakeSetRepo();
    final program = seedDemo(sessions, sets, loadCatalog());
    sessions.sessions.add(WorkoutSession(id: 'live', routineId: program.routines[2].id, startedAt: DateTime.now()));
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'level': 'intermediate',
      'goal': 'hypertrophy',
      'plan_start': DateTime.now().subtract(const Duration(days: 26)).millisecondsSinceEpoch,
      GymRepo.kMachines: GymMachine.encodeList(kDemoMachines),
      GymRepo.kProfile: const TrainingProfile(daysPerWeek: 4, sessionMinutes: 55, bodyweightKg: 78, sex: Sex.male, age: 32).encode(),
      GymRepo.kProgram: program.encode(),
      'readiness_live': 'normal',
    });
    return ProviderContainer(overrides: [
      sessionRepoProvider.overrideWithValue(sessions),
      setRepoProvider.overrideWithValue(sets),
      bodyMetricRepoProvider.overrideWithValue(FakeBodyMetricRepo()),
      photoRepoProvider.overrideWithValue(FakePhotoRepo()),
    ]);
  }

  Future<void> settle(WidgetTester t, [int steps = 30]) async {
    for (int i = 0; i < steps; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 8)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name, String location, {Future<void> Function()? before}) async {
    // Móvil típico: 393 × 852 dp
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final c = await setup();
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(393, 852), devicePixelRatio: 3, padding: EdgeInsets.only(top: 47, bottom: 34)),
          child: SuperFitApp(initialLocation: location),
        ),
      ),
    ));
    await settle(t);
    // Precargar fotos visibles
    await t.runAsync(() async {
      for (final e in t.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, key.currentContext!);
      }
    });
    await settle(t, 10);
    if (before != null) {
      await before();
      await settle(t, 20);
    }
    await t.runAsync(() async {
      final img = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
    await settle(t, 3);
  }

  final screens = <String, String>{
    '01_home': '/',
    '02_workout': '/workout/live',
    '03_exercise': '/exercises/leg_press',
    '04_muscles': '/muscles',
    '05_efficient': '/muscles?tab=machines',
    '06_program': '/program',
    '07_ai': '/ai',
    '08_machines': '/settings/machines',
    '09_settings': '/settings',
    '10_progress': '/progress',
    '11_history': '/history',
    '12_exercises': '/exercises',
    '13_routines': '/routines',
    '14_profile': '/settings/profile',
  };
  for (final e in screens.entries) {
    testWidgets('captura ${e.key}', (t) async => shot(t, e.key, e.value));
  }
}
