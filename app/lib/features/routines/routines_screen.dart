// RoutinesScreen: lista de rutinas del plan
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/routine.dart';
import '../../widgets/exercise_animation.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final catalogRepo = ref.watch(catalogRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: FutureBuilder<List<Routine>>(
        future: catalogRepo.routines(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Error cargando rutinas'));
          }
          final routines = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 24),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => _routineCard(context, routines[i], settings.locale),
          );
        },
      ),
    );
  }

  Widget _routineCard(BuildContext context, Routine r, String locale) {
    return InkWell(
      onTap: () => context.push('/routines/${r.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          if (r.workout.isNotEmpty) ExerciseThumb(r.workout.first.exerciseId, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.localizedName(locale), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${r.workout.length} ejercicios · ${r.estimatedMinutes} min',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ]),
          ),
          const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textFaint),
        ]),
      ),
    );
  }
}
