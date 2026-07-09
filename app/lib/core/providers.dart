// Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/catalog_repo.dart';
import '../data/repositories/session_repo.dart';
import '../data/repositories/set_repo.dart';
import '../data/repositories/photo_repo.dart';
import '../data/repositories/body_metric_repo.dart';
import '../data/repositories/settings_repo.dart';
import '../data/models/user_settings.dart';
import '../domain/usecases/progression_service.dart';

final catalogRepoProvider = Provider<CatalogRepo>((ref) => CatalogRepo());
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

final onboardingDoneProvider = FutureProvider<bool>(
  (ref) => ref.read(settingsRepoProvider).isOnboardingDone(),
);
