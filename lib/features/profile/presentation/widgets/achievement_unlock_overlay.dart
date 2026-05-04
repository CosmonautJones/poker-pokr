import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Listens to [newlyUnlockedProvider] and shows a queued toast for each
/// achievement that just unlocked. Drains the queue one entry at a time so
/// multiple unlocks (e.g. crossing two thresholds in one hand) don't pile
/// up on screen.
///
/// Mounted once at the AppScaffold root so toasts survive route changes.
class AchievementUnlockHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementUnlockHost({super.key, required this.child});

  @override
  ConsumerState<AchievementUnlockHost> createState() =>
      _AchievementUnlockHostState();
}

class _AchievementUnlockHostState extends ConsumerState<AchievementUnlockHost> {
  AchievementId? _showing;
  Timer? _drainTimer;

  @override
  void initState() {
    super.initState();
    // If unlocks queued before mount (e.g. hot reload, late host attach),
    // start draining on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final queue = ref.read(newlyUnlockedProvider);
      if (queue.isNotEmpty && _showing == null) _drain();
    });
  }

  @override
  void dispose() {
    _drainTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<AchievementId>>(newlyUnlockedProvider, (prev, next) {
      if (next.isEmpty) return;
      if (_showing == null) _drain();
    });

    return Stack(
      children: [
        widget.child,
        if (_showing != null)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 12,
            child: Center(
              child: _AchievementToast(
                achievement: _byId(_showing!),
                key: ValueKey(_showing!.name),
                onTap: () => context.push('/profile'),
              ),
            ),
          ),
      ],
    );
  }

  void _drain() {
    final queue = ref.read(newlyUnlockedProvider);
    if (queue.isEmpty) {
      setState(() => _showing = null);
      return;
    }
    final next = queue.first;
    ref.read(newlyUnlockedProvider.notifier).state = queue.sublist(1);
    setState(() => _showing = next);
    ref.read(hapticServiceProvider).success();
    _drainTimer?.cancel();
    _drainTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _drain();
    });
  }

  Achievement _byId(AchievementId id) =>
      achievementsCatalog.firstWhere((a) => a.id == id);
}

class _AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const _AchievementToast({
    required this.achievement,
    this.onTap,
    super.key,
  });

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _confettiProgress;
  late final Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..forward();
    _confettiProgress =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOutBack),
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = reduceMotion ? 1.0 : _slideIn.value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * -24),
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (!reduceMotion)
                  SizedBox(
                    width: 320,
                    height: 120,
                    child: CustomPaint(
                      painter: _UnlockConfettiPainter(
                        progress: _confettiProgress.value,
                        palette: [
                          pt.goldPrimary,
                          pt.goldLight,
                          pt.accent,
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                _AchievementCard(
                  achievement: widget.achievement,
                  onTap: widget.onTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  const _AchievementCard({required this.achievement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _buildBody(pt),
      ),
    );
  }

  Widget _buildBody(PokerTheme pt) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: pt.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
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
                  pt.goldPrimary.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: pt.goldPrimary.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Icon(achievement.icon, color: pt.goldLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ACHIEVEMENT UNLOCKED',
                  style: TextStyle(
                    color: pt.goldPrimary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> palette;
  static const _particleCount = 22;

  _UnlockConfettiPainter({required this.progress, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(31);
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _particleCount; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 60 + rand.nextDouble() * 110;
      final t = progress;
      final dx = math.cos(angle) * speed * t;
      final dy = math.sin(angle) * speed * t + 90 * t * t;
      final pos = center + Offset(dx, dy);
      final color = palette[i % palette.length];
      final fade = (1 - t).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: fade);
      final r = 2.5 + rand.nextDouble() * 2.0;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + t * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _UnlockConfettiPainter old) =>
      old.progress != progress;
}
