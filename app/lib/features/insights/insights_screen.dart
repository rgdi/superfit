// Pantalla de insights: fatiga, PRs predichos, tendencias
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/set_repo.dart';
import '../../data/repositories/session_repo.dart';
import '../../data/models/workout_session.dart';
import '../../domain/usecases/advanced_analytics.dart';
import '../../widgets/visual_widgets.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late Future<FatigueReport> _fatigueFuture;
  late Future<List<PredictedMax>> _prsFuture;

  @override
  void initState() {
    super.initState();
    final analytics = AdvancedAnalytics(ref.read(setRepoProvider));
    _fatigueFuture = analytics.detectFatigue();
    _loadPRs(analytics);
  }

  Future<void> _loadPRs(AdvancedAnalytics analytics) async {
    final exercises = await ref.read(catalogRepoProvider).exercises();
    final prs = <PredictedMax>[];
    for (final ex in exercises.take(8)) {
      final pr = await analytics.predictNextPR(ex.id);
      if (pr != null && pr.confidence > 0.3) prs.add(pr);
    }
    prs.sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
    if (mounted) {
      setState(() {
        _prsFuture = Future.value(prs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tu cuerpo ahora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          FutureBuilder<FatigueReport>(
            future: _fatigueFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Card(
                  child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                );
              }
              final f = snap.data!;
              return Column(
                children: [
                  FatigueRing(fatigue: f.fatigueIndex, recommendation: f.recommendation),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: StatChip(icon: Icons.thermostat, label: 'RPE EMA 7d', value: f.emaRpe7d.toStringAsFixed(1))),
                      const SizedBox(width: 8),
                      Expanded(child: StatChip(icon: Icons.fitness_center, label: 'Series 7d', value: '${f.totalSets7d}', color: AppTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: StatChip(icon: Icons.scale, label: 'Volumen 7d', value: '${(f.totalVolume7d/1000).toStringAsFixed(1)}t', color: AppTheme.muscleTriceps)),
                      const SizedBox(width: 8),
                      Expanded(child: StatChip(icon: Icons.show_chart, label: 'EMA Vol', value: f.emaVolume7d.toStringAsFixed(0), color: AppTheme.muscleGlute)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('PRs predichos (próximas semanas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Regresión lineal sobre tus últimos sets. Confianza > 0.3 = señal fiable.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PredictedMax>>(
            future: _prsFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
              }
              final prs = snap.data!;
              if (prs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Necesitas más datos. Registra al menos 3 sesiones por ejercicio.', style: TextStyle(color: Colors.white60)),
                  ),
                );
              }
              return Card(
                color: AppTheme.surfaceMid,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (int i = 0; i < prs.take(5).length; i++) _prRow(prs[i], i + 1),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Tendencia volumen semanal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _weeklyVolumeChart(),
        ],
      ),
    );
  }

  Widget _prRow(PredictedMax pr, int rank) {
    return FutureBuilder(
      future: ref.read(catalogRepoProvider).exerciseById(pr.exerciseId),
      builder: (context, snap) {
        final name = snap.data?.nameEs ?? pr.exerciseId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text('$rank', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
          ),
          title: Text(name.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('1RM estimado: ${pr.estimated1RM.toStringAsFixed(1)} kg · confianza ${(pr.confidence * 100).round()}%'),
          trailing: GainBadge(weight: pr.weight, reps: pr.reps, exerciseName: name),
        );
      },
    );
  }

  Widget _weeklyVolumeChart() {
    return FutureBuilder<List<WorkoutSession>>(
      future: ref.read(sessionRepoProvider).recentSessions(limit: 30),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        final sessions = snap.data!;
        if (sessions.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sin sesiones.', style: TextStyle(color: Colors.white60)),
            ),
          );
        }
        // agrupar por semana
        final byWeek = <String, double>{};
        for (final s in sessions) {
          final yearWeek = _isoWeek(s.startedAt);
          byWeek[yearWeek] = (byWeek[yearWeek] ?? 0) + (s.totalVolume ?? 0);
        }
        final entries = byWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entries[i].key.split('-').last, style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value,
                            color: AppTheme.primary,
                            width: 24,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _isoWeek(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final week = (dayOfYear / 7).floor() + 1;
    return '${d.year}-W$week';
  }
}
