import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/shared/widgets/app_scaffold.dart';
import 'package:poker_trainer/features/achievements/presentation/achievements_screen.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
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
              builder: (context, state) {
                // Allow `/trainer?tab=lessons` (or 0/1/2) to preselect a tab.
                final raw = state.uri.queryParameters['tab'];
                final tab = switch (raw) {
                  'setups' || '0' => 0,
                  'history' || '1' => 1,
                  'lessons' || '2' => 2,
                  _ => 0,
                };
                return HandListScreen(initialTab: tab);
              },
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
    // Top-level routes that push above the tab shell.
    GoRoute(
      path: '/achievements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AchievementsScreen(),
    ),
  ],
);

class PokerTrainerApp extends StatelessWidget {
  const PokerTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TableSense',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
