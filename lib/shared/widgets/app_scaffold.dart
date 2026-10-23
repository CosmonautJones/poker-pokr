import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/features/achievements/presentation/widgets/achievement_unlock_banner.dart';

/// Root shell that hosts the bottom-nav branches and globally listens for
/// achievement unlocks so banners surface regardless of which tab is active.
class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  @override
  void initState() {
    super.initState();
    // Ensure the achievements notifier is initialized at app start so it
    // catches unlocks even if the user never opens the gallery.
    ref.read(achievementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Drain whenever the achievements set changes. By listening to the
    // achievements provider rather than user stats, we get a strict
    // happens-after on the unlock evaluation — by the time this fires,
    // [drainPendingUnlocks] is guaranteed to return the new ids.
    ref.listen<Set<AchievementId>>(achievementsProvider, (prev, next) {
      if (prev != null && next.length > prev.length) {
        _drainAndShow();
      }
    });

    return Scaffold(
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
    );
  }

  /// Pulls newly-unlocked badges from the notifier and pops them as toasts
  /// one at a time. Spaced apart so multi-unlocks don't pile on the screen.
  Future<void> _drainAndShow() async {
    // Defer to after the current frame so the listener that triggered us
    // doesn't recurse into widget builds.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final pending = ref.read(achievementsProvider.notifier).drainPendingUnlocks();
    if (pending.isEmpty) return;
    final haptic = ref.read(hapticServiceProvider);
    for (final id in pending) {
      if (!mounted) return;
      final def = AchievementsAlgorithm.definition(id);
      if (def == null) continue;
      haptic.success();
      showAchievementUnlockBanner(context, def);
      // Stagger so multiple banners don't overlap.
      await Future<void>.delayed(const Duration(milliseconds: 2700));
    }
  }
}
