// Cycle planner: qué rutina toca según fecha y plan
import '../../data/models/routine_plan.dart';
import '../../data/models/user_settings.dart';

class PlannedSession {
  final int weekIndex;
  final int dayOfWeek; // 1=lun ... 7=dom
  final String routineId;
  final String phase; // build | deload
  final double volumeModifier;
  final int rpeModifier;
  final String nameEs;
  final String nameEn;

  const PlannedSession({
    required this.weekIndex,
    required this.dayOfWeek,
    required this.routineId,
    required this.phase,
    required this.volumeModifier,
    required this.rpeModifier,
    required this.nameEs,
    required this.nameEn,
  });
}

class CyclePlanner {
  final RoutinePlan plan;
  final UserSettings settings;

  CyclePlanner(this.plan, this.settings);

  /// Devuelve la rutina planificada para una fecha
  PlannedSession? sessionFor(DateTime date) {
    final start = settings.planStartDate;
    if (start == null) return null;
    final daysSinceStart = date.difference(_normalize(start)).inDays;
    if (daysSinceStart < 0) return null;
    // semana actual (1..4)
    final weekIndex = ((daysSinceStart / 7).floor() % plan.cycles.length) + 1;
    final cycle = plan.cycles.firstWhere(
      (c) => c.weekIndex == weekIndex,
      orElse: () => plan.cycles.first,
    );
    // día de la semana (1=lun)
    final dow = date.weekday;
    final match = cycle.routineAssignments.where((a) => a.day == dow).toList();
    if (match.isEmpty) return null;
    final assignment = match.first;
    return PlannedSession(
      weekIndex: weekIndex,
      dayOfWeek: dow,
      routineId: assignment.routineId,
      phase: cycle.phase,
      volumeModifier: cycle.volumeModifier,
      rpeModifier: cycle.rpeModifier,
      nameEs: cycle.nameEs,
      nameEn: cycle.nameEn,
    );
  }

  /// Calcula el número de semana actual (1..4) para una fecha
  int currentWeek(DateTime date) {
    final start = settings.planStartDate;
    if (start == null) return 1;
    final days = date.difference(_normalize(start)).inDays;
    if (days < 0) return 1;
    return ((days / 7).floor() % plan.cycles.length) + 1;
  }

  /// Decide si toca deload (semana 4)
  bool isDeloadWeek(DateTime date) {
    final w = currentWeek(date);
    return w == 4;
  }

  /// Progresa la semana al cerrar sesión si corresponde
  DateTime nextPlanStart() {
    // se conserva el planStartDate original para que el ciclo rote solo
    return settings.planStartDate ?? DateTime.now();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
