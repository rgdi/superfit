// Main entry point + theme + routing
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
import 'features/gym/gym_machines_screen.dart';
import 'features/gym/training_profile_screen.dart';
import 'features/gym/program_screen.dart';
import 'features/settings/how_it_works_screen.dart';
import 'features/ai/ai_screen.dart';
import 'features/muscles/muscle_map_screen.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter (tipografía)'], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield const LicenseEntryWithLineBreaks(['react-body-highlighter (siluetas anatómicas)'], _rbhLicense);
    yield const LicenseEntryWithLineBreaks(['Free Exercise DB (fotos de ejercicios)'],
        'Unlicense — dominio público. https://github.com/yuhonas/free-exercise-db');
  });
  runApp(const ProviderScope(child: SuperFitApp()));
}

class SuperFitApp extends ConsumerWidget {
  final String initialLocation;
  const SuperFitApp({super.key, this.initialLocation = '/'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingDoneProvider);
    final router = GoRouter(
      initialLocation: initialLocation,
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
            initialMachineId: state.extra is String ? state.extra as String : null,
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
        GoRoute(path: '/settings/machines', builder: (_, __) => const GymMachinesScreen()),
        GoRoute(path: '/settings/profile', builder: (_, __) => const TrainingProfileScreen()),
        GoRoute(path: '/settings/how', builder: (_, __) => const HowItWorksScreen()),
        GoRoute(path: '/program', builder: (_, __) => const ProgramScreen()),
        GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
        GoRoute(
          path: '/muscles',
          builder: (_, state) => MuscleMapScreen(initialTab: state.uri.queryParameters['tab'] == 'machines' ? 1 : 0),
        ),
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

const String _rbhLicense = r'''MIT License

Copyright (c) 2020 GV79

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';
