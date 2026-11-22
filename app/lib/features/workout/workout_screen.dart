// WorkoutScreen: sesión activa.
// - Peso de cada serie: reglas de doble progresión + IA local que aprende de
//   tus series, siempre redondeado a los pesos reales de TU máquina.
// - Historial separado por máquina física (dos Chest Press no se mezclan).
// - Series de distinto tipo: aproximación, efectivas, top set + back-off, drop.
// - Se reajusta en vivo con cada serie; detecta récords.
// - Escanear el QR/NFC de una máquina salta a su ejercicio.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../domain/ai/ai_service.dart';
import '../../domain/ai/performance_model.dart';
import '../../domain/engine/cold_start.dart';
import '../../domain/engine/load_engine.dart';
import '../../domain/engine/program_coach.dart';
import '../../domain/engine/program_generator.dart';
import '../../widgets/muscle_map_widget.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/set_row.dart';
import '../../widgets/tip_tier_widgets.dart';
import '../gym/scan_machine.dart';

export '../../domain/ai/ai_service.dart' show kReadinessPrefix;

class _PlannedSet {
  final int slot; // nº de serie guardado: <0 aproximación, 1..n efectivas, >100 drop
  SetKind kind;
  double weight;
  int reps;
  _PlannedSet(this.slot, this.kind, this.weight, this.reps);
}

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
  PerformanceModel? _ai;

  int _index = 0;
  int _dir = 1; // dirección de la animación entre ejercicios
  final Map<int, String> _swaps = {};
  final Map<String, LoadPrescription> _rx = {};
  final Map<String, String?> _aiNote = {};
  final Map<String, List<_PlannedSet>> _plan = {};
  final Map<String, bool> _topBackoff = {};
  final Map<String, double> _bestE1rm = {};
  final Map<String, SetLog> _logged = {}; // '$exId#$slot'
  bool _restVisible = false;
  int _restSeconds = 90;
  int _restKey = 0;
  int _prCount = 0;
  String? _prText;

  int get _readinessValue => switch (_readiness) {
        Readiness.low => -1,
        Readiness.high => 1,
        Readiness.normal => 0,
      };

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
      for (final s in await ref.read(setRepoProvider).setsForSession(session.id)) {
        _logged['${s.exerciseId}#${s.setNumber}'] = s;
      }
      try {
        _ai = await ref.read(performanceModelProvider.future);
      } catch (_) {
        _ai = null; // la sesión funciona sin IA
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
  MachineSpec _specFor(Exercise ex) => _machineFor(ex)?.spec ?? MachineSpec.generic;

  // ------------------------------------------------------------ prescripción

  Future<void> _ensureRx(int i) async {
    final item = _routine!.workout[i];
    final exId = _exIdAt(i);
    if (_rx.containsKey(exId)) return;
    final ex = _catalog[exId];
    if (ex == null) return;
    final machine = _machineFor(ex);
    final spec = _specFor(ex);
    final all = (await ref.read(setRepoProvider).setsForExercise(exId, limit: 120))
        .where((s) => s.sessionId != _session!.id && !s.isWarmup && s.technique != 'drop')
        .toList();
    // Historial de ESTA máquina (o series antiguas sin máquina)
    final hist = machine == null
        ? all
        : all.where((s) => s.machineId == machine.id || s.machineId == null).toList();
    final otherMachine = machine != null && hist.isEmpty && all.isNotEmpty;
    final records = hist
        .map((s) => SetRecord(sessionId: s.sessionId, weight: s.weight, reps: s.reps, rpe: s.rpe, at: s.performedAt))
        .toList();
    _bestE1rm[exId] = records.isEmpty
        ? 0
        : records.map((r) => PerformanceModel.e1rm(r.weight, r.reps, r.rpe)).reduce(math.max);
    final (lo, hi) = item.repRange;
    final level = ref.read(userSettingsProvider).level;
    var rx = LoadEngine.nextSession(
      history: records,
      repMin: lo,
      repMax: hi,
      rpeTarget: item.rpeTarget,
      coldStartWeight: coldStartWeight(ex, _profile, level),
      machine: spec,
    );
    var w = rx.weight;
    String? aiNote;
    // IA: si conoce bien este ejercicio en esta máquina, afina el peso (±10 %)
    final mId = hist.any((s) => s.machineId != null) ? machine?.id : null;
    final st = _ai?.strength(exId, mId);
    if (_ai != null && st != null && st.usable && rx.action != LoadAction.calibrate) {
      final aiW = _ai!.recommendWeight(exId, mId, ex.category == 'compound', rx.targetReps, item.rpeTarget,
          readiness: _readinessValue, spec: spec);
      if (aiW != null) {
        final bounded = spec.round(aiW.clamp(rx.weight * 0.9, rx.weight * 1.1), mode: RoundMode.down);
        if ((bounded - w).abs() > 1e-6) {
          aiNote = 'IA (confianza ${st.confidence}): ajusta a ${fmtKg(bounded)} kg según tu forma actual.';
          w = bounded;
        } else {
          aiNote = 'IA (confianza ${st.confidence}) coincide con el plan.';
        }
      }
    } else if (st != null && !st.usable) {
      aiNote = 'IA aprendiendo este ejercicio (${st.observations} series).';
    }
    if (otherMachine) {
      aiNote = 'Primera vez en ${machine.name}: cada máquina pesa distinto, calibramos con la 1ª serie.';
      rx = LoadEngine.nextSession(
        history: const [],
        repMin: lo,
        repMax: hi,
        rpeTarget: item.rpeTarget,
        coldStartWeight: coldStartWeight(ex, _profile, level),
        machine: spec,
      );
      w = rx.weight;
    }
    if (item.rpeTarget <= 6) w = spec.round(w * 0.9, mode: RoundMode.down); // descarga
    if (!mounted) return;
    setState(() {
      _rx[exId] = rx;
      _aiNote[exId] = aiNote;
      _plan[exId] = _buildPlan(exId, item, w, rx.targetReps, spec);
    });
  }

  List<_PlannedSet> _buildPlan(String exId, WorkoutItem item, double w, int reps, MachineSpec spec) {
    final out = <_PlannedSet>[];
    // Recuperar series ya hechas de tipos extra (reanudar)
    for (final s in _logged.values.where((s) => s.exerciseId == exId && (s.setNumber < 0 || s.setNumber > 100))) {
      out.add(_PlannedSet(s.setNumber, SetKindX.parse(s.technique), s.weight, s.reps));
    }
    final backoff = _topBackoff[exId] ?? false;
    for (int k = 1; k <= item.sets; k++) {
      final kind = backoff && k > 1 ? SetKind.backoff : SetKind.work;
      final ww = kind == SetKind.backoff ? spec.round(w * 0.9, mode: RoundMode.down) : w;
      out.add(_PlannedSet(k, kind, _logged['$exId#$k']?.weight ?? ww, _logged['$exId#$k']?.reps ?? reps));
    }
    out.sort((a, b) => _order(a.slot).compareTo(_order(b.slot)));
    return out;
  }

  int _order(int slot) => slot < 0 ? -1000 - slot : slot; // -1, -2 primero; luego 1..n; luego 101..

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    final routine = _routine!;
    final item = routine.workout[_index];
    final ex = _catalog[_exIdAt(_index)];
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.nameEs),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        actions: [
          IconButton(
            tooltip: 'Escanear máquina (QR / NFC)',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(28), child: _progress(routine)),
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: 350.ms,
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, a) => SlideTransition(
              position: Tween(begin: Offset(0.15 * _dir, 0), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey('${_index}_${_exIdAt(_index)}'),
              child: ex == null ? const Center(child: Text('Ejercicio no encontrado')) : _body(ex, item, routine),
            ),
          ),
          // Récord
          Positioned.fill(
            child: IgnorePointer(child: ConfettiBurst(key: ValueKey(_prCount), trigger: _prCount > 0)),
          ),
          if (_prText != null)
            Positioned(
              top: 12,
              left: 24,
              right: 24,
              child: Card(
                color: Colors.amber,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('🏆 $_prText',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              )
                  .animate(key: ValueKey('pr$_prCount'))
                  .slideY(begin: -1, duration: 400.ms, curve: Curves.elasticOut)
                  .then(delay: 2500.ms)
                  .fadeOut(duration: 400.ms),
            ),
        ],
      ),
    );
  }

  Widget _progress(Routine routine) {
    var total = 0, done = 0;
    for (int i = 0; i < routine.workout.length; i++) {
      final id = _exIdAt(i);
      final plan = _plan[id];
      final n = plan?.where((p) => p.kind != SetKind.warmup).length ?? routine.workout[i].sets;
      total += n;
      done += _logged.values.where((s) => s.exerciseId == id && !s.isWarmup).length.clamp(0, n);
    }
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text('${_index + 1}/${routine.workout.length}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pct),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: v, minHeight: 8, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/$total series', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _body(Exercise ex, WorkoutItem item, Routine routine) {
    final children = <Widget>[
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
      const SizedBox(height: 4),
      _setsSection(ex, item),
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
              child: Text('💡 ${ex.cuesEs.join(' · ')}', style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
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
        icon: const Icon(Icons.flag),
        label: const Text('TERMINAR SESIÓN'),
        style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < children.length; i++)
          children[i].animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut),
      ],
    );
  }

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

  Widget _header(Exercise ex, WorkoutItem item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex.nameEs, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _chip('${item.sets} × ${item.repsTarget}'),
                _chip('RPE ${item.rpeTarget} (deja ${10 - item.rpeTarget})'),
                _chip('Descanso ${item.restSeconds}s'),
                _chip('Tempo ${item.tempo}'),
              ]),
            ]),
          ),
          IconButton(tooltip: 'Cambiar ejercicio', icon: const Icon(Icons.swap_horiz), onPressed: () => _swap(ex)),
        ],
      );

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
          'No tienes registrada una máquina para este ejercicio. Pulsa ⇄ para cambiarlo o escanea su QR.');
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
    final plan = _plan[ex.id];
    if (rx == null || plan == null) {
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
    final w = plan.firstWhere((p) => p.kind != SetKind.warmup, orElse: () => plan.first).weight;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [color.withOpacity(0.22), color.withOpacity(0.05)]),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: NumberCounter(
                value: w,
                decimals: w == w.roundToDouble() ? 0 : 1,
                suffix: ' kg × ${rx.targetReps}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
              ),
            ),
          ),
          if (rx.e1rm != null)
            Text('1RM est. ${rx.e1rm!.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(rx.reason, style: const TextStyle(fontSize: 13)),
        if (_aiNote[ex.id] != null) ...[
          const SizedBox(height: 6),
          Text('🤖 ${_aiNote[ex.id]}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
        if (item.rpeTarget <= 6)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Descarga: peso −10 %.', style: TextStyle(fontSize: 12, color: Colors.white60)),
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
      ]),
    ).animate().shimmer(delay: 300.ms, duration: 1200.ms, color: color.withOpacity(0.25));
  }

  Widget _setsSection(Exercise ex, WorkoutItem item) {
    final plan = _plan[ex.id];
    if (plan == null) return const SizedBox.shrink();
    final spec = _specFor(ex);
    final weights = spec.weights;
    final nextSlot = plan.where((p) => _logged['${ex.id}#${p.slot}'] == null).map((p) => p.slot).firstOrNull;
    var workIdx = 0;
    var warmN = 0;
    final rows = <Widget>[];
    for (final p in plan) {
      final logged = _logged['${ex.id}#${p.slot}'];
      final badge = switch (p.kind) {
        SetKind.warmup => 'A${++warmN}',
        SetKind.drop => 'D',
        _ => '${p.slot}',
      };
      String? hint;
      if (p.kind != SetKind.warmup && logged == null) {
        final pred = _predict(ex, p.weight, p.kind == SetKind.drop ? workIdx : workIdx, item.rpeTarget, drop: p.kind == SetKind.drop);
        if (pred != null) hint = pred;
      }
      if (p.kind != SetKind.warmup && p.kind != SetKind.drop) workIdx++;
      rows.add(SetRow(
        key: ValueKey('${ex.id}_${p.slot}_${logged != null ? 'done' : '${p.weight}_${p.reps}'}'),
        badge: badge,
        kind: p.kind,
        weight: logged?.weight ?? p.weight,
        reps: logged?.reps ?? p.reps,
        rpe: logged?.rpe,
        completed: logged != null,
        weights: weights,
        rpeHint: item.rpeTarget,
        aiHint: hint,
        highlight: p.slot == nextSlot,
        onChanged: (w, r, rpe, done) => _onSet(ex, item, p, w, r, rpe, done),
        onRemove: p.slot < 0 || p.slot > 100 ? () => setState(() => plan.remove(p)) : null,
      ));
    }
    final backoff = _topBackoff[ex.id] ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Series', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Esquema de series',
          onSelected: (v) => _setScheme(ex, item, v == 'backoff'),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(value: 'straight', checked: !backoff, child: const Text('Series rectas (mismo peso)')),
            CheckedPopupMenuItem(value: 'backoff', checked: backoff, child: const Text('Top set + back-off (−10 %)')),
          ],
          child: Row(children: [
            Text(backoff ? 'Top + back-off' : 'Series rectas', style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
            const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
          ]),
        ),
      ]),
      ...rows,
      const SizedBox(height: 4),
      Wrap(spacing: 8, children: [
        ActionChip(
          avatar: const Icon(Icons.local_fire_department, size: 16, color: Colors.lightBlueAccent),
          label: const Text('+ Aproximación'),
          onPressed: () => _addWarmups(ex, spec),
        ),
        ActionChip(
          avatar: const Icon(Icons.south, size: 16, color: Colors.pinkAccent),
          label: const Text('+ Drop set'),
          onPressed: () => _addDrop(ex, spec),
        ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16, color: AppTheme.primary),
          label: const Text('+ Serie'),
          onPressed: () => _addWorkSet(ex, item),
        ),
      ]),
    ]);
  }

  String? _predict(Exercise ex, double w, int setIndex, int rpeTarget, {bool drop = false}) {
    if (_ai == null) return null;
    final machine = _machineFor(ex);
    final mId = machine != null && _ai!.knows(ex.id, machine.id) ? machine.id : null;
    final st = _ai!.strength(ex.id, mId);
    if (st == null || !st.usable) return null;
    final r = _ai!.predictReps(ex.id, mId, ex.category == 'compound', w,
        setIndex: setIndex, readiness: _readinessValue, rir: drop ? 0 : (10 - rpeTarget).toDouble());
    if (r == null) return null;
    return drop ? '~${r.floor()} reps al fallo' : '~${r.floor()} reps a RPE $rpeTarget';
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

  // ------------------------------------------------------------ acciones

  void _goto(int i) {
    setState(() {
      _dir = i >= _index ? 1 : -1;
      _index = i;
      _restVisible = false;
    });
    _ensureRx(i);
  }

  void _setScheme(Exercise ex, WorkoutItem item, bool backoff) {
    _topBackoff[ex.id] = backoff;
    final plan = _plan[ex.id];
    if (plan == null) return;
    final spec = _specFor(ex);
    final top = plan.firstWhere((p) => p.slot == 1, orElse: () => plan.first).weight;
    setState(() {
      for (final p in plan.where((p) => p.slot > 1 && p.slot <= 100)) {
        if (_logged['${ex.id}#${p.slot}'] != null) continue;
        p.kind = backoff ? SetKind.backoff : SetKind.work;
        p.weight = backoff ? spec.round(top * 0.9, mode: RoundMode.down) : top;
      }
    });
  }

  void _addWarmups(Exercise ex, MachineSpec spec) {
    final plan = _plan[ex.id]!;
    final top = plan.firstWhere((p) => p.kind != SetKind.warmup, orElse: () => plan.first).weight;
    final existing = plan.where((p) => p.slot < 0).length;
    setState(() {
      if (existing == 0) {
        plan.insert(0, _PlannedSet(-2, SetKind.warmup, spec.round(top * 0.75, mode: RoundMode.down), 4));
        plan.insert(0, _PlannedSet(-1, SetKind.warmup, spec.round(top * 0.5, mode: RoundMode.down), 8));
      } else {
        final slot = -(existing + 1);
        plan.insert(existing, _PlannedSet(slot, SetKind.warmup, spec.round(top * 0.85, mode: RoundMode.down), 2));
      }
    });
  }

  void _addDrop(Exercise ex, MachineSpec spec) {
    final plan = _plan[ex.id]!;
    final last = plan.last;
    final slot = 101 + plan.where((p) => p.slot > 100).length;
    setState(() => plan.add(_PlannedSet(slot, SetKind.drop, spec.round(last.weight * 0.75, mode: RoundMode.down),
        math.max(6, last.reps))));
  }

  void _addWorkSet(Exercise ex, WorkoutItem item) {
    final plan = _plan[ex.id]!;
    final work = plan.where((p) => p.slot >= 1 && p.slot <= 100).toList();
    final slot = (work.isEmpty ? 0 : work.map((p) => p.slot).reduce(math.max)) + 1;
    final ref0 = work.isEmpty ? plan.last : work.last;
    setState(() {
      final idx = plan.indexWhere((p) => p.slot > 100);
      final s = _PlannedSet(slot, ref0.kind, ref0.weight, ref0.reps);
      idx < 0 ? plan.add(s) : plan.insert(idx, s);
    });
  }

  Future<void> _onSet(Exercise ex, WorkoutItem item, _PlannedSet p, double weight, int reps, int? rpe, bool done) async {
    final key = '${ex.id}#${p.slot}';
    final repo = ref.read(setRepoProvider);
    final existing = _logged[key];
    final machine = _machineFor(ex);
    if (!done) {
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
        technique: existing.technique,
        machineId: existing.machineId,
      );
      await repo.updateSet(upd);
      setState(() => _logged[key] = upd);
      return;
    }
    final s = await repo.logSet(
      sessionId: _session!.id,
      exerciseId: ex.id,
      setNumber: p.slot,
      weight: weight,
      reps: reps,
      rpe: rpe,
      technique: p.kind.technique,
      machineId: machine?.id,
    );
    p.weight = weight;
    p.reps = reps;
    setState(() {
      _logged[key] = s;
      if (p.kind != SetKind.warmup) {
        _restVisible = true;
        _restSeconds = p.kind == SetKind.drop ? 15 : item.restSeconds;
        _restKey++;
      }
    });
    if (p.kind == SetKind.warmup) return;
    _checkRecord(ex, weight, reps, rpe);
    if (p.kind != SetKind.drop) _adapt(ex, item, p, weight, reps, rpe);
  }

  void _checkRecord(Exercise ex, double w, int reps, int? rpe) {
    final e = PerformanceModel.e1rm(w, reps, rpe);
    final best = _bestE1rm[ex.id] ?? 0;
    if (best > 0 && e > best * 1.005) {
      setState(() {
        _bestE1rm[ex.id] = e;
        _prCount++;
        _prText = '¡Récord en ${ex.nameEs}! 1RM est. ${e.toStringAsFixed(1)} kg';
      });
    } else if (e > best) {
      _bestE1rm[ex.id] = e;
    }
  }

  /// Tras una serie: la IA aprende al momento y reajusta las pendientes.
  void _adapt(Exercise ex, WorkoutItem item, _PlannedSet done, double weight, int reps, int? rpe) {
    final plan = _plan[ex.id]!;
    final spec = _specFor(ex);
    final machine = _machineFor(ex);
    final (lo, hi) = item.repRange;
    final workDone = _logged.values
        .where((s) => s.exerciseId == ex.id && !s.isWarmup && s.technique != 'drop')
        .length;
    double? next;
    String why = '';
    final mId = machine != null && (_ai?.knows(ex.id, machine.id) ?? false) ? machine.id : null;
    final usable = _ai?.strength(ex.id, mId)?.usable ?? false;
    if (_ai != null && usable) {
      _ai!.observeLive(TrainingObs(
        exerciseId: ex.id,
        machineId: mId,
        compound: ex.category == 'compound',
        sessionId: _session!.id,
        at: DateTime.now(),
        weight: weight,
        reps: reps,
        rpe: rpe,
        setIndex: workDone - 1,
        readiness: _readinessValue,
      ));
      final target = _rx[ex.id]?.targetReps ?? lo;
      final pred = _ai!.predictReps(ex.id, mId, ex.category == 'compound', weight,
          setIndex: workDone, readiness: _readinessValue, rir: (10 - item.rpeTarget).toDouble());
      if (pred != null && (pred < lo - 0.5 || pred > hi + 2)) {
        next = _ai!.recommendWeight(ex.id, mId, ex.category == 'compound', target, item.rpeTarget,
            setIndex: workDone, readiness: _readinessValue, spec: spec);
        why = 'la IA prevé ~${pred.floor()} reps con ${fmtKg(weight)} kg';
      }
    } else {
      final calibrating = _rx[ex.id]?.action == LoadAction.calibrate && workDone == 1;
      next = LoadEngine.adjustNextSet(
        weight: weight,
        reps: reps,
        rpe: rpe,
        repMin: lo,
        repMax: hi,
        rpeTarget: item.rpeTarget,
        machine: spec,
        calibrating: calibrating,
      );
      why = calibrating ? 'calibrado con tu 1ª serie' : 'por el RPE que has marcado';
    }
    if (next == null || (next - weight).abs() < 1e-6) return;
    var changed = false;
    for (final p in plan) {
      if (p.slot <= done.slot || p.slot > 100 || _logged['${ex.id}#${p.slot}'] != null) continue;
      final target = p.kind == SetKind.backoff ? spec.round(next * 0.9, mode: RoundMode.down) : next;
      if ((p.weight - target).abs() > 1e-6) {
        p.weight = target;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
      _snack('${next > weight ? '⬆' : '⬇'} Siguiente serie a ${fmtKg(next)} kg ($why).');
    }
  }

  Future<void> _scan() async {
    final m = await scanAndResolveMachine(context, ref);
    if (m == null || !mounted) return;
    setState(() => _machines = ref.read(gymMachinesProvider));
    await _jumpToMachine(m);
  }

  Future<void> _jumpToMachine(GymMachine m) async {
    final types = m.typeIds.toSet();
    final r = _routine!;
    int? target;
    for (int i = 0; i < r.workout.length; i++) {
      final ex = _catalog[_exIdAt(i)];
      if (ex == null || !ex.usableWith(types)) continue;
      final doneCount = _logged.values.where((s) => s.exerciseId == ex.id && !s.isWarmup).length;
      target ??= i;
      if (doneCount < r.workout[i].sets) {
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
        child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Cambiar por…', style: TextStyle(fontWeight: FontWeight.w700))),
          if (opts.isEmpty) const ListTile(title: Text('No hay alternativas con tus máquinas para este grupo.')),
          for (final e in opts)
            ListTile(
              title: Text(e.nameEs),
              subtitle: Text(_machineFor(e)?.name ?? (types == null ? '' : 'máquina no registrada')),
              onTap: () => Navigator.pop(context, e),
            ),
        ]),
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
            controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Asiento 4 · Respaldo 2')),
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
    final done = sets.where((x) => x.completed && !x.isWarmup).toList();
    final volume = done.fold<double>(0, (a, b) => a + b.volume);
    await ref.read(sessionRepoProvider).finishSession(s.id, perceivedExertion: rpe, totalSets: done.length, totalVolume: volume);
    ref.invalidate(performanceModelProvider); // la IA reaprende con esta sesión
    final ups = _rx.values.where((r) => r.action == LoadAction.increase).length;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppTheme.primary, size: 48)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.15, duration: 600.ms),
        title: const Text('¡Sesión completada!'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _stat('Series efectivas', done.length.toDouble(), ''),
          _stat('Volumen', volume, ' kg'),
          _stat('Récords', _prCount.toDouble(), ''),
          if (ups > 0) Text('Subiste carga en $ups ejercicio(s) 💪').animate().fadeIn(delay: 900.ms),
          const SizedBox(height: 8),
          const Text('🤖 La IA ya está aprendiendo de esta sesión.', style: TextStyle(fontSize: 12, color: Colors.white60))
              .animate()
              .fadeIn(delay: 1200.ms),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al inicio'))],
      ),
    );
    if (mounted) context.go('/');
  }

  Widget _stat(String label, double v, String suffix) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          NumberCounter(
            value: v,
            suffix: suffix,
            duration: 1200.ms,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
          ),
        ]),
      );

  bool _isFront(Exercise ex) {
    const front = ['pectoralis', 'deltoid_anterior', 'deltoid_lateral', 'biceps', 'brachialis',
      'rectus_abdominis', 'obliques', 'quadriceps', 'adductors'];
    return ex.primaryMuscles.any((m) => front.any(m.contains));
  }
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
          AnimatedSwitcher(
            duration: 200.ms,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$_v',
                key: ValueKey(_v),
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppTheme.rpeColor(_v))),
          ),
          Slider(value: _v.toDouble(), min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _v = v.round())),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Muy fácil', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Text('Máximo', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context, _v), child: const Text('Guardar'))],
      );
}
