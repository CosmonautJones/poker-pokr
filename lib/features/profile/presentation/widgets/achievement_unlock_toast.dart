import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

import '../achievement_icons.dart';

/// Shows a queue of achievement unlock toasts at the top of the current
/// scaffold via [ScaffoldMessenger]. Each id stays on screen for 2.6s with
/// a shimmer sweep, then dismisses automatically.
///
/// No-op if [ids] is empty or if [context] has no ScaffoldMessenger above it.
void showUnlockToasts(BuildContext context, List<String> ids) {
  if (ids.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  for (final id in ids) {
    final achievement = findAchievementById(id);
    if (achievement == null) continue;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2600),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: _UnlockToastContent(achievement: achievement),
      ),
    );
  }
}

class _UnlockToastContent extends StatelessWidget {
  final Achievement achievement;

  const _UnlockToastContent({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.surfaceDim,
              pt.goldDark.withValues(alpha: 0.35),
              pt.surfaceDim,
            ],
          ),
          border: Border.all(
            color: pt.goldPrimary.withValues(alpha: 0.6),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: pt.goldPrimary.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pt.goldLight, pt.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                achievementIcon(achievement.iconKey),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Unlocked',
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 250.ms)
          .slideY(begin: -0.3, duration: 280.ms, curve: Curves.easeOutCubic)
          .shimmer(
            delay: 150.ms,
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.18),
          ),
    );
  }
}
