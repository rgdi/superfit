// Mi programa: genera, muestra el porqué y gestiona el mesociclo.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/generated_program.dart';
import '../../data/models/training_profile.dart';
import '../../domain/engine/program_coach.dart';
import '../../domain/engine/program_generator.dart';
import '../../domain/engine/muscle_stats.dart';
import '../../core/names.dart';
import '../../data/models/user_settings.dart';
import '../../widgets/exercise_animation.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi programa'),
        actions: [
          if (program != null)
            PopupMenuButton<String>(
              onSelected: (v) => _menu(context, ref, program, v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'deload', child: Text('Adelantar descarga a esta semana')),
                PopupMenuItem(value: 'restart', child: Text('Reiniciar bloque (semana 1)')),
                PopupMenuItem(value: 'delete', child: Text('Borrar programa')),
              ],
            ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: ref.read(catalogRepoProvider).exercises(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final byId = {for (final e in snap.data!) e.id: e};
          final settings = ref.watch(userSettingsProvider);
          final priorities = ref.watch(trainingProfileProvider).priorities;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (program == null) _generateCard(context, ref, snap.data!, false),
              if (program != null) ..._programView(context, program, byId, settings, priorities),
              if (program != null) ...[
                const SizedBox(height: 24),
                _generateCard(context, ref, snap.data!, true),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _generateCard(BuildContext context, WidgetRef ref, List<Exercise> catalog, bool hasProgram) {
    final profile = ref.watch(trainingProfileProvider);
    final machines = ref.watch(gymMachinesProvider);
    final settings = ref.watch(userSettingsProvider);
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hasProgram ? 'Regenerar con mis datos actuales' : 'Crea tu programa a medida',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '${profile.daysPerWeek} días · ${profile.sessionMinutes} min · '
              '${machines.isEmpty ? 'todas las máquinas' : '${machines.length} máquinas'}'
              '${profile.injuries.isEmpty ? '' : ' · evita: ${profile.injuries.map((i) => kInjuryLabels[i]).join(', ')}'}'
              '${profile.priorities.isEmpty ? '' : ' · prioriza: ${profile.priorities.map((i) => kMuscleGroupLabels[i]).join(', ')}'}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => context.push('/settings/profile'),
                  child: const Text('Editar perfil'),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/settings/machines'),
                  child: const Text('Máquinas'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(hasProgram ? 'Regenerar' : 'Generar'),
                  onPressed: () async {
                    final p = ProgramGenerator(
                      catalog: catalog,
                      availableTypes: availableMachineTypes(machines),
                      profile: profile,
                      level: settings.level,
                      goal: settings.goal,
                    ).generate();
                    await ref.read(programProvider.notifier).set(p);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Programa listo. Aparecerá en "Hoy".')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Misma medida que el mapa muscular, pero con lo PLANIFICADO.
  List<Widget> _muscleCoverage(GeneratedProgram p, Map<String, Exercise> byId, UserSettings settings, Set<String> priorities) {
    final vol = <String, double>{};
    for (final r in p.routines) {
      for (final it in r.workout) {
        final e = byId[it.exerciseId];
        if (e == null) continue;
        for (final m in e.primaryMuscles) {
          vol[m] = (vol[m] ?? 0) + it.sets;
        }
        for (final m in e.secondaryMuscles) {
          vol[m] = (vol[m] ?? 0) + it.sets * 0.5;
        }
      }
    }
    final rows = Names.muscles.keys.map((m) {
      final t = muscleWeeklyTarget(m, settings.level, goal: settings.goal, priorities: priorities);
      return (m, vol[m] ?? 0.0, t);
    }).toList()
      ..sort((a, b) => (a.$2 / a.$3).compareTo(b.$2 / b.$3));
    return [
      for (final (m, v, t) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 150,
              child: Text(Names.muscle(m),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: kMinorMuscles.contains(m) ? AppTheme.textMuted : Colors.white)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (v / t).clamp(0.0, 1.0),
                  minHeight: 5,
                  color: v >= 0.9 * t ? AppTheme.signal : Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: 58,
              child: Text('${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}/${t.round()}',
                  textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ),
          ]),
        ),
    ];
  }

  List<Widget> _programView(BuildContext context, GeneratedProgram p, Map<String, Exercise> byId,
      UserSettings settings, Set<String> priorities) {
    final now = DateTime.now();
    final coach = ProgramCoach(p);
    final week = p.weekFor(now);
    return [
      const SizedBox(height: 16),
      Text(p.splitName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
        p.isDeloadWeek(now)
            ? 'Semana $week/${p.mesocycleWeeks} · DESCARGA'
            : 'Semana $week/${p.mesocycleWeeks} · RPE objetivo ${coach.rpeForWeek(week)}',
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      _weekStrip(p, coach, week),
      const SizedBox(height: 16),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const Text('Por qué este programa', style: TextStyle(fontWeight: FontWeight.w700)),
        children: [
          for (final r in p.rationale)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primary)),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      const Text('Volumen semanal por músculo', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Series planificadas frente a tu objetivo (principal 1, secundario 0,5).',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      ..._muscleCoverage(p, byId, settings, priorities),
      const SizedBox(height: 16),
      for (final r in p.routines)
        Card(
          color: AppTheme.surfaceMid,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.nameEs, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('~${r.estimatedMinutes} min', style: const TextStyle(color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 6),
                for (final it in r.workout)
                  InkWell(
                    onTap: () => context.push('/exercises/${it.exerciseId}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ExerciseThumb(it.exerciseId, size: 40),
                          const SizedBox(width: 10),
                          Expanded(child: Text(byId[it.exerciseId]?.nameEs ?? it.exerciseId)),
                          Text('${it.sets} × ${it.repsTarget}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _weekStrip(GeneratedProgram p, ProgramCoach coach, int current) {
    return Row(
      children: [
        for (int w = 1; w <= p.mesocycleWeeks; w++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: w == current ? AppTheme.primary : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('S$w',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: w == current ? Colors.black : Colors.white)),
                  Text(w == p.mesocycleWeeks ? 'desc.' : 'RPE ${coach.rpeForWeek(w)}',
                      style: TextStyle(fontSize: 10, color: w == current ? Colors.black : Colors.white60)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, GeneratedProgram p, String v) async {
    final n = ref.read(programProvider.notifier);
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    switch (v) {
      case 'deload':
        // Coloca el inicio para que hoy caiga en la última semana del bloque
        final monday = t0.subtract(Duration(days: t0.weekday - 1));
        await n.set(p.copyWith(startDate: monday.subtract(Duration(days: 7 * (p.mesocycleWeeks - 1)))));
        break;
      case 'restart':
        await n.set(p.copyWith(startDate: t0));
        break;
      case 'delete':
        await n.set(null);
        break;
    }
  }
}
