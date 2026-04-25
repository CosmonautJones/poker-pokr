import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement_icons.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Wraps the app body and listens to [pendingAchievementsProvider] to surface
/// unlock notifications as a top-banner toast that auto-dismisses or can be
/// tapped to advance to the next pending unlock.
class AchievementToastListener extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementToastListener({super.key, required this.child});

  @override
  ConsumerState<AchievementToastListener> createState() =>
      _AchievementToastListenerState();
}

class _AchievementToastListenerState
    extends ConsumerState<AchievementToastListener> {
  Timer? _autoDismiss;

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss(AchievementId id) {
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(milliseconds: 4200), () {
      // Only dismiss if the same head is still showing — defensive against
      // races where the user already tapped to advance.
      final current = ref.read(pendingAchievementsProvider);
      if (current.isNotEmpty && current.first == id) {
        ref.read(pendingAchievementsProvider.notifier).dismissHead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // React on the head of the queue: when a new unlock surfaces, fire
    // celebration haptics and arm the auto-dismiss timer.
    ref.listen<List<AchievementId>>(pendingAchievementsProvider,
        (prev, next) {
      final wasHead = (prev != null && prev.isNotEmpty) ? prev.first : null;
      final nowHead = next.isNotEmpty ? next.first : null;
      if (nowHead != null && nowHead != wasHead) {
        ref.read(hapticServiceProvider).success();
        _scheduleAutoDismiss(nowHead);
      } else if (nowHead == null) {
        _autoDismiss?.cancel();
      }
    });

    final pending = ref.watch(pendingAchievementsProvider);
    final head = pending.isNotEmpty ? pending.first : null;

    return Stack(
      children: [
        widget.child,
        if (head != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _AchievementToast(
                  key: ValueKey(head),
                  achievement: Achievement.byId(head),
                  onTap: () =>
                      ref.read(pendingAchievementsProvider.notifier).dismissHead(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AchievementToast extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AchievementToast({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.92),
                pt.feltCenter.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: pt.goldPrimary.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: pt.goldPrimary.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pt.goldPrimary, pt.goldDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  achievementIcon(achievement.iconCodePoint),
                  color: Colors.white,
                  size: 24,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: 1.08,
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 12, color: pt.goldPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Trophy unlocked',
                          style: TextStyle(
                            color: pt.goldPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      achievement.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pt.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: pt.textMuted, size: 20),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 220.ms).slideY(
            begin: -0.4,
            end: 0,
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
