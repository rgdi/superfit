// RoutineDetailScreen: detalle de una rutina
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/routine.dart';

class RoutineDetailScreen extends ConsumerWidget {
  final String routineId;
  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rutina')),
      body: FutureBuilder<Routine?>(
        future: ref.read(catalogRepoProvider).routineById(routineId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data;
          if (r == null) return const Center(child: Text('Rutina no encontrada'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                r.localizedName(settings.locale),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.estimatedMinutes} min · ${r.workout.length} ejercicios',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              if (r.warmup.isNotEmpty) ...[
                const Text('Calentamiento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                ...r.warmup.map((w) => ListTile(
                  leading: const Icon(Icons.directions_walk, color: AppTheme.primary),
                  title: Text(w.localizedName(settings.locale)),
                  trailing: Text('${w.durationSeconds}s'),
                  dense: true,
                )),
                const SizedBox(height: 16),
              ],
              const Text('Trabajo principal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              ...r.workout.map((w) => Card(
                color: AppTheme.surfaceMid,
                child: ListTile(
                  onTap: () => context.push('/exercises/${w.exerciseId}'),
                  title: Text(
                    w.exerciseId.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${w.sets} × ${w.repsTarget} · RPE ${w.rpeTarget} · descanso ${w.restSeconds}s',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
              if (r.cooldown.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Vuelta a la calma', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                ...r.cooldown.map((c) => ListTile(
                  leading: const Icon(Icons.self_improvement, color: AppTheme.primary),
                  title: Text(c.localizedName(settings.locale)),
                  trailing: Text('${c.durationSeconds}s'),
                  dense: true,
                )),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final session = await ref.read(sessionRepoProvider).startSession(r.id);
                  if (context.mounted) context.push('/workout/${session.id}');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('EMPEZAR ESTA RUTINA'),
              ),
            ],
          );
        },
      ),
    );
  }
}
