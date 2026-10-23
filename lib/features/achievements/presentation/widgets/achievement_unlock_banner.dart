import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Inserts a top-of-screen badge unlock toast into the nearest [Overlay].
/// Auto-dismisses after [visibleDuration] (with built-in fade-out built into
/// the animation chain).
void showAchievementUnlockBanner(
  BuildContext context,
  Achievement achievement, {
  Duration visibleDuration = const Duration(milliseconds: 2400),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) => _UnlockBanner(achievement: achievement),
  );
  overlay.insert(entry);
  Timer(visibleDuration, () {
    if (entry.mounted) entry.remove();
  });
}

class _UnlockBanner extends StatelessWidget {
  final Achievement achievement;

  const _UnlockBanner({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pt.goldDark,
                    pt.goldPrimary,
                    pt.goldLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      achievement.icon,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Badge Unlocked',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          achievement.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: -1.2, end: 0, duration: 320.ms, curve: Curves.easeOut)
        .fadeIn(duration: 220.ms)
        .then(delay: 1500.ms)
        .fadeOut(duration: 380.ms)
        .slideY(end: -0.4, duration: 380.ms);
  }
}
