import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

const _bannerVisibleFor = Duration(milliseconds: 2500);

class AchievementUnlockOverlay extends ConsumerWidget {
  final Widget child;

  const AchievementUnlockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(recentlyUnlockedAchievementsProvider);
    final current = queue.isEmpty ? null : queue.first;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: current == null
                    ? const SizedBox.shrink(key: ValueKey('empty'))
                    : _UnlockBanner(
                        key: ValueKey(current.id),
                        achievement: current,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlockBanner extends ConsumerStatefulWidget {
  final Achievement achievement;

  const _UnlockBanner({super.key, required this.achievement});

  @override
  ConsumerState<_UnlockBanner> createState() => _UnlockBannerState();
}

class _UnlockBannerState extends ConsumerState<_UnlockBanner> {
  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fire haptic only after the widget is mounted so a queued unlock that
      // gets immediately replaced doesn't double-buzz.
      ref.read(hapticServiceProvider).success();
    });
    _dismissTimer = Timer(_bannerVisibleFor, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    ref.read(recentlyUnlockedAchievementsProvider.notifier).popFirst();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final tierColor = tierColorOf(context, widget.achievement.tier);

    final banner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _dismiss,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tierColor.withValues(alpha: 0.95),
                pt.goldDark.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tierColor.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 1,
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
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.achievement.icon,
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
                      'Achievement Unlocked',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.achievement.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );

    return banner
        .animate()
        .slideY(
          begin: -0.35,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 220.ms)
        .scaleXY(
          begin: 0.96,
          end: 1.0,
          duration: 320.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(
          delay: 220.ms,
          duration: 1100.ms,
          color: Colors.white.withValues(alpha: 0.45),
        );
  }
}
