// Inicio — minimalista: lo de hoy, la semana en una línea y accesos en lista.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/routine.dart';
import '../../data/models/set_log.dart';
import '../../data/models/workout_session.dart';
import '../../domain/ai/performance_model.dart';
import '../../domain/usecases/cycle_planner.dart';
import '../../domain/usecases/routine_recommender.dart';
import '../gym/machine_history_screen.dart';
import '../gym/scan_machine.dart';
import '../history/history_screen.dart';
import '../progress/progress_screen.dart';
import '../routines/routines_screen.dart';
import '../settings/settings_screen.dart';
import 'program_today_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [_HomeTab(), RoutinesScreen(), HistoryScreen(), ProgressScreen(), SettingsScreen()];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Hoy'),
            NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda), label: 'Rutinas'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
            NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progreso'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _HomeData {
  final List<WorkoutSession> sessions;
  final WorkoutSession? active;
  final List<SetLog> sets;
  final RoutineRecommendation? fallback;
  const _HomeData(this.sessions, this.active, this.sets, this.fallback);
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  Future<_HomeData> _load(WidgetRef ref) async {
    final cat = ref.read(catalogRepoProvider);
    final sessionRepo = ref.read(sessionRepoProvider);
    final sessions = await sessionRepo.recentSessions(limit: 60);
    final active = await sessionRepo.activeSession();
    final cutoff = DateTime.now().subtract(const Duration(days: 35));
    final sets = (await ref.read(setRepoProvider).allCompleted()).where((s) => s.performedAt.isAfter(cutoff)).toList();
    RoutineRecommendation? fallback;
    if (ref.read(programProvider) == null) {
      fallback = await RoutineRecommender(CyclePlanner(await cat.plan(), ref.read(userSettingsProvider)), sessionRepo)
          .recommendForToday(await cat.routines());
    }
    return _HomeData(sessions, active, sets, fallback);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider);
    return FutureBuilder<_HomeData>(
      future: _load(ref),
      builder: (context, snap) {
        final d = snap.data;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 16, AppTheme.gutter, 32),
            children: [
              _header(context, ref),
              const SizedBox(height: 28),
              if (d?.active != null) ...[_activeRow(context, d!), const SizedBox(height: 20)],
              if (program != null) ProgramTodayCard(program: program) else const CreateProgramCta(),
              if (program == null && d?.fallback?.routine != null) _fallbackRow(context, ref, d!.fallback!.routine!),
              const SizedBox(height: 36),
              if (d != null) _week(ref, d),
              const SizedBox(height: 28),
              const Divider(),
              _row(context, 'Músculos', 'Volumen y recuperación de la semana', () => context.push('/muscles')),
              const Divider(),
              _aiRow(context, ref),
              const Divider(),
              _row(context, 'Máquinas', 'Las tuyas, con su historial', () => context.push('/settings/machines')),
              const Divider(),
              _row(context, 'Ejercicios', 'Cómo se hace cada uno', () => context.push('/exercises')),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre',
      'octubre', 'noviembre', 'diciembre'];
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Text('${days[now.weekday - 1]}\n${now.day} de ${months[now.month - 1]}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.9, height: 1.15)),
      ),
      IconButton(
        tooltip: 'Escanear máquina',
        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.textMuted),
        onPressed: () => _scanMachine(context, ref),
      ),
    ]);
  }

  Widget _activeRow(BuildContext context, _HomeData d) {
    final s = d.active!;
    final done = d.sets.where((x) => x.sessionId == s.id && !x.isWarmup).length;
    return InkWell(
      onTap: () => context.push('/workout/${s.id}'),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.surfaceHigher),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.signal, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text('Sesión en curso · $done series', style: const TextStyle(fontWeight: FontWeight.w600))),
          const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _fallbackRow(BuildContext context, WidgetRef ref, Routine r) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextButton(
          onPressed: () async {
            final s = await ref.read(sessionRepoProvider).startSession(r.id);
            if (context.mounted) context.push('/workout/${s.id}');
          },
          child: Text('O empieza ya con ${r.nameEs}  →'),
        ),
      );

  /// La semana en una línea: 7 días + 3 cifras. Sin tarjetas.
  Widget _week(WidgetRef ref, _HomeData d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final target = ref.read(trainingProfileProvider).daysPerWeek;
    final trained = d.sessions
        .where((s) => !s.startedAt.isBefore(monday))
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet();
    const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final weekAgo = now.subtract(const Duration(days: 7));
    final week = d.sets.where((s) => s.performedAt.isAfter(weekAgo) && !s.isWarmup).toList();
    final volume = week.fold<double>(0, (a, s) => a + s.weight * s.reps);
    // Récords 30 días
    final best = <String, double>{};
    var prs = 0;
    final monthAgo = now.subtract(const Duration(days: 30));
    final sorted = d.sets.where((s) => !s.isWarmup).toList()..sort((a, b) => a.performedAt.compareTo(b.performedAt));
    for (final s in sorted) {
      final e = PerformanceModel.e1rm(s.weight, s.reps, s.rpe);
      final b = best[s.exerciseId];
      if (b != null && e > b * 1.005 && s.performedAt.isAfter(monthAgo)) prs++;
      if (b == null || e > b) best[s.exerciseId] = e;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Esta semana', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${trained.length} de $target', style: const TextStyle(fontSize: 15, color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (int i = 0; i < 7; i++)
          Builder(builder: (_) {
            final day = monday.add(Duration(days: i));
            final done = trained.contains(day);
            final isToday = day == today;
            return Column(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.primary : Colors.transparent,
                  border: Border.all(color: done ? AppTheme.primary : (isToday ? AppTheme.textMuted : AppTheme.surfaceHigher)),
                ),
                child: Text(letters[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.black : (isToday ? Colors.white : AppTheme.textFaint))),
              ),
            ]);
          }),
      ]),
      const SizedBox(height: 28),
      Row(children: [
        _figure(volume >= 1000 ? (volume / 1000).toStringAsFixed(1) : volume.toStringAsFixed(0),
            volume >= 1000 ? 'toneladas' : 'kg movidos'),
        _figure('${week.length}', 'series'),
        _figure('$prs', prs == 1 ? 'récord' : 'récords', sub: '30 días'),
      ]),
    ]);
  }

  Widget _figure(String value, String label, {String? sub}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTheme.number.copyWith(fontSize: 30, fontWeight: FontWeight.w700)),
          Text(sub == null ? label : '$label · $sub', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ]),
      );

  Widget _row(BuildContext context, String title, String sub, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ]),
            ),
            const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textFaint),
          ]),
        ),
      );

  Widget _aiRow(BuildContext context, WidgetRef ref) {
    final ins = ref.watch(performanceModelProvider).valueOrNull?.insights;
    final n = ins?.observations ?? 0;
    final sub = n == 0 ? 'Aprende de tus series desde la primera sesión' : 'Ha aprendido de $n series';
    return _row(context, 'Tu modelo', sub, () => context.push('/ai'));
  }

  Future<void> _scanMachine(BuildContext context, WidgetRef ref) async {
    final m = await scanAndResolveMachine(context, ref);
    if (m == null || !context.mounted) return;
    final active = await ref.read(sessionRepoProvider).activeSession();
    if (!context.mounted) return;
    if (active != null) {
      context.push('/workout/${active.id}', extra: m.id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MachineHistoryScreen(machine: m)));
    }
  }
}
