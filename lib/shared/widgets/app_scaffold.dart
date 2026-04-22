import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievement_unlock_overlay.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          // Floating unlock toast. Sits above tab content and ignores pointer
          // events except on the toast itself so it never blocks the UI.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AchievementUnlockOverlay(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
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
}
