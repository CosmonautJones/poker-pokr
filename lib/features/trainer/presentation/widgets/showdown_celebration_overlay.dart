import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Brief full-screen celebration shown when the viewer's player wins at
/// showdown. Tap-anywhere dismisses early; parent owns the auto-dismiss
/// timer.
class ShowdownCelebrationOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const ShowdownCelebrationOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    final palette = <Color>[
      pt.goldPrimary,
      pt.goldLight,
      pt.profit,
      pt.allInGlow,
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop wash that softly tints the table gold.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  pt.goldPrimary.withValues(alpha: 0.22),
                  pt.goldPrimary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .then(delay: 1100.ms)
              .fadeOut(duration: 400.ms),
          // Particle burst.
          ..._buildSparkles(palette),
          // Centered "Winner!" badge.
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pt.goldDark, pt.goldPrimary, pt.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Winner!',
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 220.ms)
                .then(delay: 900.ms)
                .fadeOut(duration: 400.ms)
                .scaleXY(end: 0.94, duration: 400.ms),
          ),
        ],
      ),
    );
  }

  /// Builds the sparkle particles. Positions are deterministic but evenly
  /// scattered so the celebration feels lively without flashing.
  List<Widget> _buildSparkles(List<Color> palette) {
    const count = 14;
    final rng = math.Random(7); // fixed seed → stable layout per launch
    final widgets = <Widget>[];
    for (int i = 0; i < count; i++) {
      final dx = (rng.nextDouble() - 0.5) * 1.4; // -0.7..0.7
      final dy = (rng.nextDouble() - 0.5) * 1.0; // -0.5..0.5
      final size = 8.0 + rng.nextDouble() * 12.0;
      final color = palette[i % palette.length];
      final delay = (i * 22).ms;
      widgets.add(
        Align(
          alignment: Alignment(dx, dy),
          child: _Sparkle(color: color, size: size)
              .animate(delay: delay)
              .fadeIn(duration: 200.ms)
              .scaleXY(begin: 0.4, end: 1.0, duration: 320.ms)
              .moveY(begin: 0, end: -28, duration: 700.ms)
              .then()
              .fadeOut(duration: 350.ms),
        ),
      );
    }
    return widgets;
  }
}

class _Sparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _Sparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
