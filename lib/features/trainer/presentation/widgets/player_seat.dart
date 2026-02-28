import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';

/// Displays a single player seat with glass-morphism, rotating turn
/// indicator, winner ring, premium dealer chip, and animated status.
class PlayerSeat extends StatefulWidget {
  final PlayerState player;
  final bool isCurrentPlayer;
  final bool isDealer;
  final bool isStraddler;
  final bool isWinner;
  final double scale;

  const PlayerSeat({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.isDealer = false,
    this.isStraddler = false,
    this.isWinner = false,
    this.scale = 1.0,
  });

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  AnimationController? _winnerController;
  AnimationController? _sparkleController;
  List<_Particle>? _sparkleParticles;

  @override
  void initState() {
    super.initState();

    // Rotating sweep for current player turn indicator.
    _sweepController = AnimationController(
      duration: PokerAnimations.kTurnSweep,
      vsync: this,
    );

    // Breathing glow for all-in and general emphasis.
    _pulseController = AnimationController(
      duration: PokerAnimations.kGlowPulse,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncAnimations();
  }

  @override
  void didUpdateWidget(PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPlayer != oldWidget.isCurrentPlayer ||
        widget.isWinner != oldWidget.isWinner ||
        widget.player.isAllIn != oldWidget.player.isAllIn) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    // Turn indicator sweep.
    if (widget.isCurrentPlayer) {
      if (!_sweepController.isAnimating) _sweepController.repeat();
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _sweepController.stop();
      _sweepController.value = 0;

      // All-in pulse.
      if (widget.player.isAllIn) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }

    // Winner ring + sparkle particles.
    if (widget.isWinner) {
      _winnerController ??= AnimationController(
        duration: PokerAnimations.kWinnerRing,
        vsync: this,
      );
      _winnerController!.repeat();

      _sparkleController ??= AnimationController(
        duration: PokerAnimations.kWinnerSparkle,
        vsync: this,
      );
      _sparkleParticles ??= _Particle.generate(12);
      _sparkleController!.repeat();
    } else {
      _winnerController?.stop();
      _winnerController?.value = 0;
      _sparkleController?.stop();
      _sparkleController?.value = 0;
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _winnerController?.dispose();
    _sparkleController?.dispose();
    super.dispose();
  }

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final player = widget.player;
    final isFolded = player.isFolded;
    final isAllIn = player.isAllIn;
    final scale = widget.scale;
    final minW = (72 * scale).clamp(60.0, 80.0);
    final maxW = (100 * scale).clamp(76.0, 100.0);
    final borderRadius = BorderRadius.circular(12 * scale);

    return AnimatedOpacity(
      duration: PokerAnimations.kFold,
      curve: Curves.easeOut,
      opacity: isFolded ? 0.35 : 1.0,
      child: AnimatedScale(
        duration: PokerAnimations.kFold,
        scale: isFolded ? 0.97 : 1.0,
        child: AnimatedRotation(
          duration: PokerAnimations.kFold,
          turns: isFolded ? -0.01 : 0.0,
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hole cards
              if (player.holeCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: player.holeCards
                        .map((c) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0.5),
                              child: MiniCardWidget(
                                card: c,
                                scale: player.holeCards.length <= 2
                                    ? scale
                                    : scale * 0.7,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              // Main seat container with animations
              Stack(
                alignment: Alignment.center,
                children: [
                  // Winner sparkle particles
                  if (widget.isWinner &&
                      _sparkleController != null &&
                      _sparkleParticles != null)
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _sparkleController!,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _SparklePainter(
                              progress: _sparkleController!.value,
                              color: pt.winnerGlow,
                              particles: _sparkleParticles!,
                            ),
                            child: SizedBox(
                              width: maxW + 24,
                              height: 60 * scale + 24,
                            ),
                          );
                        },
                      ),
                    ),
                  // Winner ring effect
                  if (widget.isWinner && _winnerController != null)
                    _WinnerRingEffect(
                      controller: _winnerController!,
                      color: pt.winnerGlow,
                      minWidth: minW,
                      maxWidth: maxW,
                      borderRadius: borderRadius,
                    ),
                  // Rotating sweep indicator for current player
                  if (widget.isCurrentPlayer)
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _SweepIndicatorPainter(
                              progress: _sweepController.value,
                              color: pt.turnIndicatorGlow,
                              borderRadius: 12 * scale,
                            ),
                            child: SizedBox(
                              width: maxW + 6,
                              height: 60 * scale + 6,
                            ),
                          );
                        },
                      ),
                    ),
                  // Glass seat container
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        constraints:
                            BoxConstraints(minWidth: minW, maxWidth: maxW),
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          boxShadow: widget.isCurrentPlayer
                              ? [
                                  BoxShadow(
                                    color: pt.turnIndicatorGlow.withValues(
                                      alpha: _pulseAnimation.value * 0.4,
                                    ),
                                    blurRadius:
                                        12 * _pulseAnimation.value,
                                    spreadRadius:
                                        2 * _pulseAnimation.value,
                                  ),
                                ]
                              : isAllIn
                                  ? [
                                      BoxShadow(
                                        color: pt.allInGlow.withValues(
                                          alpha:
                                              _pulseAnimation.value * 0.4,
                                        ),
                                        blurRadius:
                                            8 * _pulseAnimation.value,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : widget.isWinner
                                      ? [
                                          BoxShadow(
                                            color: pt.winnerGlow
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Container(
                        constraints:
                            BoxConstraints(minWidth: minW, maxWidth: maxW),
                        padding: EdgeInsets.symmetric(
                          horizontal: (8 * scale).clamp(4.0, 8.0),
                          vertical: (5 * scale).clamp(3.0, 5.0),
                        ),
                        decoration: BoxDecoration(
                          // Glass base — semi-transparent dark
                          color: widget.isCurrentPlayer
                              ? Colors.black.withValues(alpha: 0.55)
                              : Colors.black.withValues(alpha: 0.65),
                          borderRadius: borderRadius,
                          border: Border.all(
                            color: widget.isCurrentPlayer
                                ? pt.turnIndicatorGlow
                                    .withValues(alpha: 0.4)
                                : isAllIn
                                    ? pt.seatBorderAllIn
                                        .withValues(alpha: 0.6)
                                    : widget.isWinner
                                        ? pt.winnerGlow
                                            .withValues(alpha: 0.5)
                                        : Colors.white
                                            .withValues(alpha: 0.08),
                            width: widget.isCurrentPlayer ? 1.5 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Glass sheen overlay
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: borderRadius,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white
                                            .withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.5],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildNameRow(pt, player, scale),
                                SizedBox(height: 2 * scale),
                                _buildStack(pt, player, scale),
                                if (isAllIn)
                                  _AllInBadge(scale: scale),
                                if (isFolded)
                                  _StatusBadge(
                                    label: 'FOLD',
                                    color: pt.badgeFold,
                                    textColor: pt.textMuted,
                                    scale: scale,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Current bet display with chip icon — animated entrance
              if (player.currentBet > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _BetChipDisplay(
                    amount: _formatChips(player.currentBet),
                    scale: scale,
                  )
                      .animate()
                      .slideY(
                        begin: -0.5,
                        end: 0,
                        duration: PokerAnimations.kBetSlideIn,
                        curve: PokerAnimations.betSlideCurve,
                      )
                      .fadeIn(
                        duration: const Duration(milliseconds: 200),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow(PokerTheme pt, PlayerState player, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium dealer chip — concentric gold circles with entrance animation
        if (widget.isDealer)
          Container(
            margin: EdgeInsets.only(right: 3 * scale),
            width: (14 * scale).clamp(10.0, 16.0),
            height: (14 * scale).clamp(10.0, 16.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  pt.goldLight,
                  pt.goldPrimary,
                  pt.goldDark,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: (9 * scale).clamp(7.0, 10.0),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                duration: PokerAnimations.kDealerEntrance,
                curve: PokerAnimations.dealerEntranceCurve,
              )
              .rotate(
                begin: -0.5,
                end: 0,
                duration: PokerAnimations.kDealerEntrance,
                curve: Curves.easeOutCubic,
              ),
        // Straddle badge
        if (widget.isStraddler)
          Container(
            margin: EdgeInsets.only(right: 3 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 3 * scale,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pt.straddlePrimary, pt.straddleSecondary],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'STR',
              style: TextStyle(
                color: Colors.white,
                fontSize: (7 * scale).clamp(6.0, 8.0),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 300))
              .slideX(
                begin: -0.3,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              ),
        // Player name
        Flexible(
          child: Text(
            player.name,
            style: TextStyle(
              color: widget.isCurrentPlayer
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: (11 * scale).clamp(9.0, 12.0),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStack(PokerTheme pt, PlayerState player, double scale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: player.stack),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          _formatChips(value),
          style: TextStyle(
            color: pt.textMuted,
            fontSize: (12 * scale).clamp(9.0, 13.0),
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

/// Rotating sweep indicator painted as a ring around the seat.
class _SweepIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;

  _SweepIndicatorPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final sweepAngle = math.pi * 2;
    final startAngle = progress * sweepAngle - math.pi / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.35, 0.5, 0.7],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()..addRRect(rrect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SweepIndicatorPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Sparkle particles that radiate outward from the winner's seat.
///
/// Particles are pre-generated and passed in to avoid re-randomizing
/// every frame when the painter is reconstructed inside AnimatedBuilder.
class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<_Particle> particles;

  const _SparklePainter({
    required this.progress,
    required this.color,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (final p in particles) {
      final t = (progress + p.phaseOffset) % 1.0;
      final radius = t * maxRadius * p.speed;
      final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.8;

      if (opacity <= 0.01) continue;

      final x = center.dx + math.cos(p.angle) * radius;
      final y = center.dy + math.sin(p.angle) * radius;

      // Draw a 4-pointed star
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final starSize = p.size * (1.0 - t * 0.5);
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final a = (i / 4) * math.pi * 2 - math.pi / 4;
        final outerX = x + math.cos(a) * starSize;
        final outerY = y + math.sin(a) * starSize;
        final innerA = a + math.pi / 4;
        final innerX = x + math.cos(innerA) * starSize * 0.3;
        final innerY = y + math.sin(innerA) * starSize * 0.3;

        if (i == 0) {
          path.moveTo(outerX, outerY);
        } else {
          path.lineTo(outerX, outerY);
        }
        path.lineTo(innerX, innerY);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double phaseOffset;

  const _Particle(this.angle, this.speed, this.size, this.phaseOffset);

  /// Pre-generate a stable list of particles with fixed seed.
  static List<_Particle> generate(int count) {
    final random = math.Random(42);
    return List.generate(count, (i) {
      final angle = (i / count) * math.pi * 2 +
          random.nextDouble() * 0.5;
      final speed = 0.6 + random.nextDouble() * 0.6;
      final size = 1.5 + random.nextDouble() * 2.0;
      final phaseOffset = random.nextDouble();
      return _Particle(angle, speed, size, phaseOffset);
    });
  }
}

/// Animated expanding gold rings for winner celebration.
class _WinnerRingEffect extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double minWidth;
  final double maxWidth;
  final BorderRadius borderRadius;

  const _WinnerRingEffect({
    required this.controller,
    required this.color,
    required this.minWidth,
    required this.maxWidth,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        // Three staggered rings for richer celebration
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRing(t, 0.0),
            _buildRing(t, 0.2),
            _buildRing(t, 0.4),
          ],
        );
      },
    );
  }

  Widget _buildRing(double t, double offset) {
    final adjusted = (t + offset) % 1.0;
    final scale = 1.0 + adjusted * 0.45;
    final opacity = (1.0 - adjusted).clamp(0.0, 0.6);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: maxWidth + 4,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Pulsing ALL IN badge with glow effect and shimmer.
class _AllInBadge extends StatefulWidget {
  final double scale;
  const _AllInBadge({required this.scale});

  @override
  State<_AllInBadge> createState() => _AllInBadgeState();
}

class _AllInBadgeState extends State<_AllInBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final scale = widget.scale;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 0.2 + _controller.value * 0.3;
        return Container(
          margin: EdgeInsets.only(top: 3 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 1.5,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: pt.allInGlow.withValues(alpha: glow),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Text(
            'ALL IN',
            style: TextStyle(
              color: Colors.white,
              fontSize: (8 * scale).clamp(6.0, 9.0),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .shimmer(
          delay: const Duration(milliseconds: 500),
          duration: const Duration(milliseconds: 1800),
          color: Colors.orange.withValues(alpha: 0.3),
        );
  }
}

/// Compact status badge (FOLD) with entrance animation.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final double scale;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.textColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 3 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 1.5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: (8 * scale).clamp(6.0, 9.0),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 250))
        .scaleXY(
          begin: 0.8,
          end: 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
        );
  }
}

/// Bet display with stacked chip icon and animated entrance.
class _BetChipDisplay extends StatelessWidget {
  final String amount;
  final double scale;

  const _BetChipDisplay({required this.amount, required this.scale});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pt.goldDark.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini chip stack icon
          SizedBox(
            width: 8,
            height: 12,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _chipDot(pt.chipRed, 8),
                ),
                Positioned(
                  bottom: 2.5,
                  left: 0,
                  child: _chipDot(pt.chipBlue, 8),
                ),
                Positioned(
                  bottom: 5,
                  left: 0,
                  child: _chipDot(pt.chipWhite, 8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          Text(
            amount,
            style: TextStyle(
              color: pt.chipBet,
              fontSize: (10 * scale).clamp(8.0, 11.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipDot(Color color, double size) {
    return Container(
      width: size,
      height: 3.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 0.3,
        ),
      ),
    );
  }
}
