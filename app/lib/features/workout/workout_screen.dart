// WorkoutScreen: sesión activa, registro de sets, timer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';
import '../../domain/usecases/progression_service.dart';
import '../../widgets/muscle_map_widget.dart';
import '../../widgets/set_logger_row.dart';
import '../../widgets/rest_timer.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const WorkoutScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int _currentExerciseIndex = 0;
  bool _restTimerVisible = false;
  int _restSeconds = 90;
  DateTime? _lastSetAt;
  Map<String, double> _suggestedWeights = {}; // exerciseId -> peso

  // (no initState needed)

  @override
  void dispose() {
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkoutSession?>(
      future: ref.read(sessionRepoProvider).sessionById(widget.sessionId),
      builder: (context, sessSnap) {
        if (!sessSnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = sessSnap.data!;
        return FutureBuilder<Routine?>(
          future: ref.read(catalogRepoProvider).routineById(session.routineId),
          builder: (context, routineSnap) {
            if (!routineSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final routine = routineSnap.data!;
            if (routine == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(child: Text('Rutina no encontrada')),
              );
            }
            return _buildScaffold(session, routine);
          },
        );
      },
    );
  }

  Widget _buildScaffold(WorkoutSession session, Routine routine) {
    final currentItem = routine.workout[_currentExerciseIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Ej ${_currentExerciseIndex + 1}/${routine.workout.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(session),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: FutureBuilder<Exercise?>(
        future: ref.read(catalogRepoProvider).exerciseById(currentItem.exerciseId),
        builder: (context, exSnap) {
          if (!exSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ex = exSnap.data;
          if (ex == null) {
            return const Center(child: Text('Ejercicio no encontrado'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _exerciseHeader(ex, currentItem),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: MuscleMapWidget(
                  primaryMuscles: ex.primaryMuscles.toSet(),
                  secondaryMuscles: ex.secondaryMuscles.toSet(),
                  view: _isFrontDominant(ex) ? 'front' : 'back',
                ),
              ),
              const SizedBox(height: 16),
              if (_restTimerVisible)
                RestTimer(
                  seconds: _restSeconds,
                  onComplete: () {
                    setState(() => _restTimerVisible = false);
                  },
                ),
              const SizedBox(height: 8),
              const Text('Series', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              for (int i = 1; i <= currentItem.sets; i++)
                SetLoggerRow(
                  key: ValueKey('${ex.id}_set_$i'),
                  setNumber: i,
                  initialWeight: _suggestedWeights[ex.id] ?? ProgressionService.suggestInitialWeight(ex),
                  initialReps: _parseRepsMin(currentItem.repsTarget),
                  technique: i == currentItem.sets && ex.category == 'isolation' ? null : null,
                  onSave: (weight, reps, rpe, completed) async {
                    if (completed) {
                      _lastSetAt = DateTime.now();
                      await ref.read(setRepoProvider).logSet(
                        sessionId: session.id,
                        exerciseId: ex.id,
                        setNumber: i,
                        weight: weight,
                        reps: reps,
                        rpe: rpe,
                        technique: null,
                      );
                      // arrancar timer descanso
                      setState(() {
                        _restTimerVisible = true;
                        _restSeconds = currentItem.restSeconds;
                      });
                      // actualizar sugerencia de peso
                      setState(() {
                        _suggestedWeights[ex.id] = weight;
                      });
                    }
                  },
                ),
              const SizedBox(height: 16),
              _exerciseNotes(currentItem),
              const SizedBox(height: 16),
              _navigationButtons(routine),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _finishSession(session),
                icon: const Icon(Icons.stop),
                label: const Text('TERMINAR SESIÓN'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isFrontDominant(Exercise ex) {
    const frontMuscles = [
      'pectoralis', 'deltoid_anterior', 'deltoid_lateral',
      'biceps', 'brachialis', 'rectus_abdominis', 'obliques',
      'quadriceps',
    ];
    return ex.primaryMuscles.any((m) => frontMuscles.any((f) => m.contains(f)));
  }

  int _parseRepsMin(String r) {
    try {
      return int.parse(r.split('-').first);
    } catch (_) {
      return 8;
    }
  }

  Widget _exerciseHeader(Exercise ex, dynamic item) {
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ex.nameEs,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('${item.sets} × ${item.repsTarget}'),
                _chip('RPE ${item.rpeTarget}'),
                _chip('Descanso ${item.restSeconds}s'),
                _chip('Tempo ${item.tempo}'),
              ],
            ),
            const SizedBox(height: 12),
            ...ex.instructionsEs.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primary)),
                  Expanded(child: Text(i, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            if (ex.cuesEs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.cuesEs.join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    );
  }

  Widget _exerciseNotes(dynamic item) {
    final notes = item.notesEs as String?;
    if (notes == null) return const SizedBox.shrink();
    return Card(
      color: AppTheme.secondary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(notes, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _navigationButtons(Routine routine) {
    return Row(
      children: [
        if (_currentExerciseIndex > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentExerciseIndex--),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
          ),
        if (_currentExerciseIndex > 0) const SizedBox(width: 12),
        if (_currentExerciseIndex < routine.workout.length - 1)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => setState(() => _currentExerciseIndex++),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Siguiente'),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmExit(WorkoutSession s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Salir sin terminar?'),
        content: const Text('La sesión quedará activa y podrás continuarla luego.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirm == true && mounted) context.pop();
  }

  Future<void> _finishSession(WorkoutSession s) async {
    final rpe = await showDialog<int>(
      context: context,
      builder: (_) => _rpeDialog(),
    );
    if (rpe == null) return;
    final notesController = TextEditingController();
    final sets = await ref.read(setRepoProvider).setsForSession(s.id);
    final completedSets = sets.where((x) => x.completed).toList();
    final totalVolume = completedSets.fold<double>(0, (a, b) => a + b.volume);
    await ref.read(sessionRepoProvider).finishSession(
      s.id,
      perceivedExertion: rpe,
      notes: null,
      totalSets: completedSets.length,
      totalVolume: totalVolume,
    );
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.celebration, color: AppTheme.primary, size: 48),
          title: const Text('¡Sesión completada!'),
          content: Text(
            'Series: ${completedSets.length}\nVolumen total: ${totalVolume.toStringAsFixed(0)} kg·reps\nRPE sesión: $rpe',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/');
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      );
    }
  }

  Widget _rpeDialog() {
    int selected = 8;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('RPE global de la sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Cómo te sentiste en general?', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            Text('$selected', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
            Slider(
              value: selected.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$selected',
              onChanged: (v) => setState(() => selected = v.round()),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Fácil', style: TextStyle(color: Colors.white60, fontSize: 11)),
                Text('Máximo', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
