import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_session.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: FutureBuilder<List<WorkoutSession>>(
        future: ref.read(sessionRepoProvider).recentSessions(limit: 50),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Sin sesiones aún.\nCompleta tu primera sesión para empezar tu historial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            );
          }
          return FutureBuilder(
            future: ref.read(catalogRepoProvider).routines(),
            builder: (context, rSnap) {
              final routines = {for (final r in (rSnap.data ?? [])) r.id: r};
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snap.data!.length,
                itemBuilder: (_, i) {
                  final s = snap.data![i];
                  final r = routines[s.routineId];
                  return Card(
                    color: AppTheme.surfaceMid,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      onTap: () => context.push('/history/${s.id}'),
                      leading: const Icon(Icons.fitness_center, color: AppTheme.primary),
                      title: Text(r?.nameEs ?? s.routineId),
                      subtitle: Text(
                        '${_fmt(s.startedAt)} · ${s.duration?.inMinutes ?? 0}min · RPE ${s.perceivedExertion ?? "—"}\n${s.totalSets ?? 0} series · ${(s.totalVolume ?? 0).toStringAsFixed(0)} vol',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
