// Historial de una máquina física: cada ejercicio que haces en ella, con su
// propio peso, evolución del 1RM estimado y la estimación de la IA.
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/gym_machine.dart';
import '../../data/models/set_log.dart';
import '../../domain/ai/performance_model.dart';
import '../../widgets/set_row.dart' show fmtKg, SetKind, SetKindX;
import '../../widgets/tip_tier_widgets.dart';
import 'gym_machines_screen.dart' show MachineEditScreen;

class MachineHistoryScreen extends ConsumerWidget {
  final GymMachine machine;
  const MachineHistoryScreen({super.key, required this.machine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(machine.name), actions: [
        IconButton(
          tooltip: 'Editar máquina',
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => MachineEditScreen(machine: machine))),
        ),
      ]),
      body: FutureBuilder<(List<SetLog>, Map<String, Exercise>, PerformanceModel?)>(
        future: () async {
          final sets = await ref.read(setRepoProvider).setsForMachine(machine.id);
          final ex = {for (final e in await ref.read(catalogRepoProvider).exercises()) e.id: e};
          PerformanceModel? ai;
          try {
            ai = await ref.read(performanceModelProvider.future);
          } catch (_) {}
          return (sets, ex, ai);
        }(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (sets, catalog, ai) = snap.data!;
          if (sets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no hay series en esta máquina.\nCuando entrenes en ella verás aquí el historial de cada ejercicio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            );
          }
          final byExercise = groupBy<SetLog, String>(sets, (s) => s.exerciseId);
          final working = sets.where((s) => !s.isWarmup).toList();
          final sessions = sets.map((s) => s.sessionId).toSet().length;
          final best = working.isEmpty ? 0.0 : working.map((s) => s.weight).reduce(math.max);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                _tile('Sesiones', sessions.toDouble(), ''),
                _tile('Series', working.length.toDouble(), ''),
                _tile('Máx. peso', best, ' kg'),
              ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
              if (machine.setupNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('⚙ ${machine.setupNotes}', style: const TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 16),
              for (final (i, e) in byExercise.entries.indexed)
                _ExerciseHistory(
                  exercise: catalog[e.key],
                  exerciseId: e.key,
                  sets: e.value,
                  machineId: machine.id,
                  ai: ai,
                ).animate().fadeIn(delay: (120 * (i + 1)).ms, duration: 400.ms).slideY(begin: 0.08),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String label, double v, String suffix) => Expanded(
        child: Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              NumberCounter(
                value: v,
                decimals: v == v.roundToDouble() ? 0 : 1,
                suffix: suffix,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
            ]),
          ),
        ),
      );
}

class _ExerciseHistory extends StatelessWidget {
  final Exercise? exercise;
  final String exerciseId;
  final List<SetLog> sets;
  final String machineId;
  final PerformanceModel? ai;
  const _ExerciseHistory({
    required this.exercise,
    required this.exerciseId,
    required this.sets,
    required this.machineId,
    required this.ai,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = groupBy<SetLog, String>(sets.where((s) => !s.isWarmup), (s) => s.sessionId)
        .values
        .map((ss) => ss..sort((a, b) => a.performedAt.compareTo(b.performedAt)))
        .toList()
      ..sort((a, b) => a.first.performedAt.compareTo(b.first.performedAt));
    final e1rmPts = <FlSpot>[];
    final topPts = <FlSpot>[];
    final t0 = sessions.isEmpty ? DateTime.now() : sessions.first.first.performedAt;
    for (final ss in sessions) {
      final x = ss.first.performedAt.difference(t0).inHours / 24.0;
      e1rmPts.add(FlSpot(x, ss.map((s) => PerformanceModel.e1rm(s.weight, s.reps, s.rpe)).reduce(math.max)));
      topPts.add(FlSpot(x, ss.map((s) => s.weight).reduce(math.max)));
    }
    final st = ai?.strength(exerciseId, machineId);
    final aiPts = st == null
        ? <FlSpot>[]
        : st.history.map((h) => FlSpot(h.$1.difference(t0).inHours / 24.0, h.$2)).toList();
    final allY = [...e1rmPts, ...topPts, ...aiPts].map((p) => p.y);
    final minY = allY.isEmpty ? 0.0 : allY.reduce(math.min) * 0.9;
    final maxY = allY.isEmpty ? 10.0 : allY.reduce(math.max) * 1.08;

    return Card(
      color: AppTheme.surfaceMid,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise?.nameEs ?? exerciseId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (st != null)
            Text(
              '🤖 1RM estimado por la IA: ${st.oneRm.toStringAsFixed(1)} kg (±${(st.sd * 100).toStringAsFixed(0)} %, '
              'confianza ${st.confidence})'
              '${st.trendPerWeek.abs() > 0.002 ? ' · ${st.trendPerWeek > 0 ? '↗' : '↘'} ${(st.trendPerWeek * 100).toStringAsFixed(1)} %/sem' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          const SizedBox(height: 12),
          if (sessions.length >= 2)
            SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) =>
                            Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    _line(topPts, Colors.white54, dashed: false, area: false),
                    _line(e1rmPts, AppTheme.primary, dashed: false, area: true),
                    if (aiPts.length >= 2) _line(aiPts, Colors.amberAccent, dashed: true, area: false),
                  ],
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
              ),
            ),
          if (sessions.length >= 2)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Wrap(spacing: 12, children: [
                _Legend(AppTheme.primary, '1RM estimado'),
                _Legend(Colors.white54, 'Peso máximo'),
                _Legend(Colors.amberAccent, 'IA'),
              ]),
            ),
          const SizedBox(height: 10),
          for (final ss in sessions.reversed.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 52,
                  child: Text('${ss.first.performedAt.day}/${ss.first.performedAt.month}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 4, children: [
                    for (final s in ss)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SetKindX.parse(s.technique).color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${fmtKg(s.weight)}×${s.reps}${s.rpe != null ? ' @${s.rpe}' : ''}'
                          '${SetKindX.parse(s.technique) == SetKind.drop ? ' D' : ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> pts, Color c, {required bool dashed, required bool area}) => LineChartBarData(
        spots: pts,
        isCurved: true,
        preventCurveOverShooting: true,
        color: c,
        barWidth: dashed ? 2 : 3,
        dashArray: dashed ? [6, 4] : null,
        dotData: FlDotData(show: !dashed && pts.length < 15),
        belowBarData: BarAreaData(
          show: area,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.withOpacity(0.3), c.withOpacity(0.0)],
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend(this.color, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ]);
}
