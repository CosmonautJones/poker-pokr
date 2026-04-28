import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Full-screen celebration overlay for showdown wins by the viewer's seat.
///
/// Pure-Flutter confetti via a [CustomPainter] driven by an
/// [AnimationController] (no extra dependencies). Fires a "YOU WIN" banner
/// scaled in then translated up; auto-dismisses via [onDone] after the
/// animation finishes.
class ShowdownCelebration extends StatefulWidget {
  /// Called when the celebration animation finishes — typically used by the
  /// caller to remove its [OverlayEntry].
  final VoidCallback onDone;

  const ShowdownCelebration({super.key, required this.onDone});

  @override
  State<ShowdownCelebration> createState() => _ShowdownCelebrationState();
}

class _ShowdownCelebrationState extends State<ShowdownCelebration>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2200);

  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  late final Animation<double> _bannerScale;
  late final Animation<double> _bannerSlide;
  late final Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();
    final rand = math.Random(7);
    _particles = List.generate(64, (i) => _ConfettiParticle.random(rand, i));

    _controller = AnimationController(duration: _duration, vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..forward();

    _bannerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.08).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_controller);

    _bannerSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _bannerFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                  palette: [
                    pt.goldPrimary,
                    pt.goldLight,
                    pt.goldDark,
                    pt.profit,
                    Colors.white,
                  ],
                ),
              ),
              Center(
                child: FractionalTranslation(
                  translation: Offset(0, _bannerSlide.value),
                  child: Opacity(
                    opacity: _bannerFade.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _bannerScale.value,
                      child: const _WinBanner(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WinBanner extends StatelessWidget {
  const _WinBanner();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pt.goldDark, pt.goldPrimary, pt.goldLight, pt.goldPrimary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: pt.goldPrimary.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Text(
        'YOU WIN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}

/// One falling/exploding confetti chip.
class _ConfettiParticle {
  final double startXFraction;
  final double launchAngle; // radians
  final double launchSpeed; // units per t
  final double size;
  final int paletteIndex;
  final double rotationSpeed;
  final double phaseOffset;

  const _ConfettiParticle({
    required this.startXFraction,
    required this.launchAngle,
    required this.launchSpeed,
    required this.size,
    required this.paletteIndex,
    required this.rotationSpeed,
    required this.phaseOffset,
  });

  factory _ConfettiParticle.random(math.Random r, int seed) {
    return _ConfettiParticle(
      startXFraction: r.nextDouble(),
      launchAngle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi,
      launchSpeed: 220 + r.nextDouble() * 280,
      size: 4 + r.nextDouble() * 5,
      paletteIndex: seed,
      rotationSpeed: (r.nextDouble() - 0.5) * 8,
      phaseOffset: r.nextDouble(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress; // 0..1
  final List<Color> palette;
  static const double _gravity = 800;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final centerY = size.height * 0.35;
    for (final p in particles) {
      final t = (progress + p.phaseOffset * 0.05).clamp(0.0, 1.0);
      final x = p.startXFraction * size.width +
          math.cos(p.launchAngle) * p.launchSpeed * t;
      final y = centerY +
          math.sin(p.launchAngle) * p.launchSpeed * t +
          0.5 * _gravity * t * t;
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      paint.color = palette[p.paletteIndex % palette.length]
          .withValues(alpha: opacity * 0.95);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.6,
          height: p.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
