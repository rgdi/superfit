// "Entrenador": decide qué toca hoy y adapta la sesión.
//
// - Rotación en vez de días fijos: si faltas un día, no se pierde la sesión,
//   simplemente toca la siguiente de la lista.
// - Mesociclo: RPE objetivo creciente (7 → 9) y última semana de descarga.
// - Disposición del día (readiness): si llegas mal, menos series y RPE −1.
//   Autorregulación diaria con RPE: Helms et al. 2018 (PMID 29628895) — los
//   efectos frente a programas fijos son modestos, pero reduce el riesgo de
//   pasarte cuando estás cansado.
import 'dart:math' as math;
import '../../data/models/generated_program.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout_item.dart';

enum Readiness { low, normal, high }

class CoachAdvice {
  final Routine? routine;
  final String headline;
  final List<String> notes;
  final int week;
  final bool deload;
  final bool suggestRest;
  const CoachAdvice({
    required this.routine,
    required this.headline,
    this.notes = const [],
    required this.week,
    required this.deload,
    this.suggestRest = false,
  });
}

class FinishedSessionInfo {
  final String routineId;
  final DateTime startedAt;
  final int? sessionRpe;
  const FinishedSessionInfo(this.routineId, this.startedAt, this.sessionRpe);
}

class ProgramCoach {
  final GeneratedProgram program;
  ProgramCoach(this.program);

  /// RPE objetivo para la semana `w` (1..N). Última semana = descarga (6).
  int rpeForWeek(int w) {
    final n = program.mesocycleWeeks;
    if (w >= n) return 6;
    final build = n - 1;
    if (build <= 1) return 8;
    return (7 + 2 * (w - 1) / (build - 1)).round().clamp(7, 9);
  }

  /// Siguiente rutina de la rotación según lo último completado.
  Routine nextRoutine(List<FinishedSessionInfo> recent) {
    final ids = program.rotation;
    final lastIdx = recent
        .where((s) => ids.contains(s.routineId))
        .map((s) => ids.indexOf(s.routineId))
        .firstOrNull;
    final nextId = lastIdx == null ? ids.first : ids[(lastIdx + 1) % ids.length];
    return program.routines.firstWhere((r) => r.id == nextId);
  }

  CoachAdvice adviseToday({
    required DateTime now,
    required List<FinishedSessionInfo> recent, // más reciente primero
    required int daysPerWeek,
    double fatigueShare = 0, // % de ejercicios con caída de rendimiento
  }) {
    final week = program.weekFor(now);
    final deload = program.isDeloadWeek(now);
    final routine = nextRoutine(recent);
    final notes = <String>[];

    final today = DateTime(now.year, now.month, now.day);
    final trainedToday = recent.any((s) => !s.startedAt.isBefore(today));
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final thisWeek = recent.where((s) => !s.startedAt.isBefore(monday)).length;
    final trainedYesterday = recent.any((s) =>
        !s.startedAt.isBefore(today.subtract(const Duration(days: 1))) && s.startedAt.isBefore(today));

    if (deload) {
      notes.add('Semana de descarga: mitad de series, RPE ~6. Sirve para disipar fatiga, no pierdes músculo.');
    } else {
      notes.add('Semana $week/${program.mesocycleWeeks} · RPE objetivo ${rpeForWeek(week)}.');
    }
    if (!deload && fatigueShare >= 0.5) {
      notes.add('Tu rendimiento ha bajado en la mitad de los ejercicios recientes. '
          'Si además duermes mal o estás muy cargado, plantéate adelantar la descarga (Ajustes → Mi programa).');
    }
    final recentRpes = recent.take(3).map((s) => s.sessionRpe).whereType<int>().toList();
    if (recentRpes.length == 3 && recentRpes.every((r) => r >= 9)) {
      notes.add('Tus 3 últimas sesiones las marcaste RPE ≥9. Hoy elige "Cansado" al empezar.');
    }

    if (trainedToday) {
      return CoachAdvice(
        routine: routine, headline: 'Ya has entrenado hoy. Próxima: ${routine.nameEs}',
        notes: notes, week: week, deload: deload, suggestRest: true);
    }
    if (thisWeek >= daysPerWeek) {
      return CoachAdvice(
        routine: routine, headline: 'Semana completada ($thisWeek/$daysPerWeek). Descansa o haz cardio suave.',
        notes: notes, week: week, deload: deload, suggestRest: true);
    }
    if (trainedYesterday && daysPerWeek <= 3) {
      notes.add('Ayer entrenaste cuerpo completo: si tienes agujetas fuertes, mejor mañana.');
    }
    return CoachAdvice(
      routine: routine,
      headline: 'Hoy toca: ${routine.nameEs}',
      notes: notes,
      week: week,
      deload: deload,
    );
  }

  /// Aplica semana del mesociclo + disposición del día a una rutina.
  Routine adapt(Routine r, {required DateTime date, Readiness readiness = Readiness.normal}) {
    final week = program.weekFor(date);
    final deload = program.isDeloadWeek(date);
    final rpe = rpeForWeek(week);
    final items = r.workout.map((it) {
      var sets = it.sets;
      var target = rpe;
      String? note;
      if (deload) {
        sets = math.max(1, (it.sets / 2).ceil());
        note = 'Descarga: mitad de series, sin acercarte al fallo.';
      }
      if (readiness == Readiness.low) {
        sets = math.max(deload ? 1 : 2, sets - 1);
        target = math.max(6, target - 1);
        note = '${note == null ? '' : '$note '}Hoy vas justo: 1 serie menos y RPE −1.';
      }
      return WorkoutItem(
        exerciseId: it.exerciseId,
        sets: sets,
        repsTarget: it.repsTarget,
        rpeTarget: target,
        restSeconds: it.restSeconds,
        tempo: it.tempo,
        notesEs: [if (it.notesEs != null) it.notesEs!, if (note != null) note].join(' ').trim().isEmpty
            ? null
            : [if (it.notesEs != null) it.notesEs!, if (note != null) note].join(' '),
        notesEn: it.notesEn,
        supersetWith: it.supersetWith,
      );
    }).toList();
    return Routine(
      id: r.id,
      nameEs: r.nameEs,
      nameEn: r.nameEn,
      dayOfWeek: r.dayOfWeek,
      estimatedMinutes: r.estimatedMinutes,
      level: r.level,
      goal: r.goal,
      warmup: r.warmup,
      workout: items,
      cooldown: r.cooldown,
    );
  }
}
