import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Mounts inside the app shell and listens to
/// [pendingAchievementUnlocksProvider]. When entries appear it pops them
/// one-at-a-time, animates a top-aligned banner in/out, and emits a
/// celebratory haptic on each unlock.
///
/// Designed as an overlay layer so any screen — replay, lessons, settings —
/// reveals achievements without each screen needing its own listener.
class AchievementUnlockHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementUnlockHost({super.key, required this.child});

  @override
  ConsumerState<AchievementUnlockHost> createState() =>
      _AchievementUnlockHostState();
}

class _AchievementUnlockHostState
    extends ConsumerState<AchievementUnlockHost> {
  Achievement? _current;
  Timer? _dismissTimer;

  static const _displayDuration = Duration(milliseconds: 3200);

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Achievement>>(
      pendingAchievementUnlocksProvider,
      (_, next) {
        if (_current != null || next.isEmpty) return;
        // Defer: callback fires during a build pass, and `_showNext`
        // calls `setState` + mutates the queue provider. Posting to the
        // next frame keeps build-time side effects out of the build
        // pipeline and avoids a re-entrant listener fire mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_current != null) return;
          _showNext();
        });
      },
    );

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: _UnlockToast(
                key: ValueKey(_current!.id),
                achievement: _current!,
                onDismiss: _dismissNow,
              ),
            ),
          ),
      ],
    );
  }

  void _showNext() {
    final next = ref
        .read(pendingAchievementUnlocksProvider.notifier)
        .consume();
    if (next == null) return;
    setState(() => _current = next);
    ref.read(hapticServiceProvider).success();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_displayDuration, _dismissNow);
  }

  void _dismissNow() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_current == null) return;
    setState(() => _current = null);
    // Allow the slide-out to finish, then chain to the next queued unlock.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final hasMore =
          ref.read(pendingAchievementUnlocksProvider).isNotEmpty;
      if (hasMore) _showNext();
    });
  }
}

/// Animated banner shown for a single achievement unlock.
class _UnlockToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const _UnlockToast({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_UnlockToast> createState() => _UnlockToastState();
}

class _UnlockToastState extends State<_UnlockToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onDismiss,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF111111).withValues(alpha: 0.96),
                    const Color(0xFF222222).withValues(alpha: 0.96),
                  ],
                ),
                border: Border.all(
                  color: pt.goldPrimary.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [pt.goldLight, pt.goldPrimary, pt.goldDark],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pt.goldPrimary.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.achievement.icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACHIEVEMENT UNLOCKED',
                          style: textTheme.labelSmall?.copyWith(
                            color: pt.goldPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievement.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.achievement.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: pt.textMuted,
                            height: 1.3,
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
          ),
        ),
      ),
    );
  }
}
