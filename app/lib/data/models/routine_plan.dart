// Modelo del Plan de Rutinas (cargado desde assets/data/routine_plan.json)
import 'routine.dart';

class RoutinePlan {
  final String version;
  final String descriptionEs;
  final String descriptionEn;
  final String defaultLevel;
  final String defaultGoal;
  final List<PlanCycle> cycles;
  final Map<String, LevelModifier> levelModifiers;
  final Map<String, GoalModifier> goalModifiers;

  const RoutinePlan({
    required this.version,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.defaultLevel,
    required this.defaultGoal,
    required this.cycles,
    required this.levelModifiers,
    required this.goalModifiers,
  });

  factory RoutinePlan.fromJson(Map<String, dynamic> j) => RoutinePlan(
    version: j['version'] as String,
    descriptionEs: j['description_es'] as String? ?? '',
    descriptionEn: j['description_en'] as String? ?? '',
    defaultLevel: j['default_level'] as String,
    defaultGoal: j['default_goal'] as String,
    cycles: (j['cycles'] as List).map((e) => PlanCycle.fromJson(e as Map<String, dynamic>)).toList(),
    levelModifiers: (j['level_modifiers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, LevelModifier.fromJson(v as Map<String, dynamic>)),
    ),
    goalModifiers: (j['goal_modifiers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, GoalModifier.fromJson(v as Map<String, dynamic>)),
    ),
  );

  String localizedDescription(String locale) =>
      locale == 'en' ? descriptionEn : descriptionEs;
}

class PlanCycle {
  final int weekIndex;
  final String nameEs;
  final String nameEn;
  final String phase; // build | deload
  final double volumeModifier;
  final int rpeModifier;
  final List<DayAssignment> routineAssignments;

  const PlanCycle({
    required this.weekIndex,
    required this.nameEs,
    required this.nameEn,
    required this.phase,
    required this.volumeModifier,
    required this.rpeModifier,
    required this.routineAssignments,
  });

  factory PlanCycle.fromJson(Map<String, dynamic> j) => PlanCycle(
    weekIndex: j['week_index'] as int,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    phase: j['phase'] as String,
    volumeModifier: (j['volume_modifier'] as num).toDouble(),
    rpeModifier: j['rpe_modifier'] as int,
    routineAssignments: (j['routine_assignments'] as List)
        .map((e) => DayAssignment.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  String localizedName(String locale) => locale == 'en' ? nameEn : nameEs;
}

class DayAssignment {
  final int day;
  final String routineId;

  const DayAssignment({required this.day, required this.routineId});

  factory DayAssignment.fromJson(Map<String, dynamic> j) => DayAssignment(
    day: j['day'] as int,
    routineId: j['routine_id'] as String,
  );
}

class LevelModifier {
  final String defaultReps;
  final int rpeTarget;
  final double restModifier;

  const LevelModifier({
    required this.defaultReps,
    required this.rpeTarget,
    required this.restModifier,
  });

  factory LevelModifier.fromJson(Map<String, dynamic> j) => LevelModifier(
    defaultReps: j['default_reps'] as String,
    rpeTarget: j['rpe_target'] as int,
    restModifier: (j['rest_modifier'] as num).toDouble(),
  );
}

class GoalModifier {
  final String repsModifier;
  final int rpeTarget;

  const GoalModifier({required this.repsModifier, required this.rpeTarget});

  factory GoalModifier.fromJson(Map<String, dynamic> j) => GoalModifier(
    repsModifier: j['reps_modifier'] as String,
    rpeTarget: j['rpe_target'] as int,
  );
}
