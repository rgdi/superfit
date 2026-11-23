import 'package:flutter/material.dart';
import '../../core/names.dart';
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
              const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 24),
                itemCount: snap.data!.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final s = snap.data![i];
                  final r = routines[s.routineId];
                  final vol = s.totalVolume ?? 0;
                  return InkWell(
                    onTap: () => context.push('/history/${s.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(children: [
                        SizedBox(
                          width: 48,
                          child: Column(children: [
                            Text('${s.startedAt.day}', style: AppTheme.number.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                            Text(months[s.startedAt.month - 1], style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r?.nameEs ?? (s.routineId.startsWith('gen_') ? 'Sesión de un programa anterior' : Names.exercise(s.routineId)), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${s.totalSets ?? 0} series · ${s.duration?.inMinutes ?? 0} min',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                          ]),
                        ),
                        Text(vol >= 1000 ? '${(vol / 1000).toStringAsFixed(1)} t' : '${vol.toStringAsFixed(0)} kg',
                            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                      ]),
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

}
