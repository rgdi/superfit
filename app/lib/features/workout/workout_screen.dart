// WorkoutScreen: sesión activa.
// - Peso de cada serie calculado por LoadEngine con tu historial real y los
//   saltos de peso de TU máquina.
// - Se reajusta dentro de la sesión según el RPE que marcas.
// - Muestra tu máquina (nombre + ajuste de asiento) y permite cambiar de
//   ejercicio por otro que puedas hacer en tu gimnasio.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/gym_machine.dart';
import '../../data/models/routine.dart';
import '../../data/models/set_log.dart';
import '../../data/models/training_profile.dart';
import '../../data/models/workout_item.dart';
import '../../data/models/workout_session.dart';
import '../../domain/engine/cold_start.dart';
import '../../domain/engine/load_engine.dart';
import '../../domain/engine/program_coach.dart';
import '../../domain/engine/program_generator.dart';
import '../../widgets/muscle_map_widget.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/set_logger_row.dart';
import '../gym/scan_machine.dart';

const kReadinessPrefix = 'readiness_';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? initialMachineId; // máquina escaneada desde Inicio
  const WorkoutScreen({super.key, required this.sessionId, this.initialMachineId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _loading = true;
  String? _error;
  WorkoutSession? _session;
  Routine? _routine;
  Map<String, Exercise> _catalog = {};
  List<GymMachine> _machines = [];
  TrainingProfile _profile = const TrainingProfile();
  Readiness _readiness = Readiness.normal;

  int _index = 0;
  final Map<int, String> _swaps = {}; // índice → ejercicio sustituto
  final Map<String, LoadPrescription> _rx = {}; // exerciseId → prescripción
  final Map<String, List<double>> _setWeights = {}; // exerciseId → peso por serie
  final Map<String, SetLog> _logged = {}; // '$exId#$set' → set guardado
  bool _restVisible = false;
  int _restSeconds = 90;
  int _restKey = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalogRepo = ref.read(catalogRepoProvider);
      final gym = ref.read(gymRepoProvider);
      final session = await ref.read(sessionRepoProvider).sessionById(widget.sessionId);
      if (session == null) throw 'Sesión no encontrada';
      var routine = await catalogRepo.routineById(session.routineId);
      if (routine == null) throw 'Rutina no encontrada';
      final prefs = await SharedPreferences.getInstance();
      final rd = prefs.getString('$kReadinessPrefix${session.id}');
      _readiness = Readiness.values.firstWhere((r) => r.name == rd, orElse: () => Readiness.normal);
      final program = await gym.program();
      if (routine.isGenerated && program != null) {
        routine = ProgramCoach(program).adapt(routine, date: session.startedAt, readiness: _readiness);
      }
      _catalog = {for (final e in await catalogRepo.exercises()) e.id: e};
      _machines = await gym.machines();
      _profile = await gym.profile();
      // Sets ya guardados (reanudar sesión)
      for (final s in await ref.read(setRepoProvider).setsForSession(session.id)) {
        _logged['${s.exerciseId}#${s.setNumber}'] = s;
      }
      setState(() {
        _session = session;
        _routine = routine;
        _loading = false;
      });
      await _ensureRx(0);
      final initial = _machines.where((m) => m.id == widget.initialMachineId).firstOrNull;
      if (initial != null && mounted) await _jumpToMachine(initial);
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _exIdAt(int i) => _swaps[i] ?? _routine!.workout[i].exerciseId;

  GymMachine? _machineFor(Exercise ex) => machineForExercise(ex, _machines);

  MachineSpec _specFor(Exercise ex) {
    final m = _machineFor(ex);
    if (m == null) return MachineSpec.generic;
    return MachineSpec(minWeight: m.minWeight, maxWeight: m.maxWeight, increment: m.increment);
  }

  Future<void> _ensureRx(int i) async {
    final item = _routine!.workout[i];
    final exId = _exIdAt(i);
    if (_rx.containsKey(exId)) return;
    final ex = _catalog[exId];
    if (ex == null) return;
    final history = (await ref.read(setRepoProvider).setsForExercise(exId, limit: 80))
        .where((s) => s.sessionId != _session!.id)
        .map((s) => SetRecord(sessionId: s.sessionId, weight: s.weight, reps: s.reps, rpe: s.rpe, at: s.performedAt))
        .toList();
    final (lo, hi) = item.repRange;
    final level = ref.read(userSettingsProvider).level;
    final rx = LoadEngine.nextSession(
      history: history,
      repMin: lo,
      repMax: hi,
      rpeTarget: item.rpeTarget,
      coldStartWeight: coldStartWeight(ex, _profile, level),
      machine: _specFor(ex),
    );
    // Descarga: misma técnica, −10% de carga
    final isDeload = item.rpeTarget <= 6;
    final w = isDeload
        ? LoadEngine.roundTo(rx.weight * 0.9, _specFor(ex), mode: RoundMode.down)
        : rx.weight;
    if (!mounted) return;
    setState(() {
      _rx[exId] = rx;
      _setWeights[exId] = [
        for (int s = 1; s <= item.sets; s++) _logged['$exId#$s']?.weight ?? w,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    }
    final routine = _routine!;
    final item = routine.workout[_index];
    final ex = _catalog[_exIdAt(_index)];
    return Scaffold(
      appBar: AppBar(
        title: Text('${routine.nameEs} · ${_index + 1}/${routine.workout.length}'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        actions: [
          IconButton(
            tooltip: 'Escanear máquina (QR / NFC)',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
          ),
        ],
      ),
      body: ex == null
          ? const Center(child: Text('Ejercicio no encontrado'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_readiness == Readiness.low)
                  _banner(Icons.battery_2_bar, 'Modo "voy justo": 1 serie menos y RPE −1 en cada ejercicio.'),
                _header(ex, item),
                const SizedBox(height: 12),
                _machineCard(ex),
                const SizedBox(height: 12),
                _rxCard(ex, item),
                const SizedBox(height: 12),
                if (_restVisible)
                  RestTimer(
                    key: ValueKey(_restKey),
                    seconds: _restSeconds,
                    onComplete: () => setState(() => _restVisible = false),
                  ),
                const SizedBox(height: 8),
                const Text('Series', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                ..._setRows(ex, item),
                if (item.localizedNotes('es') != null) ...[
                  const SizedBox(height: 12),
                  _banner(Icons.info_outline, item.localizedNotes('es')!),
                ],
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Técnica y músculos'),
                  children: [
                    ...ex.instructionsEs.map((t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('• ', style: TextStyle(color: AppTheme.primary)),
                            Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
                          ]),
                        )),
                    if (ex.cuesEs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('💡 ${ex.cuesEs.join(' · ')}',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                      ),
                    SizedBox(
                      height: 200,
                      child: MuscleMapWidget(
                        primaryMuscles: ex.primaryMuscles.toSet(),
                        secondaryMuscles: ex.secondaryMuscles.toSet(),
                        view: _isFront(ex) ? 'front' : 'back',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _nav(routine),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.stop),
                  label: const Text('TERMINAR SESIÓN'),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------- widgets

  Widget _banner(IconData icon, String text) => Card(
        color: AppTheme.secondary.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ]),
        ),
      );

  Widget _header(Exercise ex, WorkoutItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ex.nameEs, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _chip('${item.sets} × ${item.repsTarget}'),
                _chip('RPE ${item.rpeTarget} (deja ${10 - item.rpeTarget} en reserva)'),
                _chip('Descanso ${item.restSeconds}s'),
                _chip('Tempo ${item.tempo}'),
              ]),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cambiar ejercicio',
          icon: const Icon(Icons.swap_horiz),
          onPressed: () => _swap(ex),
        ),
      ],
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      );

  Widget _machineCard(Exercise ex) {
    final m = _machineFor(ex);
    if (m == null) {
      if (_machines.isEmpty) return const SizedBox.shrink();
      return _banner(Icons.help_outline,
          'No tienes registrada una máquina para este ejercicio. Pulsa ⇄ para cambiarlo por uno que puedas hacer.');
    }
    return Card(
      color: AppTheme.surfaceMid,
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: AppTheme.primary),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(m.setupNotes.isEmpty ? 'Toca para guardar tu ajuste de asiento' : '⚙ ${m.setupNotes}'),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () => _editSetup(m),
      ),
    );
  }

  Widget _rxCard(Exercise ex, WorkoutItem item) {
    final rx = _rx[ex.id];
    if (rx == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
    }
    final color = switch (rx.action) {
      LoadAction.increase => AppTheme.primary,
      LoadAction.decrease => AppTheme.secondary,
      LoadAction.calibrate => Colors.amber,
      _ => Colors.white70,
    };
    final icon = switch (rx.action) {
      LoadAction.increase => Icons.trending_up,
      LoadAction.decrease => Icons.trending_down,
      LoadAction.calibrate => Icons.tune,
      LoadAction.maxedOut => Icons.vertical_align_top,
      _ => Icons.trending_flat,
    };
    final w = _setWeights[ex.id]?.first ?? rx.weight;
    return Card(
      color: color.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text('Hoy: ${_fmt(w)} kg × ${rx.targetReps}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              const Spacer(),
              if (rx.e1rm != null)
                Text('1RM est. ${rx.e1rm!.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Text(rx.reason, style: const TextStyle(fontSize: 13)),
            if (item.rpeTarget <= 6)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Descarga: peso −10%.', style: TextStyle(fontSize: 12, color: Colors.white60)),
              ),
            if (rx.plateau || rx.action == LoadAction.maxedOut)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _swap(ex),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Ver alternativas'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _setRows(Exercise ex, WorkoutItem item) {
    final weights = _setWeights[ex.id];
    if (weights == null) return const [];
    final spec = _specFor(ex);
    final rx = _rx[ex.id]!;
    return [
      for (int i = 1; i <= item.sets; i++)
        Builder(builder: (_) {
          final logged = _logged['${ex.id}#$i'];
          final w = weights[i - 1];
          return SetLoggerRow(
            key: ValueKey('${ex.id}_${i}_${logged != null ? 'done' : w}'),
            setNumber: i,
            initialWeight: logged?.weight ?? w,
            initialReps: logged?.reps ?? rx.targetReps,
            initialRpe: logged?.rpe,
            initialCompleted: logged != null,
            rpeHint: item.rpeTarget,
            step: spec.increment,
            minWeight: spec.minWeight,
            maxWeight: spec.maxWeight,
            onSave: (weight, reps, rpe, completed) => _onSet(ex, item, i, weight, reps, rpe, completed),
          );
        }),
    ];
  }

  Widget _nav(Routine routine) => Row(children: [
        if (_index > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _goto(_index - 1),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
          ),
        if (_index > 0) const SizedBox(width: 12),
        if (_index < routine.workout.length - 1)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _goto(_index + 1),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Siguiente'),
            ),
          ),
      ]);

  // ---------------------------------------------------------------- acciones

  void _goto(int i) {
    setState(() {
      _index = i;
      _restVisible = false;
    });
    _ensureRx(i);
  }

  Future<void> _onSet(Exercise ex, WorkoutItem item, int i, double weight, int reps, int? rpe, bool completed) async {
    final key = '${ex.id}#$i';
    final repo = ref.read(setRepoProvider);
    final existing = _logged[key];
    if (!completed) {
      if (existing != null) {
        await repo.deleteSet(existing.id);
        setState(() => _logged.remove(key));
      }
      return;
    }
    if (existing != null) {
      final upd = SetLog(
        id: existing.id,
        sessionId: existing.sessionId,
        exerciseId: existing.exerciseId,
        setNumber: existing.setNumber,
        weight: weight,
        reps: reps,
        rpe: rpe,
        completed: true,
        performedAt: existing.performedAt,
      );
      await repo.updateSet(upd);
      _logged[key] = upd;
    } else {
      final s = await repo.logSet(
        sessionId: _session!.id,
        exerciseId: ex.id,
        setNumber: i,
        weight: weight,
        reps: reps,
        rpe: rpe,
      );
      _logged[key] = s;
      setState(() {
        _restVisible = true;
        _restSeconds = item.restSeconds;
        _restKey++;
      });
    }
    _adjustRemaining(ex, item, i, weight, reps, rpe);
  }

  /// Reajusta las series pendientes según cómo ha ido esta.
  void _adjustRemaining(Exercise ex, WorkoutItem item, int i, double weight, int reps, int? rpe) {
    final rx = _rx[ex.id];
    final weights = _setWeights[ex.id];
    if (rx == null || weights == null || i >= item.sets) return;
    final (lo, hi) = item.repRange;
    final firstDone = !_logged.keys.any((k) => k.startsWith('${ex.id}#') && k != '${ex.id}#$i' &&
        int.parse(k.split('#').last) < i);
    final next = LoadEngine.adjustNextSet(
      weight: weight,
      reps: reps,
      rpe: rpe,
      repMin: lo,
      repMax: hi,
      rpeTarget: item.rpeTarget,
      machine: _specFor(ex),
      calibrating: rx.action == LoadAction.calibrate && firstDone,
    );
    if (next == null) return;
    var changed = false;
    for (int s = i + 1; s <= item.sets; s++) {
      if (_logged['${ex.id}#$s'] == null && weights[s - 1] != next) {
        weights[s - 1] = next;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(next > weight
            ? 'Vas sobrado: siguiente serie a ${_fmt(next)} kg.'
            : 'Muy exigente: siguiente serie a ${_fmt(next)} kg.'),
      ));
    }
  }

  Future<void> _scan() async {
    final m = await scanAndResolveMachine(context, ref);
    if (m == null || !mounted) return;
    setState(() => _machines = ref.read(gymMachinesProvider));
    await _jumpToMachine(m);
  }

  /// Va al ejercicio de la sesión que se hace en esa máquina; si no hay,
  /// ofrece cambiar el ejercicio actual por uno de esa máquina.
  Future<void> _jumpToMachine(GymMachine m) async {
    final types = m.typeIds.toSet();
    final r = _routine!;
    int? target;
    for (int i = 0; i < r.workout.length; i++) {
      final ex = _catalog[_exIdAt(i)];
      if (ex == null || !ex.usableWith(types)) continue;
      final done = List.generate(r.workout[i].sets, (k) => _logged['${ex.id}#${k + 1}'] != null).every((d) => d);
      target ??= i;
      if (!done) {
        target = i;
        break;
      }
    }
    if (target != null) {
      _goto(target);
      _snack('${m.name} → ${_catalog[_exIdAt(target)]!.nameEs}');
      return;
    }
    final current = _catalog[_exIdAt(_index)];
    final opts = _catalog.values.where((e) => e.usableWith(types)).toList()
      ..sort((a, b) {
        final g = current == null ? '' : groupOf(current);
        return (groupOf(a) == g ? 0 : 1).compareTo(groupOf(b) == g ? 0 : 1);
      });
    if (opts.isEmpty) {
      _snack('No sé qué ejercicio corresponde a ${m.name}. Revisa sus tipos en Mis máquinas.');
      return;
    }
    final pick = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(m.name),
        content: Text('No está en la sesión de hoy. ¿Cambio "${current?.nameEs ?? 'el ejercicio actual'}" '
            'por "${opts.first.nameEs}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cambiar')),
        ],
      ),
    );
    if (pick != true) return;
    setState(() => _swaps[_index] = opts.first.id);
    await _ensureRx(_index);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _swap(Exercise current) async {
    final types = availableMachineTypes(_machines);
    final group = groupOf(current);
    final opts = _catalog.values
        .where((e) => e.id != current.id && groupOf(e) == group && (types == null || e.usableWith(types)))
        .toList()
      ..sort((a, b) => (a.pattern == current.pattern ? 0 : 1).compareTo(b.pattern == current.pattern ? 0 : 1));
    final pick = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Cambiar por…', style: TextStyle(fontWeight: FontWeight.w700))),
            if (opts.isEmpty)
              const ListTile(title: Text('No hay alternativas con tus máquinas para este grupo.')),
            for (final e in opts)
              ListTile(
                title: Text(e.nameEs),
                subtitle: Text(_machineFor(e)?.name ?? (types == null ? '' : 'máquina no registrada')),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return;
    setState(() => _swaps[_index] = pick.id);
    await _ensureRx(_index);
  }

  Future<void> _editSetup(GymMachine m) async {
    final c = TextEditingController(text: m.setupNotes);
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(m.name),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Asiento 4 · Respaldo 2'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    if (v == null) return;
    final upd = m.copyWith(setupNotes: v);
    await ref.read(gymMachinesProvider.notifier).upsert(upd);
    setState(() => _machines = [for (final x in _machines) x.id == m.id ? upd : x]);
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
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
    if (ok == true && mounted) context.pop();
  }

  Future<void> _finish() async {
    final rpe = await showDialog<int>(context: context, builder: (_) => const _SessionRpeDialog());
    if (rpe == null) return;
    final s = _session!;
    final sets = await ref.read(setRepoProvider).setsForSession(s.id);
    final done = sets.where((x) => x.completed).toList();
    final volume = done.fold<double>(0, (a, b) => a + b.volume);
    await ref.read(sessionRepoProvider).finishSession(
          s.id,
          perceivedExertion: rpe,
          totalSets: done.length,
          totalVolume: volume,
        );
    final ups = _rx.values.where((r) => r.action == LoadAction.increase).length;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppTheme.primary, size: 48),
        title: const Text('¡Sesión completada!'),
        content: Text(
          'Series: ${done.length}\n'
          'Volumen: ${volume.toStringAsFixed(0)} kg·reps\n'
          'RPE sesión: $rpe'
          '${ups > 0 ? '\nHoy subiste carga en $ups ejercicio(s) 💪' : ''}',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al inicio')),
        ],
      ),
    );
    if (mounted) context.go('/');
  }

  bool _isFront(Exercise ex) {
    const front = ['pectoralis', 'deltoid_anterior', 'deltoid_lateral', 'biceps', 'brachialis',
      'rectus_abdominis', 'obliques', 'quadriceps', 'adductors'];
    return ex.primaryMuscles.any((m) => front.any(m.contains));
  }

  String _fmt(double w) => w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
}

class _SessionRpeDialog extends StatefulWidget {
  const _SessionRpeDialog();
  @override
  State<_SessionRpeDialog> createState() => _SessionRpeDialogState();
}

class _SessionRpeDialogState extends State<_SessionRpeDialog> {
  int _v = 7;
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('¿Qué tan dura fue la sesión?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_v', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
          Slider(
            value: _v.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => setState(() => _v = v.round()),
          ),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Muy fácil', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Text('Máximo', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context, _v), child: const Text('Guardar'))],
      );
}
