import 'dart:math' as math;
import 'package:flutter/material.dart';
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

    // Winner ring.
    if (widget.isWinner) {
      _winnerController ??= AnimationController(
        duration: PokerAnimations.kWinnerRing,
        vsync: this,
      );
      _winnerController!.repeat();
    } else {
      _winnerController?.stop();
      _winnerController?.value = 0;
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _winnerController?.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hole cards
            if (player.holeCards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: player.holeCards.length <= 2
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: player.holeCards
                            .map((c) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  child: MiniCardWidget(
                                      card: c, scale: scale),
                                ))
                            .toList(),
                      )
                    : Wrap(
                        spacing: 1,
                        runSpacing: 1,
                        alignment: WrapAlignment.center,
                        children: player.holeCards
                            .map((c) => MiniCardWidget(
                                card: c, scale: scale * 0.85))
                            .toList(),
                      ),
              ),
            // Main seat container with animations
            Stack(
              alignment: Alignment.center,
              children: [
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
                  AnimatedBuilder(
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
            // Current bet display with chip icon
            if (player.currentBet > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: _BetChipDisplay(
                  amount: _formatChips(player.currentBet),
                  scale: scale,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow(PokerTheme pt, PlayerState player, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium dealer chip — concentric gold circles
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
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
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
        // Two staggered rings
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRing(t, 0.0),
            _buildRing(t, 0.25),
          ],
        );
      },
    );
  }

  Widget _buildRing(double t, double offset) {
    final adjusted = (t + offset) % 1.0;
    final scale = 1.0 + adjusted * 0.4;
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

/// Pulsing ALL IN badge with glow effect.
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
    );
  }
}

/// Compact status badge (FOLD).
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
    );
  }
}

/// Bet display with stacked chip icon.
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
