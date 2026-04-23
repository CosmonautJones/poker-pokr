import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/shared/widgets/app_scaffold.dart';
import 'package:poker_trainer/features/home/presentation/home_screen.dart';
import 'package:poker_trainer/features/bookkeeper/presentation/screens/session_list_screen.dart';
import 'package:poker_trainer/features/bookkeeper/presentation/screens/add_session_screen.dart';
import 'package:poker_trainer/features/bookkeeper/presentation/screens/reports_screen.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/hand_list_screen.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/create_hand_screen.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/hand_replay_screen.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_detail_screen.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_play_screen.dart';
import 'package:poker_trainer/features/settings/presentation/settings_screen.dart';
import 'package:poker_trainer/features/settings/domain/personalization.dart';
import 'package:poker_trainer/features/settings/providers/personalization_provider.dart';
import 'package:poker_trainer/features/onboarding/presentation/onboarding_screen.dart';
import 'package:poker_trainer/features/achievements/presentation/achievements_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final seen = ref.read(userStatsServiceProvider).loadOnboardingSeen();
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!seen && !goingToOnboarding) return '/onboarding';
      if (seen && goingToOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookkeeper',
                builder: (context, state) => const SessionListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddSessionScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:sessionId',
                    builder: (context, state) => AddSessionScreen(
                      sessionId: int.tryParse(
                          state.pathParameters['sessionId'] ?? ''),
                    ),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer',
                builder: (context, state) => const HandListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateHandScreen(),
                  ),
                  GoRoute(
                    path: 'replay/:handId',
                    builder: (context, state) => HandReplayScreen(
                      handId: int.tryParse(
                              state.pathParameters['handId'] ?? '') ??
                          0,
                    ),
                  ),
                  GoRoute(
                    path: 'lesson/:lessonId',
                    builder: (context, state) => LessonDetailScreen(
                      lessonId: state.pathParameters['lessonId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'play/:scenarioIndex',
                        builder: (context, state) => LessonPlayScreen(
                          lessonId: state.pathParameters['lessonId'] ?? '',
                          scenarioIndex: int.tryParse(
                                  state.pathParameters['scenarioIndex'] ??
                                      '') ??
                              0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

class PokerTrainerApp extends ConsumerWidget {
  const PokerTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(personalizationProvider);
    final felt = PersonalizationSettings.feltOverrides(p.felt);
    final back = PersonalizationSettings.cardBackOverrides(p.cardBack);
    final customPoker = PokerTheme.dark.copyWith(
      feltCenter: felt.feltCenter,
      feltEdge: felt.feltEdge,
      feltHighlight: felt.feltHighlight,
      cardBackPrimary: back.cardBackPrimary,
      cardBackSecondary: back.cardBackSecondary,
    );
    final theme = appTheme.copyWith(extensions: [customPoker]);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TableSense',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

