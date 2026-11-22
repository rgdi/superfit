// Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/catalog_repo.dart';
import '../data/repositories/session_repo.dart';
import '../data/repositories/set_repo.dart';
import '../data/repositories/photo_repo.dart';
import '../data/repositories/body_metric_repo.dart';
import '../data/repositories/settings_repo.dart';
import '../data/models/user_settings.dart';
import '../data/models/gym_machine.dart';
import '../data/models/training_profile.dart';
import '../data/models/generated_program.dart';
import '../data/models/exercise.dart';
import '../data/repositories/gym_repo.dart';
import 'package:sqflite/sqflite.dart';
import 'db/db_helper.dart';
import '../domain/usecases/progression_service.dart';

final gymRepoProvider = Provider<GymRepo>((ref) => GymRepo());
final catalogRepoProvider = Provider<CatalogRepo>((ref) => CatalogRepo(ref.read(gymRepoProvider)));
final sessionRepoProvider = Provider<SessionRepo>((ref) => SessionRepo());
final setRepoProvider = Provider<SetRepo>((ref) => SetRepo());
final photoRepoProvider = Provider<PhotoRepo>((ref) => PhotoRepo());
final bodyMetricRepoProvider = Provider<BodyMetricRepo>((ref) => BodyMetricRepo());
final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo());

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>(
  (ref) => UserSettingsNotifier(ref.read(settingsRepoProvider)),
);

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final SettingsRepo _repo;
  UserSettingsNotifier(this._repo) : super(UserSettings.initial()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> update(UserSettings s) async {
    state = s;
    await _repo.save(s);
  }

  Future<void> markOnboardingDone() async {
    await _repo.markOnboardingDone();
  }

  Future<void> reset() async {
    await _repo.reset();
    state = UserSettings.initial();
  }
}

final progressionServiceProvider = Provider<ProgressionService>(
  (ref) => ProgressionService(ref.read(setRepoProvider)),
);

final cyclePlannerProvider = Provider<dynamic>((ref) {
  return null; // se inicializa en un provider async
});


final databaseProvider = FutureProvider<Database>((ref) async {
  return DBHelper.database;
});

final allSessionsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(sessionRepoProvider).recentSessions(limit: 100);
});

final onboardingDoneProvider = FutureProvider<bool>(
  (ref) => ref.read(settingsRepoProvider).isOnboardingDone(),
);


// ---------------------------------------------------------------------------
// Mi gimnasio: máquinas, perfil y programa generado
// ---------------------------------------------------------------------------

final gymMachinesProvider = StateNotifierProvider<GymMachinesNotifier, List<GymMachine>>(
  (ref) => GymMachinesNotifier(ref.read(gymRepoProvider)),
);

class GymMachinesNotifier extends StateNotifier<List<GymMachine>> {
  final GymRepo _repo;
  GymMachinesNotifier(this._repo) : super(const []) {
    _repo.machines().then((m) {
      if (mounted) state = m;
    });
  }

  Future<void> upsert(GymMachine m) async {
    final i = state.indexWhere((x) => x.id == m.id);
    state = i < 0 ? [...state, m] : [...state.sublist(0, i), m, ...state.sublist(i + 1)];
    await _repo.saveMachines(state);
  }

  Future<void> addAll(List<GymMachine> ms) async {
    state = [...state, ...ms];
    await _repo.saveMachines(state);
  }

  Future<void> remove(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _repo.saveMachines(state);
  }

  Future<void> reload() async => state = await _repo.machines();
}

/// Tipos de máquina disponibles (null = el usuario aún no configuró nada).
Set<String>? availableMachineTypes(List<GymMachine> machines) =>
    machines.isEmpty ? null : machines.expand((m) => m.typeIds).toSet();

/// Máquina del usuario con la que se hace un ejercicio (si la tiene).
GymMachine? machineForExercise(Exercise ex, List<GymMachine> machines) {
  for (final m in machines) {
    if (m.typeIds.contains(ex.equipmentId)) return m;
  }
  for (final m in machines) {
    if (ex.altEquipment.any(m.typeIds.contains)) return m;
  }
  return null;
}

final trainingProfileProvider = StateNotifierProvider<TrainingProfileNotifier, TrainingProfile>(
  (ref) => TrainingProfileNotifier(ref.read(gymRepoProvider)),
);

class TrainingProfileNotifier extends StateNotifier<TrainingProfile> {
  final GymRepo _repo;
  TrainingProfileNotifier(this._repo) : super(const TrainingProfile()) {
    _repo.profile().then((p) {
      if (mounted) state = p;
    });
  }

  Future<void> update(TrainingProfile p) async {
    state = p;
    await _repo.saveProfile(p);
  }
}

final programProvider = StateNotifierProvider<ProgramNotifier, GeneratedProgram?>(
  (ref) => ProgramNotifier(ref.read(gymRepoProvider)),
);

class ProgramNotifier extends StateNotifier<GeneratedProgram?> {
  final GymRepo _repo;
  ProgramNotifier(this._repo) : super(null) {
    _repo.program().then((p) {
      if (mounted) state = p;
    });
  }

  Future<void> set(GeneratedProgram? p) async {
    state = p;
    await _repo.saveProgram(p);
  }
}
