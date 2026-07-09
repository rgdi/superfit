// Repositorio de settings (persiste en DB fila única + SharedPreferences)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

class SettingsRepo {
  static const _kLevel = 'level';
  static const _kGoal = 'goal';
  static const _kUnits = 'units';
  static const _kLocale = 'locale';
  static const _kPlanStart = 'plan_start';
  static const _kCurrentWeek = 'current_week';
  static const _kCurrentDeload = 'current_deload';
  static const _kOnboardingDone = 'onboarding_done';

  Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      level: UserLevel.values.firstWhere(
        (e) => e.name == prefs.getString(_kLevel),
        orElse: () => UserLevel.intermediate,
      ),
      goal: UserGoal.values.firstWhere(
        (e) => e.name == prefs.getString(_kGoal),
        orElse: () => UserGoal.hypertrophy,
      ),
      units: WeightUnits.values.firstWhere(
        (e) => e.name == prefs.getString(_kUnits),
        orElse: () => WeightUnits.kg,
      ),
      locale: prefs.getString(_kLocale) ?? 'es',
      planStartDate: prefs.getInt(_kPlanStart) != null
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kPlanStart)!)
          : null,
      currentWeek: prefs.getInt(_kCurrentWeek) ?? 1,
      currentDeload: prefs.getBool(_kCurrentDeload) ?? false,
    );
  }

  Future<void> save(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLevel, settings.level.name);
    await prefs.setString(_kGoal, settings.goal.name);
    await prefs.setString(_kUnits, settings.units.name);
    await prefs.setString(_kLocale, settings.locale);
    if (settings.planStartDate != null) {
      await prefs.setInt(_kPlanStart, settings.planStartDate!.millisecondsSinceEpoch);
    }
    await prefs.setInt(_kCurrentWeek, settings.currentWeek);
    await prefs.setBool(_kCurrentDeload, settings.currentDeload);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
