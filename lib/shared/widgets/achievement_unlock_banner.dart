import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievement_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/motion.dart';
import 'package:poker_trainer/shared/widgets/confetti_burst.dart';

/// Top-of-screen host that watches [achievementsProvider] and renders the
/// celebration banner whenever new achievements are queued. Place once near
/// the root of the widget tree (e.g. inside MaterialApp.router's `builder:`).
class AchievementToastHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementToastHost({super.key, required this.child});

  @override
  ConsumerState<AchievementToastHost> createState() =>
      _AchievementToastHostState();
}

class _AchievementToastHostState extends ConsumerState<AchievementToastHost> {
  Achievement? _current;

  @override
  Widget build(BuildContext context) {
    // Watch the head id rather than the queue object itself. Queue has no
    // value-equality, so watching the queue would only fire when a new
    // Queue instance is assigned — too brittle as a public contract.
    // The id string compares structurally and is sufficient: the host only
    // cares whether *some* toast is at the front waiting to be promoted.
    final headId = ref.watch(
      achievementsProvider.select(
        (s) => s.pendingToasts.isEmpty ? null : s.pendingToasts.first.id,
      ),
    );
    if (_current == null && headId != null) {
      // Defer state mutation until after the build completes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final next =
            ref.read(achievementsProvider.notifier).consumeNextToast();
        if (next != null) {
          setState(() => _current = next);
        }
      });
    }

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _AchievementBanner(
                  // Key tied to id so the banner state restarts per toast.
                  key: ValueKey(_current!.id),
                  achievement: _current!,
                  onDismissed: () {
                    if (!mounted) return;
                    setState(() => _current = null);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The visible banner card. Slides in from the top, runs a confetti burst
/// behind it, pulses the icon, and dismisses itself after [visibleDuration]
/// (or earlier on tap).
class _AchievementBanner extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismissed;
  final Duration visibleDuration;

  const _AchievementBanner({
    super.key,
    required this.achievement,
    required this.onDismissed,
    this.visibleDuration = const Duration(milliseconds: 3400),
  });

  @override
  State<_AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<_AchievementBanner>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = Motion.shouldAnimate(context);
    if (!_enter.isAnimating && _enter.value == 0) {
      if (animate) {
        _enter.forward();
        _pulse.repeat(reverse: true);
      } else {
        _enter.value = 1.0;
      }
      _scheduleDismiss();
    }
  }

  void _scheduleDismiss() {
    Future<void>.delayed(widget.visibleDuration, () async {
      if (!mounted || _exiting) return;
      await _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (_exiting) return;
    _exiting = true;
    _pulse.stop();
    if (Motion.shouldAnimate(context)) {
      await _enter.reverse();
    } else {
      _enter.value = 0.0;
    }
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final entrance = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: entrance,
      builder: (context, child) {
        final t = entrance.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -32 * (1 - t)),
            child: Transform.scale(
              scale: 0.95 + 0.05 * t,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti behind the card.
            Positioned.fill(
              child: ConfettiBurst(
                colors: [
                  pt.goldPrimary,
                  pt.goldLight,
                  pt.goldDark,
                  Colors.white.withValues(alpha: 0.9),
                ],
              ),
            ),
            _BannerCard(
              achievement: widget.achievement,
              pulse: _pulse,
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Achievement achievement;
  final Animation<double> pulse;

  const _BannerCard({required this.achievement, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pt.goldDark, pt.goldPrimary, pt.goldDark],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: pt.goldPrimary.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final t = pulse.value;
                return Transform.scale(
                  scale: 1.0 + 0.06 * t,
                  child: child,
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      pt.goldLight.withValues(alpha: 0.95),
                      pt.goldPrimary,
                      pt.goldDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: pt.goldPrimary.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  achievement.iconData,
                  color: Colors.black.withValues(alpha: 0.85),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement Unlocked',
                    style: TextStyle(
                      color: pt.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: pt.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
