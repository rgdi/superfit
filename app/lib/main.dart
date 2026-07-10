// Main entry point + theme + routing
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/workout/workout_screen.dart';
import 'features/routines/routines_screen.dart';
import 'features/routines/routine_detail_screen.dart';
import 'features/exercises/exercises_screen.dart';
import 'features/exercises/exercise_detail_screen.dart';
import 'features/history/history_screen.dart';
import 'features/history/session_detail_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/progress_photos/photos_screen.dart';
import 'features/progress_photos/photo_compare_screen.dart';
import 'features/settings/settings_screen.dart';

import 'features/insights/insights_screen.dart';
import 'features/backup/backup_screen.dart';

void main() {
  runApp(const ProviderScope(child: SuperFitApp()));
}

class SuperFitApp extends ConsumerWidget {
  const SuperFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingDoneProvider);
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (onboardingAsync.isLoading) return null;
        final done = onboardingAsync.valueOrNull ?? false;
        final loc = state.matchedLocation;
        if (!done && loc != '/onboarding') return '/onboarding';
        if (done && loc == '/onboarding') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/workout/:sessionId',
          builder: (_, state) => WorkoutScreen(
            sessionId: state.pathParameters['sessionId']!,
          ),
        ),
        GoRoute(path: '/routines', builder: (_, __) => const RoutinesScreen()),
        GoRoute(
          path: '/routines/:id',
          builder: (_, state) => RoutineDetailScreen(
            routineId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(path: '/exercises', builder: (_, __) => const ExercisesScreen()),
        GoRoute(
          path: '/exercises/:id',
          builder: (_, state) => ExerciseDetailScreen(
            exerciseId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(
          path: '/history/:id',
          builder: (_, state) => SessionDetailScreen(
            sessionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
        GoRoute(path: '/progress/photos', builder: (_, __) => const PhotosScreen()),
        GoRoute(
          path: '/progress/compare',
          builder: (_, state) {
            final extra = state.extra as Map<String, String>?;
            return PhotoCompareScreen(
              photoId1: extra?['id1'] ?? '',
              photoId2: extra?['id2'] ?? '',
            );
          },
        ),
        GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/settings/backup', builder: (_, __) => const BackupScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'SuperFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
