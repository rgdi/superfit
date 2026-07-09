// Modelo de Rutina (loaded from assets/data/routines/*.json)
import 'workout_item.dart';

class Routine {
  final String id;
  final String nameEs;
  final String nameEn;
  final int dayOfWeek;
  final int estimatedMinutes;
  final String level;
  final String goal;
  final List<WarmupItem> warmup;
  final List<WorkoutItem> workout;
  final List<CooldownItem> cooldown;

  const Routine({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.dayOfWeek,
    required this.estimatedMinutes,
    required this.level,
    required this.goal,
    required this.warmup,
    required this.workout,
    required this.cooldown,
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    dayOfWeek: j['day_of_week'] as int? ?? 1,
    estimatedMinutes: j['estimated_minutes'] as int,
    level: j['level'] as String? ?? 'intermediate',
    goal: j['goal'] as String? ?? 'hypertrophy',
    warmup: (j['warmup'] as List?)?.map((e) => WarmupItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    workout: (j['workout'] as List).map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>)).toList(),
    cooldown: (j['cooldown'] as List?)?.map((e) => CooldownItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  String localizedName(String locale) =>
      locale == 'en' ? nameEn : nameEs;
}

class WarmupItem {
  final String type; // mobility | activation
  final String nameEs;
  final String nameEn;
  final int durationSeconds;

  WarmupItem({required this.type, required this.nameEs, required this.nameEn, required this.durationSeconds});

  factory WarmupItem.fromJson(Map<String, dynamic> j) => WarmupItem(
    type: j['type'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    durationSeconds: j['duration_seconds'] as int,
  );

  String localizedName(String locale) => locale == 'en' ? nameEn : nameEs;
}

class CooldownItem {
  final String type;
  final String nameEs;
  final String nameEn;
  final int durationSeconds;

  CooldownItem({required this.type, required this.nameEs, required this.nameEn, required this.durationSeconds});

  factory CooldownItem.fromJson(Map<String, dynamic> j) => CooldownItem(
    type: j['type'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    durationSeconds: j['duration_seconds'] as int,
  );

  String localizedName(String locale) => locale == 'en' ? nameEn : nameEs;
}
