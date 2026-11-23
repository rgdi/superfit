// Tarjeta "Hoy" cuando hay programa generado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/generated_program.dart';
import '../../data/models/routine.dart';
import '../../domain/engine/load_engine.dart';
import '../../domain/engine/program_coach.dart';
import '../../domain/engine/muscle_stats.dart';
import '../workout/session_starter.dart';
import '../../domain/ai/ai_service.dart' show kReadinessPrefix;
import '../../widgets/exercise_animation.dart';

class ProgramTodayCard extends ConsumerWidget {
  final GeneratedProgram program;
  const ProgramTodayCard({super.key, required this.program});

  Future<CoachAdvice> _advice(WidgetRef ref) async {
    final sessions = await ref.read(sessionRepoProvider).recentSessions(limit: 30);
    final recent = sessions
        .where((s) => !s.isActive)
        .map((s) => FinishedSessionInfo(s.routineId, s.startedAt, s.perceivedExertion))
        .toList();
    // Fatiga: ¿en qué proporción de ejercicios ha caído el rendimiento?
    final ids = program.routines.expand((r) => r.workout).map((w) => w.exerciseId).toSet();
    var considered = 0, drops = 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    for (final id in ids) {
      final sets = await ref.read(setRepoProvider).setsForExercise(id, limit: 40);
      if (sets.isEmpty || sets.first.performedAt.isBefore(cutoff)) continue;
      final rx = LoadEngine.nextSession(
        history: sets
            .map((s) => SetRecord(sessionId: s.sessionId, weight: s.weight, reps: s.reps, rpe: s.rpe, at: s.performedAt))
            .toList(),
        repMin: 8, repMax: 12, rpeTarget: 8, coldStartWeight: 0,
      );
      final sessionsCount = sets.map((s) => s.sessionId).toSet().length;
      if (sessionsCount < 3) continue;
      considered++;
      if (rx.performanceDrop) drops++;
    }
    final profile = ref.read(trainingProfileProvider);
    // Recuperación por músculo para elegir la sesión más adecuada hoy
    final cat = ref.read(catalogRepoProvider);
    final exercises = {for (final e in await cat.exercises()) e.id: e};
    final muscleIds = (await cat.muscles()).map((m) => m.id);
    final cutoff2 = DateTime.now().subtract(const Duration(days: 7));
    final recentSets = (await ref.read(setRepoProvider).allCompleted()).where((s) => s.performedAt.isAfter(cutoff2)).toList();
    final stats = computeMuscleStats(
      sets: recentSets,
      catalog: exercises,
      muscleIds: muscleIds,
      level: ref.read(userSettingsProvider).level,
    );
    return ProgramCoach(program).adviseToday(
      now: DateTime.now(),
      recent: recent,
      daysPerWeek: profile.daysPerWeek,
      fatigueShare: considered >= 3 ? drops / considered : 0,
      recovery: {for (final s in stats.values) s.id: s.recovery},
      primaryOf: {for (final e in exercises.values) e.id: e.primaryMuscles},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CoachAdvice>(
      future: _advice(ref),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 380);
        final a = snap.data!;
        final r = a.routine!;
        final coach = ProgramCoach(program);
        final meta = [
          '${r.workout.length} ejercicios',
          '${r.estimatedMinutes} min',
          a.deload ? 'descarga' : 'semana ${a.week} de ${program.mesocycleWeeks}',
        ].join(' · ');
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.push('/routines/${r.id}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(exercisePhoto(r.workout.first.exerciseId, 0), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceMid)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(a.suggestRest ? 'Hoy toca descansar' : 'Hoy',
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(r.nameEs, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -1.0)),
          const SizedBox(height: 6),
          Text(meta, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          if (!a.deload && !a.suggestRest) ...[
            const SizedBox(height: 2),
            Text('Esfuerzo objetivo RPE ${coach.rpeForWeek(a.week)}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          ],
          for (final n in a.notes.where((n) => n.contains('recuperando') || n.contains('rendimiento ha bajado')))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(n, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _start(context, ref, r),
              child: Text(a.suggestRest ? 'Entrenar igualmente' : 'Empezar'),
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, Routine r) async {
    // Antes de nada: ¿hay una sesión a medias?
    final (go, resumeId) = await resolveActiveSession(context, ref);
    if (!go || !context.mounted) return;
    if (resumeId != null) {
      context.push('/workout/$resumeId');
      return;
    }
    final readiness = await showModalBottomSheet<Readiness>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 12),
              child: Text('¿Cómo llegas hoy?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            ),
            _opt(context, Readiness.low, 'Cansado', 'Una serie menos y algo menos de esfuerzo'),
            const Divider(indent: AppTheme.gutter, endIndent: AppTheme.gutter),
            _opt(context, Readiness.normal, 'Normal', 'La sesión tal cual'),
            const Divider(indent: AppTheme.gutter, endIndent: AppTheme.gutter),
            _opt(context, Readiness.high, 'Con energía', 'Si vas sobrado, subo el peso'),
          ]),
        ),
      ),
    );
    if (readiness == null) return;
    final session = await ref.read(sessionRepoProvider).startSession(r.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$kReadinessPrefix${session.id}', readiness.name);
    if (context.mounted) context.push('/workout/${session.id}');
  }

  Widget _opt(BuildContext context, Readiness v, String title, String sub) => ListTile(
        onTap: () => Navigator.pop(context, v),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textFaint),
      );
}

/// Invitación a crear el programa cuando aún no existe.
class CreateProgramCta extends StatelessWidget {
  const CreateProgramCta({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(exercisePhoto('leg_press', 0), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceMid)),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Tu programa', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -1.0)),
        const SizedBox(height: 6),
        const Text('Con tus máquinas, tus días y tu tiempo.', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: () => context.push('/settings/profile'), child: const Text('Crear programa')),
        ),
      ]);
}
