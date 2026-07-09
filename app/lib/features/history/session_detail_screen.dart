// SessionDetailScreen: detalle de una sesión con todos sus sets
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/set_log.dart';
import '../../data/models/workout_session.dart';

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de sesión')),
      body: FutureBuilder<WorkoutSession?>(
        future: ref.read(sessionRepoProvider).sessionById(sessionId),
        builder: (context, sessSnap) {
          if (!sessSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = sessSnap.data;
          if (session == null) return const Center(child: Text('No encontrada'));
          return FutureBuilder<List<SetLog>>(
            future: ref.read(setRepoProvider).setsForSession(sessionId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final sets = snap.data!;
              // group by exercise
              final byExercise = <String, List<SetLog>>{};
              for (final s in sets) {
                byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: AppTheme.surfaceMid,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.routineId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${session.startedAt.toString().split('.').first}\n'
                            'Duración: ${session.duration?.inMinutes ?? 0} min · RPE: ${session.perceivedExertion ?? "—"}\n'
                            'Series: ${session.totalSets ?? 0} · Volumen: ${(session.totalVolume ?? 0).toStringAsFixed(0)} kg·reps',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in byExercise.entries) ...[
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Card(
                      color: AppTheme.surfaceMid,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            for (final s in entry.value) ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.surfaceLight,
                                radius: 14,
                                child: Text(
                                  '${s.setNumber}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              title: Text('${s.weight.toStringAsFixed(1)} kg × ${s.reps}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.rpe == null ? Colors.transparent : AppTheme.rpeColor(s.rpe!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.rpe == null ? '—' : 'RPE ${s.rpe}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const Text('Notas', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Card(
                      color: AppTheme.surfaceMid,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(session.notes!),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
