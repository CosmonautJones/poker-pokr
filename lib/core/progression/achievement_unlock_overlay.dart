import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/haptic_service.dart';
import '../theme/poker_theme.dart';
import 'achievement.dart';
import 'achievement_visuals.dart';
import 'progression_provider.dart';

/// Full-width floating toast that slides in from the top of the screen when
/// a new achievement is unlocked. Mounted inside [AppScaffold] so it floats
/// above every tab and over scrollable content.
///
/// Design notes:
///  - Uses [ref.listen] on [pendingAchievementUnlocksProvider] rather than
///    [ref.watch] so rebuilds triggered by sibling widgets don't re-fire
///    haptics or reset the dismiss timer.
///  - Dismiss is a single atomic step: it pops the head off the queue and
///    clears the currently-showing id at the same time, so the
///    [AnimatedSwitcher] can animate the transition directly into the next
///    queued unlock without a visual gap.
class AchievementUnlockOverlay extends ConsumerStatefulWidget {
  const AchievementUnlockOverlay({super.key});

  @override
  ConsumerState<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState
    extends ConsumerState<AchievementUnlockOverlay> {
  static const _displayDuration = Duration(milliseconds: 2800);

  String? _showingId;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // Surface anything already queued at mount time (e.g. unlocked during an
    // async init flow that ran before this widget was inserted).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowNext(ref.read(pendingAchievementUnlocksProvider));
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _maybeShowNext(List<String> queue) {
    if (_showingId != null) return; // already presenting one
    if (queue.isEmpty) return;
    final head = queue.first;
    setState(() => _showingId = head);
    // ignore: unawaited_futures
    ref.read(hapticServiceProvider).success();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_displayDuration, _dismissCurrent);
  }

  void _dismissCurrent() {
    if (!mounted) return;
    setState(() => _showingId = null);
    ref.read(pendingAchievementUnlocksProvider.notifier).popNext();
    // After popping, the listener will fire for the new state; but we also
    // try once more immediately to keep back-to-back unlocks snappy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowNext(ref.read(pendingAchievementUnlocksProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<String>>(pendingAchievementUnlocksProvider, (_, next) {
      _maybeShowNext(next);
    });

    final showingId = _showingId;
    final achievement =
        showingId == null ? null : AchievementCatalog.byId(showingId);

    return IgnorePointer(
      ignoring: achievement == null,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.35),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: achievement == null
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : _UnlockToast(
                    key: ValueKey(achievement.id),
                    achievement: achievement,
                    onTap: _dismissCurrent,
                  ),
          ),
        ),
      ),
    );
  }
}

class _UnlockToast extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _UnlockToast({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final tierColor = achievement.tier.displayColor(pt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pt.surfaceOverlay,
                tierColor.withValues(alpha: 0.22),
                pt.surfaceDim,
              ],
              stops: const [0, 0.55, 1],
            ),
            border: Border.all(
              color: tierColor.withValues(alpha: 0.8),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tierColor.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: tierColor,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(achievement.icon, size: 24, color: tierColor),
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
                    Text(
                      'Achievement unlocked',
                      style: textTheme.labelSmall?.copyWith(
                        color: tierColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      achievement.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: pt.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.emoji_events_rounded,
                size: 22,
                color: tierColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
