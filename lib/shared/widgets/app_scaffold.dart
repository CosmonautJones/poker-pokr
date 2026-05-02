import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_icons.dart';

/// Root tab scaffold. Hosts the global achievement-unlock listener so any
/// stat / lesson change anywhere in the app fires exactly one celebration.
class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Prime the seen-set synchronously so the post-build listener never
    // retro-celebrates achievements that were already unlocked before this
    // version (or before the listener wired up). Only seeds when seen has
    // never been written so legitimate unlocks since last launch still fire.
    final unlocked = ref.read(unlockedAchievementsProvider);
    final seen = ref.read(achievementsSeenProvider);
    if (seen.isEmpty && unlocked.isNotEmpty) {
      ref.read(achievementsSeenProvider.notifier).markSeen(unlocked);
    }
  }

  void _celebrate(Achievement ach) {
    final pt = PokerTheme.of(context);
    ref.read(hapticServiceProvider).success();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: pt.goldPrimary.withValues(alpha: 0.5),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [pt.goldPrimary, pt.goldDark],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                achievementIcon(ach.iconCodePoint),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement unlocked',
                    style: TextStyle(
                      color: pt.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ach.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: pt.goldLight,
          onPressed: () {
            // Use the root navigator so this works from any tab.
            GoRouter.of(context).push('/achievements');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Set<String>>(unlockedAchievementsProvider, (prev, next) {
      final seen = ref.read(achievementsSeenProvider);
      final fresh = next.difference(seen);
      if (fresh.isEmpty) return;

      // Surface a single celebration per event - the first match in catalog
      // order. Any other simultaneous unlocks still show up in the catalog
      // screen, just without back-to-back toasts.
      Achievement? first;
      for (final a in kAchievements) {
        if (fresh.contains(a.id)) {
          first = a;
          break;
        }
      }
      if (first != null) _celebrate(first);
      ref.read(achievementsSeenProvider.notifier).markSeen(fresh);
    });

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.book), label: 'Bookkeeper'),
            NavigationDestination(icon: Icon(Icons.school), label: 'Trainer'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
