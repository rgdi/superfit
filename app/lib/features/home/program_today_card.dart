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
import '../../domain/ai/ai_service.dart' show kReadinessPrefix;

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
    return ProgramCoach(program).adviseToday(
      now: DateTime.now(),
      recent: recent,
      daysPerWeek: profile.daysPerWeek,
      fatigueShare: considered >= 3 ? drops / considered : 0,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CoachAdvice>(
      future: _advice(ref),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator()));
        }
        final a = snap.data!;
        final r = a.routine!;
        return Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(a.deload ? Icons.spa : Icons.bolt, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.headline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('${program.splitName} · ${r.workout.length} ejercicios · ~${r.estimatedMinutes} min',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                for (final n in a.notes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $n', style: const TextStyle(fontSize: 13)),
                  ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.spaceBetween, children: [
                  OutlinedButton(
                    onPressed: () => context.push('/program'),
                    child: const Text('Programa'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _start(context, ref, r),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(a.suggestRest ? 'Entrenar igualmente' : 'Empezar'),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, Routine r) async {
    final readiness = await showDialog<Readiness>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('¿Cómo llegas hoy?'),
        children: [
          _opt(context, Readiness.low, '😴', 'Cansado / dormí mal / agujetas', '1 serie menos y RPE −1'),
          _opt(context, Readiness.normal, '🙂', 'Normal', 'Sesión según el plan'),
          _opt(context, Readiness.high, '🔥', 'A tope', 'Según plan; si vas sobrado, el sistema sube peso'),
        ],
      ),
    );
    if (readiness == null) return;
    final session = await ref.read(sessionRepoProvider).startSession(r.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$kReadinessPrefix${session.id}', readiness.name);
    if (context.mounted) context.push('/workout/${session.id}');
  }

  Widget _opt(BuildContext context, Readiness v, String emoji, String title, String sub) => SimpleDialogOption(
        onPressed: () => Navigator.pop(context, v),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
        ]),
      );
}

/// Invitación a crear el programa cuando aún no existe.
class CreateProgramCta extends StatelessWidget {
  const CreateProgramCta({super.key});
  @override
  Widget build(BuildContext context) => Card(
        color: AppTheme.primary.withOpacity(0.12),
        child: ListTile(
          leading: const Icon(Icons.auto_awesome, color: AppTheme.primary),
          title: const Text('Crea tu programa a medida', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Con tus máquinas, tus días, tu tiempo y tus molestias.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/profile'),
        ),
      );
}
