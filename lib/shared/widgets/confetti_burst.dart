import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:poker_trainer/core/utils/motion.dart';

/// Lightweight one-shot confetti burst used by the achievement-unlock
/// banner. ~16 particles emitted from the centre and falling outward;
/// renders nothing when reduced-motion is on.
class ConfettiBurst extends StatefulWidget {
  final List<Color> colors;
  final int particleCount;
  final Duration duration;

  const ConfettiBurst({
    super.key,
    required this.colors,
    this.particleCount = 16,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final rng = math.Random(0xC0FFEE);
    _particles = List.generate(widget.particleCount, (i) {
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 1.4;
      final speed = 90 + rng.nextDouble() * 80;
      return _Particle(
        angle: angle,
        speed: speed,
        rotation: rng.nextDouble() * math.pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 6,
        color: widget.colors[i % widget.colors.length],
        size: 4 + rng.nextDouble() * 3,
        wobble: (rng.nextDouble() - 0.5) * 2.0,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.shouldAnimate(context) && !_controller.isAnimating &&
        _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.shouldAnimate(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BurstPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;
  final double wobble;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.wobble,
  });
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _BurstPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Easing: fast emission, gentle settle.
    final t = progress;
    final tEased = Curves.easeOutQuad.transform(t);
    final fade = (1.0 - t).clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * tEased + p.wobble * t * 20;
      // Gravity pulls particles down quadratically.
      final dy = math.sin(p.angle) * p.speed * tEased + 120 * t * t;
      final paint = Paint()..color = p.color.withValues(alpha: 0.9 * fade);
      canvas.save();
      canvas.translate(cx + dx, cy + dy);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
