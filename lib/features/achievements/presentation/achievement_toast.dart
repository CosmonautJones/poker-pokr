import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_icons.dart';

/// Host that listens to [achievementUnlocksProvider] and shows an
/// animated toast at the top of the screen whenever a new achievement
/// unlocks.
///
/// Wrap the router/navigator in this widget so the toast stays visible
/// regardless of which screen is active. Multiple simultaneous unlocks
/// are queued and displayed sequentially.
class AchievementToastHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementToastHost({super.key, required this.child});

  @override
  ConsumerState<AchievementToastHost> createState() =>
      _AchievementToastHostState();
}

class _AchievementToastHostState extends ConsumerState<AchievementToastHost> {
  static const _displayDuration = Duration(milliseconds: 2600);

  StreamSubscription<Achievement>? _sub;
  final Queue<Achievement> _queue = Queue<Achievement>();
  Achievement? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // listenManual runs once; no rebuild overhead.
    _sub = ref
        .read(achievementUnlocksProvider)
        .listen(_handleUnlock);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleUnlock(Achievement a) {
    // Fire a celebration haptic for every unlock, even if one is already
    // showing — feels more responsive and the UI still queues properly.
    // Using listenManual-style read so we don't trigger rebuilds.
    ref.read(hapticServiceProvider).success();
    if (_current == null) {
      _showNext(a);
    } else {
      _queue.add(a);
    }
  }

  void _showNext(Achievement a) {
    setState(() => _current = a);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_displayDuration, _dismiss);
  }

  void _dismiss() {
    if (_queue.isNotEmpty) {
      _showNext(_queue.removeFirst());
    } else {
      setState(() => _current = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: _AchievementToastCard(
                  key: ValueKey(_current!.id),
                  achievement: _current!,
                  onTap: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AchievementToastCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AchievementToastCard({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final rarityColor = _rarityColor(pt, achievement.rarity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  pt.surfaceDim,
                  rarityColor.withValues(alpha: 0.18),
                  pt.surfaceDim,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 4),
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
                        rarityColor.withValues(alpha: 0.55),
                        rarityColor.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: rarityColor,
                      width: 1.2,
                    ),
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
                          Text(
                            'Achievement Unlocked',
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RarityBadge(rarity: achievement.rarity),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          color: pt.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  Color _rarityColor(PokerTheme pt, AchievementRarity r) {
    switch (r) {
      case AchievementRarity.common:
        return pt.profit;
      case AchievementRarity.rare:
        return pt.seatActiveBorder;
      case AchievementRarity.epic:
        return pt.straddlePrimary;
      case AchievementRarity.legendary:
        return pt.goldPrimary;
    }
  }
}

class _RarityBadge extends StatelessWidget {
  final AchievementRarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
