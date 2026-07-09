// Settings del usuario (también se guardan en SharedPreferences, este modelo es para DB snapshot)
enum UserLevel { beginner, intermediate, advanced }
enum UserGoal { hypertrophy, strength, maintenance, definition }
enum WeightUnits { kg, lb }

class UserSettings {
  final UserLevel level;
  final UserGoal goal;
  final WeightUnits units;
  final String locale;
  final DateTime? planStartDate;
  final int currentWeek;
  final bool currentDeload;

  const UserSettings({
    required this.level,
    required this.goal,
    required this.units,
    required this.locale,
    this.planStartDate,
    required this.currentWeek,
    required this.currentDeload,
  });

  factory UserSettings.initial() => const UserSettings(
    level: UserLevel.intermediate,
    goal: UserGoal.hypertrophy,
    units: WeightUnits.kg,
    locale: 'es',
    currentWeek: 1,
    currentDeload: false,
  );

  UserSettings copyWith({
    UserLevel? level,
    UserGoal? goal,
    WeightUnits? units,
    String? locale,
    DateTime? planStartDate,
    int? currentWeek,
    bool? currentDeload,
  }) => UserSettings(
    level: level ?? this.level,
    goal: goal ?? this.goal,
    units: units ?? this.units,
    locale: locale ?? this.locale,
    planStartDate: planStartDate ?? this.planStartDate,
    currentWeek: currentWeek ?? this.currentWeek,
    currentDeload: currentDeload ?? this.currentDeload,
  );

  Map<String, dynamic> toMap() => {
    'level': level.name,
    'goal': goal.name,
    'units': units.name,
    'locale': locale,
    'plan_start_date': planStartDate?.millisecondsSinceEpoch,
    'current_week': currentWeek,
    'current_deload': currentDeload ? 1 : 0,
  };

  factory UserSettings.fromMap(Map<String, dynamic> m) => UserSettings(
    level: UserLevel.values.firstWhere(
      (e) => e.name == m['level'],
      orElse: () => UserLevel.intermediate,
    ),
    goal: UserGoal.values.firstWhere(
      (e) => e.name == m['goal'],
      orElse: () => UserGoal.hypertrophy,
    ),
    units: WeightUnits.values.firstWhere(
      (e) => e.name == m['units'],
      orElse: () => WeightUnits.kg,
    ),
    locale: m['locale'] as String? ?? 'es',
    planStartDate: m['plan_start_date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['plan_start_date'] as int)
        : null,
    currentWeek: m['current_week'] as int? ?? 1,
    currentDeload: (m['current_deload'] as int? ?? 0) == 1,
  );
}
