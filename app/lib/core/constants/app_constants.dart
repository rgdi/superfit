// Constantes globales de SuperFit
class AppConstants {
  static const String appName = 'SuperFit';
  static const String appVersion = '1.0.0';
  static const String dbName = 'superfit.db';
  static const int dbVersion = 1;

  // SharedPreferences keys
  static const String kOnboardingDone = 'onboarding_done';
  static const String kLevel = 'user_level';
  static const String kGoal = 'user_goal';
  static const String kUnits = 'user_units';
  static const String kLocale = 'user_locale';
  static const String kPlanStartDate = 'plan_start_date';
  static const String kCurrentWeek = 'current_week';
  static const String kCurrentDeload = 'current_deload';
  static const String kActiveSessionId = 'active_session_id';

  // Plan
  static const int kWeeksPerCycle = 4;
  static const int kTrainingDaysPerWeek = 4;

  // Adaptive thresholds
  static const double kRpeTargetLow = 7.0;
  static const double kRpeTargetHigh = 9.0;
  static const int kStagnationWeeks = 3;
  static const int kMaxConsecutiveMissedDays = 2;

  // Auto-regulation: peso delta cuando RPE muy alto
  static const double kWeightDeltaKg = 2.5;
  static const double kRpeReduceWeight = 9.0; // RPE > este valor -> -5% peso
  static const double kRpeIncreaseWeight = 7.0; // RPE < este valor -> +5% peso (si hits reps)

  // Sujerencias de imagen por defecto
  static const String kDefaultExerciseImage = 'assets/images/exercises/placeholder.png';
  static const String kDefaultMuscleImage = 'assets/images/muscles/placeholder.png';
  static const String kDefaultMachineImage = 'assets/images/machines/placeholder.png';
}
