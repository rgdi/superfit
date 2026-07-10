// Insights tip-tier: ACWR + Volume Landmarks + PRs predichos + Fatiga + chart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/set_log.dart';
import '../../domain/usecases/advanced_metrics.dart';
import '../../domain/usecases/advanced_analytics.dart';
import '../../widgets/tip_tier_widgets.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E10), Color(0xFF1A1A1F), Color(0xFF0E0E10)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Center(
                child: Text('Registra tu primera sesión\npara ver insights', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              );
            }
            return FutureBuilder<_InsightsData>(
              future: _loadData(ref, sessions.cast()),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                if (!snap.hasData) {
                  return const Center(child: Text('Sin datos suficientes', style: TextStyle(color: Colors.white70)));
                }
                final data = snap.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headerCard(data.acwr),
                      const SizedBox(height: 20),
                      _volumeSection(data.landmarks),
                      const SizedBox(height: 20),
                      _prSection(data.predicted),
                      const SizedBox(height: 20),
                      _fatigueSection(data.fatigue),
                      const SizedBox(height: 20),
                      _weeklyChart(data.weeklyVolume),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard(ACWR acwr) {
    Color zoneColor;
    IconData zoneIcon;
    switch (acwr.zone) {
      case ACWRZone.sweetSpot:
        zoneColor = AppTheme.primary;
        zoneIcon = Icons.favorite;
        break;
      case ACWRZone.underTrained:
        zoneColor = Colors.lightBlue;
        zoneIcon = Icons.bedtime;
        break;
      case ACWRZone.highRisk:
        zoneColor = Colors.orange;
        zoneIcon = Icons.warning_amber;
        break;
      case ACWRZone.overtraining:
        zoneColor = Colors.red;
        zoneIcon = Icons.dangerous;
        break;
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(zoneIcon, color: zoneColor, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ACWR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              NumberCounter(
                value: acwr.ratio,
                decimals: 2,
                style: TextStyle(color: zoneColor, fontSize: 36, fontWeight: FontWeight.w900),
                duration: const Duration(milliseconds: 1000),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(acwr.message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          if (acwr.ratio > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (acwr.ratio / 2.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(zoneColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _volumeSection(List<_MuscleLandmark> landmarks) {
    final sorted = [...landmarks]..sort((a, b) => b.landmark.currentSets.compareTo(a.landmark.currentSets));
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.accent, size: 24),
              SizedBox(width: 8),
              Text('Volume Landmarks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          for (final l in sorted.take(5)) _landmarkRow(l),
        ],
      ),
    );
  }

  Widget _landmarkRow(_MuscleLandmark l) {
    Color color;
    switch (l.landmark.zone) {
      case VolumeZone.belowMEV:
        color = Colors.lightBlue;
        break;
      case VolumeZone.optimal:
        color = AppTheme.primary;
        break;
      case VolumeZone.high:
        color = Colors.orange;
        break;
      case VolumeZone.overreached:
        color = Colors.red;
        break;
    }
    final progress = l.landmark.mrv == 0 ? 0.0 : (l.landmark.currentSets / l.landmark.mrv).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${l.landmark.currentSets}/${l.landmark.mrv} sets', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prSection(List<PredictedMax> prs) {
    if (prs.isEmpty) {
      return const SizedBox.shrink();
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('PRs predichos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          for (final p in prs) _prRow(p),
        ],
      ),
    );
  }

  Widget _prRow(PredictedMax p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(p.exerciseId, style: const TextStyle(color: Colors.white, fontSize: 14))),
          NumberCounter(
            value: p.weight,
            style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.w800),
            suffix: ' kg',
          ),
        ],
      ),
    );
  }

  Widget _fatigueSection(double fatigue) {
    String label;
    Color color;
    if (fatigue < 0.3) {
      label = 'fresco';
      color = AppTheme.primary;
    } else if (fatigue < 0.6) {
      label = 'cargado';
      color = Colors.amber;
    } else if (fatigue < 0.85) {
      label = 'pesado';
      color = Colors.orange;
    } else {
      label = '¡deload!';
      color = Colors.red;
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Fatiga (EMA)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NumberCounter(
                value: (fatigue * 100).round(),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                suffix: '%',
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyChart(List<double> volumes) {
    if (volumes.isEmpty || volumes.every((v) => v == 0)) return const SizedBox.shrink();
    final maxV = volumes.reduce((a, b) => a > b ? a : b);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primary, size: 24),
              SizedBox(width: 8),
              Text('Volumen semanal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxV * 1.1,
                barGroups: [
                  for (int i = 0; i < volumes.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: volumes[i],
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]),
                ],
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleLandmark {
  final String name;
  final VolumeLandmarks landmark;
  _MuscleLandmark(this.name, this.landmark);
}

class _InsightsData {
  final ACWR acwr;
  final List<_MuscleLandmark> landmarks;
  final List<PredictedMax> predicted;
  final double fatigue;
  final List<double> weeklyVolume;
  _InsightsData(this.acwr, this.landmarks, this.predicted, this.fatigue, this.weeklyVolume);
}


double _calcFatigue(List<dynamic> sessions, List<List<SetLog>> allSets) {
  if (sessions.isEmpty) return 0;
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  double weekVol = 0;
  for (int i = 0; i < sessions.length; i++) {
    final s = sessions[i];
    if (s.startedAt.isAfter(weekAgo)) {
      for (final set in allSets[i]) {
        weekVol += set.weight * set.reps;
      }
    }
  }
  // normalize: 5000 = 50% fatigue, 15000 = 100%
  return (weekVol / 10000).clamp(0.0, 1.0);
}

Future<_InsightsData> _loadData(WidgetRef ref, List<dynamic> sessions) async {
  final analytics = AdvancedAnalytics(ref.read(setRepoProvider));
  final db = await ref.read(databaseProvider.future);

  // Load sets per session
  final List<List<SetLog>> allSets = [];
  for (final s in sessions) {
    final rows = await db.query('set_logs', where: 'session_id = ?', whereArgs: [s.id]);
    allSets.add(rows.map((m) => SetLog.fromMap(m)).toList());
  }

  // ACWR
  final acwr = ACWRCalculator.compute(sessions, allSets);

  // Volume per muscle
  final Map<String, int> setsPerMuscle = {};
  for (final sets in allSets) {
    for (final set in sets) {
      final ex = await db.query('exercises', where: 'id = ?', whereArgs: [set.exerciseId], limit: 1);
      if (ex.isNotEmpty) {
        final primary = (ex.first['primary_muscles'] as String? ?? '').split(',');
        for (final m in primary) {
          if (m.trim().isEmpty) continue;
          setsPerMuscle[m.trim()] = (setsPerMuscle[m.trim()] ?? 0) + 1;
        }
      }
    }
  }
  final landmarks = setsPerMuscle.entries
      .map((e) => _MuscleLandmark(e.key, VolumeLandmarkCalculator.computeForMuscle(e.key, e.value)))
      .toList();

  // PRs predichos: por ejercicio, 1RM histórico
  final predicted = <PredictedMax>[];
  final exerciseIds = <String>{};
  for (final sets in allSets) {
    for (final s in sets) {
      exerciseIds.add(s.exerciseId);
    }
  }
  for (final exId in exerciseIds.take(5)) {
    final history = <double>[];
    for (final sets in allSets) {
      for (final s in sets) {
        if (s.exerciseId == exId) {
          history.add(ProgressionMath.epley1RM(s.weight.toDouble(), s.reps));
        }
      }
    }
    if (history.length >= 2) {
      final pr = await analytics.predictNextPR(exId, lastSets: history.length);
      if (pr != null) predicted.add(pr);
    }
  }

  // Fatiga
  // Simple fatigue calc: volume this week / chronic avg
  final fatigue = _calcFatigue(sessions, allSets);

  // Volumen semanal (últimas 4 semanas)
  final now = DateTime.now();
  final weeklyVolume = <double>[];
  for (int w = 3; w >= 0; w--) {
    final weekStart = now.subtract(Duration(days: (w + 1) * 7));
    final weekEnd = now.subtract(Duration(days: w * 7));
    double total = 0;
    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      if (s.startedAt.isAfter(weekStart) && s.startedAt.isBefore(weekEnd)) {
        if (i < allSets.length) {
          for (final set in allSets[i]) {
            total += set.weight * set.reps;
          }
        }
      }
    }
    weeklyVolume.add(total);
  }

  return _InsightsData(acwr, landmarks, predicted, fatigue, weeklyVolume);
}
