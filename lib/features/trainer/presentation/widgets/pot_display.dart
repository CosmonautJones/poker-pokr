import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/pot.dart';

/// Displays the current pot with gold shimmer text, chip icon, and
/// animated value changes. Shows side pots when present.
class PotDisplay extends StatelessWidget {
  final double pot;
  final List<SidePot> sidePots;
  final double scale;

  const PotDisplay({
    super.key,
    required this.pot,
    this.sidePots = const [],
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PotPill(pot: pot, scale: scale),
        if (sidePots.isNotEmpty && sidePots.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 4 * scale),
            child: Wrap(
              spacing: 4 * scale,
              children: [
                for (int i = 0; i < sidePots.length; i++)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pt.goldDark.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Side ${i + 1}: ${_formatChips(sidePots[i].amount)}',
                      style: TextStyle(
                        color: pt.potText.withValues(alpha: 0.8),
                        fontSize: (10 * scale).clamp(8.0, 11.0),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 80 * i),
                        duration: const Duration(milliseconds: 300),
                      )
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        delay: Duration(milliseconds: 80 * i),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
              ],
            ),
          ),
      ],
    );
  }

  static String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}

/// The main pot pill with gold shimmer, chip icon, scale-flash on change,
/// and enhanced ambient glow for large pots.
class _PotPill extends StatefulWidget {
  final double pot;
  final double scale;

  const _PotPill({required this.pot, required this.scale});

  @override
  State<_PotPill> createState() => _PotPillState();
}

class _PotPillState extends State<_PotPill>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  late AnimationController _flashController;
  late Animation<double> _flashScale;

  late AnimationController _chipWobbleController;
  late Animation<double> _chipWobble;

  double _previousPot = 0;

  @override
  void initState() {
    super.initState();
    _previousPot = widget.pot;

    // Gold shimmer sweep
    _shimmerController = AnimationController(
      duration: PokerAnimations.kShimmer,
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Pot change flash
    _flashController = AnimationController(
      duration: PokerAnimations.kPotFlash,
      vsync: this,
    );
    _flashScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_flashController);

    // Chip wobble on pot change
    _chipWobbleController = AnimationController(
      duration: PokerAnimations.kChipWobble,
      vsync: this,
    );
    _chipWobble = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.08),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.08, end: -0.06),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.06, end: 0.03),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.03, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_chipWobbleController);
  }

  @override
  void didUpdateWidget(_PotPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.pot - _previousPot).abs() > 0.01) {
      _previousPot = widget.pot;
      _flashController.forward(from: 0);
      _chipWobbleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _flashController.dispose();
    _chipWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final scale = widget.scale;

    // Enhanced glow for large pots (more gold glow when pot is big)
    final potGlowIntensity = (widget.pot / 500).clamp(0.05, 0.25);

    return AnimatedBuilder(
      animation: _flashScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _flashController.isAnimating ? _flashScale.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (14 * scale).clamp(10.0, 18.0),
          vertical: (6 * scale).clamp(4.0, 8.0),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.black.withValues(alpha: 0.55),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pt.goldDark.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: pt.goldPrimary.withValues(alpha: potGlowIntensity),
              blurRadius: 8 + potGlowIntensity * 16,
              spreadRadius: 1 + potGlowIntensity * 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chip stack icon with wobble on change
            AnimatedBuilder(
              animation: _chipWobble,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _chipWobbleController.isAnimating
                      ? _chipWobble.value
                      : 0,
                  child: child,
                );
              },
              child: SizedBox(
                width: 10,
                height: 14,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      child: _chipSlice(pt.chipRed, 10),
                    ),
                    Positioned(
                      bottom: 3,
                      child: _chipSlice(pt.chipBlue, 10),
                    ),
                    Positioned(
                      bottom: 6,
                      child: _chipSlice(pt.chipGreen, 10),
                    ),
                    Positioned(
                      bottom: 9,
                      child: _chipSlice(pt.chipWhite, 10),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            // Gold shimmer pot text
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, _) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        pt.potText,
                        pt.goldLight,
                        pt.potText,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(_shimmerAnimation.value - 1, 0),
                      end: Alignment(_shimmerAnimation.value, 0),
                    ).createShader(bounds);
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: widget.pot),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        'Pot: ${PotDisplay._formatChips(value)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (14 * scale).clamp(11.0, 16.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipSlice(Color color, double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.25),
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 0.5,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
    );
  }
}
