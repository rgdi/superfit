// Mapa de músculos entrenados + máquinas más eficientes.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/generated_program.dart';
import '../../data/models/machine.dart';
import '../../data/models/muscle.dart';
import '../../data/models/routine.dart';
import '../../data/models/set_log.dart';
import '../../data/models/workout_item.dart';
import '../../domain/engine/efficiency.dart';
import '../../domain/engine/muscle_stats.dart';
import '../../domain/engine/program_generator.dart' show contraindicatedFor;
import '../../widgets/body_heatmap.dart';

class _Data {
  final List<Muscle> muscles;
  final Map<String, Exercise> exercises;
  final Map<String, Machine> machineTypes;
  final List<SetLog> sets;
  const _Data(this.muscles, this.exercises, this.machineTypes, this.sets);
}

class MuscleMapScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const MuscleMapScreen({super.key, this.initialTab = 0});
  @override
  ConsumerState<MuscleMapScreen> createState() => _MuscleMapScreenState();
}

class _MuscleMapScreenState extends ConsumerState<MuscleMapScreen> {
  late final Future<_Data> _data = _load();
  bool _recoveryMode = false;
  String? _selected;
  bool _essential = true;

  Future<_Data> _load() async {
    final cat = ref.read(catalogRepoProvider);
    final muscles = await cat.muscles();
    final ex = {for (final e in await cat.exercises()) e.id: e};
    final types = {for (final m in await cat.machines()) m.id: m};
    final sets = await ref.read(setRepoProvider).allCompleted();
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    return _Data(muscles, ex, types, sets.where((s) => s.performedAt.isAfter(cutoff)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Músculos'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.accessibility_new), text: 'Mapa'),
            Tab(icon: Icon(Icons.bolt), text: 'Máquinas eficientes'),
          ]),
        ),
        body: FutureBuilder<_Data>(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return TabBarView(children: [_mapTab(snap.data!), _efficientTab(snap.data!)]);
          },
        ),
      ),
    );
  }

  // ======================================================================= MAPA

  Widget _mapTab(_Data d) {
    final level = ref.watch(userSettingsProvider).level;
    final stats = computeMuscleStats(
      sets: d.sets,
      catalog: d.exercises,
      muscleIds: d.muscles.map((m) => m.id),
      level: level,
    );
    final colors = {
      for (final s in stats.values)
        s.id: _recoveryMode
            ? (s.lastTrained == null ? const Color(0xFF34343A) : recoveryColor(s.recovery))
            : heatColor(s.ratio),
    };
    final names = {for (final m in d.muscles) m.id: m.nameEs};
    final inTarget = stats.values.where((s) => s.ratio >= 0.9 && s.ratio <= 1.5).length;
    final low = stats.values.where((s) => s.weeklySets >= 0.5 && s.ratio < 0.9).length;
    final none = stats.values.where((s) => s.weeklySets < 0.5).length;
    final sorted = stats.values.toList()..sort((a, b) => a.ratio.compareTo(b.ratio));

    final items = <Widget>[
      Center(
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('🔥 Volumen')),
            ButtonSegment(value: true, label: Text('🔋 Recuperación')),
          ],
          selected: {_recoveryMode},
          onSelectionChanged: (s) => setState(() => _recoveryMode = s.first),
        ),
      ),
      const SizedBox(height: 12),
      BodyHeatmap(
        key: ValueKey(_recoveryMode),
        colors: colors,
        selected: _selected,
        onTap: (id) => setState(() => _selected = _selected == id ? null : id),
      ),
      const SizedBox(height: 8),
      _legend(),
      const SizedBox(height: 12),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, child: FadeTransition(opacity: a, child: c)),
        child: _selected == null
            ? Text('Toca un músculo para ver su detalle.',
                key: const ValueKey('hint'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54))
            : _detail(stats[_selected]!, names, d, key: ValueKey(_selected)),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _pill('$inTarget', 'en objetivo', const Color(0xFF3DDC84)),
        _pill('$low', 'por debajo', const Color(0xFF1FA4B8)),
        _pill('$none', 'sin trabajar', Colors.white38),
      ]),
      const SizedBox(height: 12),
      const Text('Lo que más necesita trabajo (7 días)', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      for (final s in sorted.take(23))
        InkWell(
          onTap: () => setState(() => _selected = s.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(width: 150, child: Text(names[s.id] ?? s.id, style: const TextStyle(fontSize: 12))),
              Expanded(child: _bar(s.ratio / 1.5, heatColor(s.ratio))),
              SizedBox(
                width: 64,
                child: Text('${_fmt(s.weeklySets)}/${_fmt(s.target)}',
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'Series: músculo principal = 1, secundario = 0,5 (recuento fraccional, Pelland 2026). '
        'El objetivo semanal es orientativo según tu nivel. La recuperación es una estimación por tiempo y '
        'esfuerzo, no una medida de tu músculo.',
        style: TextStyle(fontSize: 11, color: Colors.white38),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.animate(interval: 40.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
    );
  }

  Widget _legend() => _recoveryMode
      ? Wrap(alignment: WrapAlignment.center, runSpacing: 4, children: [
          _dot(recoveryColor(0), 'Fatigado'),
          _dot(recoveryColor(0.5), 'Recuperándose'),
          _dot(recoveryColor(1), 'Listo'),
        ])
      : Wrap(alignment: WrapAlignment.center, runSpacing: 4, children: [
          _dot(heatColor(0.3), 'Poco'),
          _dot(heatColor(1), 'En objetivo'),
          _dot(heatColor(2), 'Mucho'),
        ]);

  Widget _dot(Color c, String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      );

  Widget _pill(String n, String label, Color c) => Expanded(
        child: Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
            ]),
          ),
        ),
      );

  Widget _bar(double frac, Color c) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: frac.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, f, __) => Stack(children: [
          Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: f,
            child: Container(height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
          ),
        ]),
      );

  Widget _detail(MuscleStat s, Map<String, String> names, _Data d, {Key? key}) {
    final machines = ref.read(gymMachinesProvider);
    final types = availableMachineTypes(machines);
    final injuries = ref.read(trainingProfileProvider).injuries;
    // Mejor ejercicio para este músculo con tus máquinas
    final options = d.exercises.values
        .where((e) =>
            e.primaryMuscles.contains(s.id) &&
            (types == null || e.usableWith(types)) &&
            !contraindicatedFor(e, injuries))
        .toList()
      ..sort((a, b) => (kLengthTips.containsKey(b.id) ? 1 : 0).compareTo(kLengthTips.containsKey(a.id) ? 1 : 0));
    final best = options.firstOrNull;
    final since = s.lastTrained == null ? null : DateTime.now().difference(s.lastTrained!);
    final contrib = s.byExercise.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      key: key,
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(names[s.id] ?? s.id, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: heatColor(s.ratio).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(s.status, style: TextStyle(fontSize: 11, color: heatColor(s.ratio == 0 ? 0.3 : s.ratio))),
            ),
          ]),
          const SizedBox(height: 10),
          Text('Series esta semana: ${_fmt(s.weeklySets)} de ~${_fmt(s.target)}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          _bar(s.ratio / 1.5, heatColor(s.ratio)),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.battery_charging_full, size: 16, color: recoveryColor(s.recovery)),
            const SizedBox(width: 6),
            Expanded(child: Text(
              since == null
                  ? 'Sin entrenar en 14 días'
                  : 'Recuperación ~${(s.recovery * 100).round()} % · hace ${since.inHours < 48 ? '${since.inHours} h' : '${since.inDays} días'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            )),
          ]),
          if (contrib.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Lo han trabajado:', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final e in contrib.take(4))
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${d.exercises[e.key]?.nameEs ?? e.key} · ${_fmt(e.value)}',
                      style: const TextStyle(fontSize: 11)),
                ),
            ]),
          ],
          if (best != null) ...[
            const Divider(height: 20),
            Text('💡 Para trabajarlo: ${best.nameEs}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (machineForExercise(best, machines) != null)
              Text('en tu ${machineForExercise(best, machines)!.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
            if (kLengthTips[best.id] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(kLengthTips[best.id]!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ),
          ] else if (types != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Ninguna de tus máquinas lo trabaja como músculo principal.',
                  style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
            ),
        ]),
      ),
    );
  }

  // ============================================================ EFICIENTES

  Widget _efficientTab(_Data d) {
    final machines = ref.watch(gymMachinesProvider);
    final types = availableMachineTypes(machines);
    final injuries = ref.watch(trainingProfileProvider).injuries;
    final exclude = d.exercises.values.where((e) => contraindicatedFor(e, injuries)).map((e) => e.id).toSet();
    final plan = planMinimalCircuit(
      catalog: d.exercises.values.toList(),
      muscleIds: d.muscles.map((m) => m.id),
      availableTypes: types,
      exclude: exclude,
      essential: _essential,
    );
    final names = {for (final m in d.muscles) m.id: m.nameEs};
    final covColors = {
      for (final e in plan.coverage.entries)
        e.key: e.value >= 1 ? heatColor(1) : (e.value > 0 ? heatColor(0.45) : const Color(0xFF34343A)),
    };
    // ¿Qué máquina añadir para cubrir lo que falta?
    String? addSuggestion;
    if (types != null && plan.uncovered.isNotEmpty) {
      final ideal = planMinimalCircuit(
        catalog: d.exercises.values.toList(),
        muscleIds: plan.uncovered,
        exclude: exclude,
        essential: false,
      );
      final need = ideal.picks.map((p) => d.machineTypes[p.exercise.equipmentId]?.nameEs).whereType<String>().toSet();
      if (need.isNotEmpty) addSuggestion = 'Si tu gimnasio tiene: ${need.join(', ')} — añádelas en Mis máquinas.';
    }

    final items = <Widget>[
      Center(
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Esencial')),
            ButtonSegment(value: false, label: Text('Completo')),
          ],
          selected: {_essential},
          onSelectionChanged: (s) => setState(() => _essential = s.first),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _essential
            ? 'Lo mínimo que más rinde: los grupos grandes con las menos máquinas posibles.'
            : 'Todos los músculos, incluidos los pequeños, con el mínimo de ejercicios.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _pill('${plan.picks.length}', 'máquinas', AppTheme.primary),
        _pill('~${plan.minutes}', 'min (2 series)', AppTheme.primary),
        _pill('${plan.coverage.values.where((v) => v >= 1).length}/${plan.coverage.length}', 'músculos', AppTheme.primary),
      ]),
      const SizedBox(height: 8),
      BodyHeatmap(key: ValueKey('cov$_essential${plan.picks.length}'), colors: covColors, height: 260),
      Wrap(alignment: WrapAlignment.center, runSpacing: 4, children: [
        _dot(heatColor(1), 'Directo'),
        _dot(heatColor(0.45), 'Indirecto'),
        _dot(const Color(0xFF34343A), 'Sin trabajar'),
      ]),
      const SizedBox(height: 12),
      for (final (i, p) in plan.picks.indexed) _pickCard(i + 1, p, names, machines),
      if (plan.uncovered.isNotEmpty)
        Card(
          color: Colors.amber.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Sin trabajar: ${plan.uncovered.map((m) => names[m] ?? m).join(', ')}.'
              '${addSuggestion != null ? '\n$addSuggestion' : (_essential ? '\nCámbiate a "Completo" para incluirlos.' : '')}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      if (plan.partial.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Solo de forma indirecta: ${plan.partial.map((m) => names[m] ?? m).join(', ')}.',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: plan.picks.isEmpty ? null : () => _useAsProgram(plan),
        icon: const Icon(Icons.playlist_add_check),
        label: const Text('Usar como mi programa'),
      ),
      const SizedBox(height: 16),
      _honestCard(),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.05),
    );
  }

  Widget _pickCard(int n, EfficientPick p, Map<String, String> names, List machines) {
    final m = machineForExercise(p.exercise, ref.read(gymMachinesProvider));
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Text('$n', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.exercise.nameEs, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (m != null) Text(m.name, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (final c in p.covers) _tag(names[c] ?? c, heatColor(1)),
                for (final c in p.helps) _tag(names[c] ?? c, heatColor(0.45)),
              ]),
              const SizedBox(height: 6),
              Text(p.why, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              if (p.tip != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('💡 ${p.tip}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: TextStyle(fontSize: 10, color: c)),
      );

  Widget _honestCard() => const Card(
        color: AppTheme.surfaceMid,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Por qué no "máxima activación": la activación medida con electromiografía no predice bien cuánto crece '
            'un músculo (Vigotsky 2017). Por eso optimizo cuántos músculos trabajas directamente por cada máquina, '
            'priorizando multiarticulares, y añado variantes que entrenan el músculo estirado, que sí tienen respaldo '
            '(Maeo 2021 y 2023, Pedrosa 2022, Kassiano 2023). 2 series cerca del fallo por ejercicio, 2-3 veces por '
            'semana, ya producen ganancias; más series dan más resultado, con rendimientos decrecientes.',
            style: TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ),
      );

  Future<void> _useAsProgram(EfficientPlan plan) async {
    final profile = ref.read(trainingProfileProvider);
    final settings = ref.read(userSettingsProvider);
    final items = [
      for (final p in plan.picks)
        WorkoutItem(
          exerciseId: p.exercise.id,
          sets: 2,
          repsTarget: p.exercise.defaultReps,
          rpeTarget: 8,
          restSeconds: p.exercise.category == 'compound' ? 120 : 75,
          tempo: p.exercise.tempo,
          notesEs: p.tip,
        ),
    ];
    final routine = Routine(
      id: 'gen_1',
      nameEs: _essential ? 'Circuito esencial' : 'Circuito completo',
      nameEn: _essential ? 'Essential circuit' : 'Full circuit',
      dayOfWeek: 1,
      estimatedMinutes: plan.minutes,
      level: settings.level.name,
      goal: settings.goal.name,
      warmup: const [],
      workout: items,
      cooldown: const [],
    );
    final now = DateTime.now();
    final program = GeneratedProgram(
      createdAt: now,
      startDate: DateTime(now.year, now.month, now.day),
      splitName: routine.nameEs,
      routines: [routine],
      rotation: const ['gen_1'],
      mesocycleWeeks: profile.mesocycleWeeks,
      rationale: [
        'Circuito de mínimo esfuerzo: ${plan.picks.length} máquinas que cubren '
            '${plan.coverage.values.where((v) => v >= 1).length} de ${plan.coverage.length} músculos directamente.',
        '2 series por ejercicio cerca del fallo, cuerpo completo, ${profile.daysPerWeek.clamp(2, 3)} veces por semana.',
        'La IA y la doble progresión ajustan el peso en cada sesión.',
      ],
      weeklySets: const {},
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Usar este circuito?'),
        content: Text('Sustituirá tu programa actual por "${routine.nameEs}" (${plan.picks.length} máquinas, ~${plan.minutes} min).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(programProvider.notifier).set(program);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listo: aparecerá en "Hoy".')));
    }
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
