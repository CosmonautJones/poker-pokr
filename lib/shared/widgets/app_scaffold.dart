import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/progression/widgets/achievement_toast_overlay.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          // Achievement toast lives above the active tab so it is visible
          // regardless of which shell branch is currently selected.
          const AchievementToastOverlay(),
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
