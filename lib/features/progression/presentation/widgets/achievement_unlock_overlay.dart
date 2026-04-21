import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Root-level overlay that listens to [pendingAchievementsProvider] and
/// pops a celebratory toast for each unlock. Toasts auto-dismiss after
/// ~2.6s; tapping dismisses early. Dismissal marks the achievement as seen.
///
/// Wrap once near the top of the widget tree (e.g. MaterialApp.builder).
class AchievementUnlockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementUnlockOverlay({super.key, required this.child});

  @override
  ConsumerState<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState
    extends ConsumerState<AchievementUnlockOverlay> {
  Achievement? _current;
  bool _hiding = false;

  @override
  void initState() {
    super.initState();
    // Delay to next frame so the provider is safe to read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pumpIfIdle());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Achievement>>(pendingAchievementsProvider, (prev, next) {
      if (!mounted) return;
      if (_current == null && next.isNotEmpty) {
        _show(next.first);
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.of(context).padding.top + 12,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: _dismiss,
                child: _UnlockCard(
                  key: ValueKey(_current!.id),
                  achievement: _current!,
                  hiding: _hiding,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _pumpIfIdle() {
    if (!mounted || _current != null) return;
    final queue = ref.read(pendingAchievementsProvider);
    if (queue.isNotEmpty) _show(queue.first);
  }

  void _show(Achievement a) {
    setState(() {
      _current = a;
      _hiding = false;
    });
    // Haptic celebration.
    ref.read(hapticServiceProvider).success();

    // Auto-dismiss after display window.
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted || _current?.id != a.id || _hiding) return;
      _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (_current == null || _hiding) return;
    final dismissedId = _current!.id;
    setState(() => _hiding = true);
    // Let the exit animation play before we drop the widget.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await ref
        .read(userStatsProvider.notifier)
        .markAchievementsSeen([dismissedId]);
    if (!mounted) return;
    setState(() {
      _current = null;
      _hiding = false;
    });
    // If another unlock is queued, chain into it.
    final remaining = ref.read(pendingAchievementsProvider);
    if (remaining.isNotEmpty) {
      // Tiny gap so the user sees the separation between toasts.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      _show(remaining.first);
    }
  }
}

class _UnlockCard extends StatelessWidget {
  final Achievement achievement;
  final bool hiding;

  const _UnlockCard({
    super.key,
    required this.achievement,
    required this.hiding,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final color = _rarityColor(pt, achievement.rarity);

    final card = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.surfaceDim.withValues(alpha: 0.96),
              color.withValues(alpha: 0.18),
              pt.surfaceDim.withValues(alpha: 0.96),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.7),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 2,
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
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.85),
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(achievement.icon, size: 22, color: color),
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
                      color: color,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                achievement.rarity.label.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (hiding) {
      return card
          .animate()
          .fadeOut(duration: 220.ms, curve: Curves.easeOut)
          .slideY(begin: 0, end: -0.2, duration: 220.ms, curve: Curves.easeOut);
    }
    return card
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(
          begin: -0.3,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        )
        .shimmer(
          duration: 1400.ms,
          delay: 300.ms,
          color: color.withValues(alpha: 0.25),
        );
  }
}

Color _rarityColor(PokerTheme pt, AchievementRarity rarity) {
  return switch (rarity) {
    AchievementRarity.common => pt.seatActiveBorder,
    AchievementRarity.rare => pt.accent,
    AchievementRarity.epic => pt.straddlePrimary,
    AchievementRarity.legendary => pt.goldPrimary,
  };
}
