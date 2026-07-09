import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';
import '../../domain/usecases/cycle_planner.dart';
import '../../domain/usecases/routine_recommender.dart';
import '../routines/routines_screen.dart';
import '../../widgets/visual_widgets.dart';
import '../../widgets/hero_routine_card.dart';
import '../../domain/usecases/advanced_analytics.dart';
import '../history/history_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const RoutinesScreen(),
      const HistoryScreen(),
      const ProgressScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Rutinas'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogRepo = ref.watch(catalogRepoProvider);
    final sessionRepo = ref.watch(sessionRepoProvider);
    final settings = ref.watch(userSettingsProvider);
    final locale = settings.locale;

    return FutureBuilder<RoutineRecommendation>(
      future: () async {
        final routines = await catalogRepo.routines();
        final plan = await catalogRepo.plan();
        final planner = CyclePlanner(plan, settings);
        final recommender = RoutineRecommender(planner, sessionRepo);
        return recommender.recommendForToday(routines);
      }(),
      builder: (context, snap) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Hola 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Text(
                _greeting(),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              _streakCard(ref),
              const SizedBox(height: 16),
              _todayCard(context, ref, snap, locale),
              const SizedBox(height: 16),
              _lastSessionCard(ref),
              const SizedBox(height: 16),
              _volumeChart(ref),
              const SizedBox(height: 16),
              _quickActions(context),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días. Listo para entrenar?';
    if (h < 20) return 'Buenas tardes. A por el entreno.';
    return 'Buenas noches. Mañana más.';
  }

  Widget _streakCard(WidgetRef ref) {
    return FutureBuilder<int>(
      future: ref.read(sessionRepoProvider).currentStreakDays(),
      builder: (context, snap) {
        final streak = snap.data ?? 0;
        return Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak días',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const Text('racha de entrenamiento',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _fatigueCard(WidgetRef ref) {
    return FutureBuilder(
      future: AdvancedAnalytics(ref.read(setRepoProvider)).detectFatigue(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.totalSets7d == 0) {
          return const SizedBox.shrink();
        }
        return FatigueRing(
          fatigue: snap.data!.fatigueIndex,
          recommendation: snap.data!.recommendation,
        );
      },
    );
  }
  Widget _todayCard(BuildContext context, WidgetRef ref, AsyncSnapshot<RoutineRecommendation> snap, String locale) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final rec = snap.data;
    if (rec == null || rec.routine == null) {
      return Card(
        color: AppTheme.surfaceMid,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.bedtime, size: 48, color: Colors.white60),
              const SizedBox(height: 12),
              Text(
                rec?.reason ?? 'No hay rutina planificada hoy.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return HeroRoutineCard(
      routine: rec.routine!,
      reason: rec.reason ?? '',
      locale: locale,
      onView: () => context.push('/routines/${rec.routine!.id}'),
      onStart: () => _startRoutine(context, ref, rec.routine!),
    );
  }

  Future<void> _startRoutine(BuildContext context, WidgetRef ref, Routine r) async {
    final session = await ref.read(sessionRepoProvider).startSession(r.id);
    if (context.mounted) context.push('/workout/${session.id}');
  }

  Widget _lastSessionCard(WidgetRef ref) {
    return FutureBuilder<WorkoutSession?>(
      future: ref.read(sessionRepoProvider).activeSession().then((s) async {
        if (s != null) return s;
        final r = await ref.read(sessionRepoProvider).recentSessions(limit: 1);
        return r.isEmpty ? null : r.first;
      }),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        final s = snap.data!;
        if (s.isActive) {
          return Card(
            color: AppTheme.primary.withOpacity(0.15),
            child: InkWell(
              onTap: () => context.push('/workout/${s.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sesión activa',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        }
        return Card(
          color: AppTheme.surfaceMid,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: AppTheme.primary),
            title: Text('Última: ${s.routineId}'),
            subtitle: Text(
              '${s.startedAt.day}/${s.startedAt.month} · ${s.totalSets ?? 0} series · RPE ${s.perceivedExertion ?? "—"}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/history/${s.id}'),
          ),
        );
      },
    );
  }

  Widget _volumeChart(WidgetRef ref) {
    return FutureBuilder<List<WorkoutSession>>(
      future: ref.read(sessionRepoProvider).recentSessions(limit: 20),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final sessions = snap.data!.take(8).toList().reversed.toList();
        return Card(
          color: AppTheme.surfaceMid,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Volumen por sesión (kg · reps)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < sessions.length; i++)
                              FlSpot(i.toDouble(), sessions[i].totalVolume ?? 0),
                          ],
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primary.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _actionCard(Icons.camera_alt, 'Foto progreso', () => context.push('/progress/photos'))),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(Icons.menu_book, 'Ejercicios', () => context.push('/exercises'))),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      color: AppTheme.surfaceMid,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
