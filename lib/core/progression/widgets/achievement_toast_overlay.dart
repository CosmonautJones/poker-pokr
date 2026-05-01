import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/haptic_service.dart';
import '../../theme/poker_theme.dart';
import '../achievement.dart';
import '../progression_provider.dart';

/// Top-of-screen banner that announces newly-unlocked achievements.
///
/// Watches [pendingAchievementToastsProvider] and shows the head item with a
/// slide-down + fade animation, auto-dismisses after [_visibleDuration], and
/// plays a celebratory haptic on appear. Designed to live in the root scaffold
/// stack so it overlays any tab.
class AchievementToastOverlay extends ConsumerStatefulWidget {
  const AchievementToastOverlay({super.key});

  @override
  ConsumerState<AchievementToastOverlay> createState() =>
      _AchievementToastOverlayState();
}

class _AchievementToastOverlayState
    extends ConsumerState<AchievementToastOverlay> {
  /// On-screen window aligned with the animate chain
  /// (slide-in 320ms + dwell 2480ms + slide-out 260ms ≈ 3060ms)
  /// so the overlay clears the queue exactly when the banner finishes
  /// animating out, with no perceptible "ghost gap".
  static const _visibleDuration = Duration(milliseconds: 3060);

  String? _shownId;
  Timer? _autoDismiss;

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _onHeadChanged(Achievement? head) {
    if (head == null) {
      _shownId = null;
      _autoDismiss?.cancel();
      _autoDismiss = null;
      return;
    }
    if (_shownId == head.id) return;
    _shownId = head.id;
    ref.read(hapticServiceProvider).success();
    _autoDismiss?.cancel();
    _autoDismiss = Timer(_visibleDuration, _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    if (!mounted) return;
    ref.read(pendingAchievementToastsProvider.notifier).dismissCurrent();
  }

  @override
  Widget build(BuildContext context) {
    // Drive side-effects from queue mutations rather than from build itself,
    // so theme/MediaQuery rebuilds don't re-fire the haptic or reset the timer.
    ref.listen<List<Achievement>>(
      pendingAchievementToastsProvider,
      (prev, next) {
        _onHeadChanged(next.isEmpty ? null : next.first);
      },
    );

    final queue = ref.watch(pendingAchievementToastsProvider);
    if (queue.isEmpty) {
      return const SizedBox.shrink();
    }
    final head = queue.first;
    // First-paint case: ref.listen only fires on changes, not on the
    // initial value, so kick off the side-effect for the first head too.
    if (_shownId != head.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onHeadChanged(head);
      });
    }

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _ToastBanner(
            // Key by id so flutter_animate restarts when a new toast arrives.
            key: ValueKey(head.id),
            achievement: head,
            onTap: _dismiss,
          ),
        ),
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _ToastBanner({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final tier = tierColor(pt, achievement.tier);

    final banner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pt.surfaceDim,
                Color.alphaBlend(
                  pt.goldPrimary.withValues(alpha: 0.18),
                  pt.surfaceDim,
                ),
              ],
            ),
            border: Border.all(
              color: pt.goldPrimary.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: pt.goldPrimary.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tier.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: tier.withValues(alpha: 0.85),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(achievement.icon, size: 22, color: tier),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Achievement unlocked',
                      style: textTheme.labelSmall?.copyWith(
                        color: pt.goldPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      achievement.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: pt.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.workspace_premium_rounded,
                color: pt.goldLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      liveRegion: true,
      label:
          'Achievement unlocked: ${achievement.title}. ${achievement.description}',
      child: banner
          .animate()
          .slideY(
            begin: -0.6,
            end: 0,
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 220.ms)
          .then(delay: 2480.ms)
          .fadeOut(duration: 260.ms)
          .slideY(
            begin: 0,
            end: -0.4,
            duration: 260.ms,
            curve: Curves.easeInCubic,
          ),
    );
  }
}
