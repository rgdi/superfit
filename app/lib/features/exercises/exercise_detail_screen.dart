// ExerciseDetailScreen: detalle de un ejercicio con músculos resaltados
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../widgets/muscle_map_widget.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio')),
      body: FutureBuilder<Exercise?>(
        future: ref.read(catalogRepoProvider).exerciseById(exerciseId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ex = snap.data;
          if (ex == null) return const Center(child: Text('No encontrado'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                ex.localizedName(settings.locale),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${ex.category == 'compound' ? 'Compuesto' : 'Aislamiento'} · ${ex.pattern.replaceAll('_', ' ')}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              _muscleMapSection(ex),
              const SizedBox(height: 16),
              _paramsCard(ex),
              const SizedBox(height: 16),
              _instructionsCard(ex, settings.locale),
              const SizedBox(height: 16),
              _cuesCard(ex, settings.locale),
              if (ex.contraindications.isNotEmpty) ...[
                const SizedBox(height: 16),
                _contraindicationsCard(ex),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _muscleMapSection(Exercise ex) {
    final frontView = ex.primaryMuscles.any((m) =>
      m.contains('pectoralis') || m.contains('deltoid_anterior') || m.contains('deltoid_lateral') ||
      m.contains('biceps') || m.contains('brachialis') || m.contains('rectus') ||
      m.contains('obliqu') || m.contains('quad')
    );
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.accessibility, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Músculos activados', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: MuscleMapWidget(
                primaryMuscles: ex.primaryMuscles.toSet(),
                secondaryMuscles: ex.secondaryMuscles.toSet(),
                view: frontView ? 'front' : 'back',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...ex.primaryMuscles.map((m) => Chip(
                  label: Text(m.replaceAll('_', ' ')),
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 11),
                )),
                ...ex.secondaryMuscles.map((m) => Chip(
                  label: Text(m.replaceAll('_', ' ')),
                  backgroundColor: AppTheme.surfaceLight,
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramsCard(Exercise ex) {
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _param('Reps', ex.defaultReps),
            _param('RPE', '${ex.rpeTarget}'),
            _param('Descanso', '${ex.defaultRestSeconds}s'),
            _param('Tempo', ex.tempo),
          ],
        ),
      ),
    );
  }

  Widget _param(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _instructionsCard(Exercise ex, String locale) {
    final list = ex.localizedInstructions(locale);
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cómo hacerlo', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (int i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(list[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cuesCard(Exercise ex, String locale) {
    final list = ex.localizedCues(locale);
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('Cues técnicos', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(list.join(' · '), style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _contraindicationsCard(Exercise ex) {
    return Card(
      color: AppTheme.secondary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.secondary, size: 20),
                SizedBox(width: 8),
                Text('Contraindicaciones', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(ex.contraindications.join(', ').replaceAll('_', ' ')),
          ],
        ),
      ),
    );
  }
}
