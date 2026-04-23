import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

class AchievementToastOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementToastOverlay({super.key, required this.child});

  @override
  ConsumerState<AchievementToastOverlay> createState() =>
      _AchievementToastOverlayState();
}

class _AchievementToastOverlayState
    extends ConsumerState<AchievementToastOverlay> {
  Achievement? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending =
          ref.read(recentlyUnlockedAchievementsProvider);
      if (pending.isNotEmpty) _maybeConsume();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _maybeConsume() {
    if (_current != null) return;
    final next = ref
        .read(recentlyUnlockedAchievementsProvider.notifier)
        .consumeFirst();
    if (next == null) return;
    ref.read(hapticServiceProvider).success();
    setState(() => _current = next);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() => _current = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeConsume();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Achievement>>(recentlyUnlockedAchievementsProvider,
        (_, next) {
      if (next.isNotEmpty && _current == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeConsume();
        });
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: _AchievementCard(achievement: _current!)
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: -0.4, end: 0, duration: 280.ms)
                .shimmer(
                  duration: 1400.ms,
                  delay: 300.ms,
                  color: const Color(0x66FFD86B),
                ),
          ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  Color _rarityColor(PokerTheme pt) {
    switch (achievement.rarity) {
      case AchievementRarity.common:
        return pt.goldLight;
      case AchievementRarity.rare:
        return pt.turnIndicatorGlow;
      case AchievementRarity.epic:
        return pt.straddlePrimary;
      case AchievementRarity.legendary:
        return pt.goldPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final rarity = _rarityColor(pt);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              pt.surfaceDim,
              pt.surfaceDim.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(color: pt.goldPrimary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: pt.goldPrimary.withValues(alpha: 0.35),
              blurRadius: 18,
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
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    rarity.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: rarity, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                IconData(achievement.iconCodePoint,
                    fontFamily: 'MaterialIcons'),
                size: 22,
                color: pt.goldPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement unlocked!',
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
