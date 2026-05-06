import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Mounts above the navigation shell. Listens to [lastDispatchResultProvider]
/// and shows a banner-style celebration whenever an achievement unlock or
/// daily-challenge completion fires. Self-clears after the banner exits.
class AchievementUnlockListener extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementUnlockListener({super.key, required this.child});

  @override
  ConsumerState<AchievementUnlockListener> createState() =>
      _AchievementUnlockListenerState();
}

class _AchievementUnlockListenerState
    extends ConsumerState<AchievementUnlockListener> {
  final List<_BannerSpec> _queue = [];
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AchievementDispatchResult>(
      lastDispatchResultProvider,
      (prev, next) {
        if (!next.hasAny) return;
        for (final ach in next.newlyUnlocked) {
          _queue.add(_BannerSpec.achievement(ach));
        }
        if (next.dailyJustCompleted) {
          _queue.add(_BannerSpec.daily());
        }
        // One-shot: clear the trigger so a rebuild doesn't re-enqueue.
        ref.read(lastDispatchResultProvider.notifier).clear();
        _drainQueue();
      },
    );

    return Stack(
      children: [
        widget.child,
        if (_currentSpec != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: _UnlockBanner(
                key: ValueKey(_currentSpec!.key),
                spec: _currentSpec!,
                onDismissed: _onBannerDismissed,
              ),
            ),
          ),
      ],
    );
  }

  _BannerSpec? _currentSpec;

  void _drainQueue() {
    if (_showing) return;
    if (_queue.isEmpty) return;
    final next = _queue.removeAt(0);
    setState(() {
      _showing = true;
      _currentSpec = next;
    });
    // Strong haptic for unlock; lighter for daily completion.
    final hs = ref.read(hapticServiceProvider);
    if (next.kind == _BannerKind.achievement) {
      hs.success();
    } else {
      hs.medium();
    }
  }

  void _onBannerDismissed() {
    setState(() {
      _showing = false;
      _currentSpec = null;
    });
    if (_queue.isNotEmpty) {
      // Slight delay so banners don't blur into one another.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _drainQueue();
      });
    }
  }
}

enum _BannerKind { achievement, daily }

class _BannerSpec {
  final _BannerKind kind;
  final Achievement? achievement;
  final String key;

  _BannerSpec.achievement(Achievement a)
      : kind = _BannerKind.achievement,
        achievement = a,
        key = 'ach-${a.id}-${DateTime.now().microsecondsSinceEpoch}';

  _BannerSpec.daily()
      : kind = _BannerKind.daily,
        achievement = null,
        key = 'daily-${DateTime.now().microsecondsSinceEpoch}';
}

class _UnlockBanner extends StatelessWidget {
  final _BannerSpec spec;
  final VoidCallback onDismissed;

  const _UnlockBanner({
    super.key,
    required this.spec,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final isAch = spec.kind == _BannerKind.achievement;
    final ach = spec.achievement;
    final tierColor = isAch
        ? _tierColor(ach!.tier, pt)
        : pt.profit;
    final title = isAch ? 'Achievement Unlocked' : 'Daily Challenge Complete';
    final subtitle = isAch ? ach!.title : 'Tap to claim your reward';
    final icon = isAch ? ach!.icon : Icons.redeem_rounded;
    final xp = isAch ? ach!.xpReward : 0;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tierColor.withValues(alpha: 0.32),
              pt.surfaceDim.withValues(alpha: 0.95),
            ],
          ),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  tierColor.withValues(alpha: 0.7),
                  tierColor.withValues(alpha: 0.05),
                ]),
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.8),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (xp > 0) ...[
              const SizedBox(width: 8),
              _XpPill(xp: xp),
            ],
          ],
        ),
      )
          .animate(onComplete: (_) => onDismissed())
          .slideY(
            begin: -0.6,
            end: 0,
            duration: 320.ms,
            curve: Curves.easeOut,
          )
          .fadeIn(duration: 220.ms)
          .then(delay: 1800.ms)
          .slideY(
            begin: 0,
            end: -0.6,
            duration: 280.ms,
            curve: Curves.easeIn,
          )
          .fadeOut(duration: 240.ms),
    );
  }

  static Color _tierColor(AchievementTier tier, PokerTheme pt) {
    return switch (tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silver => const Color(0xFFB0B7BD),
      AchievementTier.gold => pt.goldPrimary,
      AchievementTier.platinum => const Color(0xFF7DD3FC),
    };
  }
}

class _XpPill extends StatelessWidget {
  final int xp;
  const _XpPill({required this.xp});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [pt.goldDark, pt.goldPrimary]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            '+$xp',
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
