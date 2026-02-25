import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/pot.dart';

/// Displays the current pot amount with animated value changes and any side pots.
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
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (14 * scale).clamp(10.0, 18.0),
            vertical: (6 * scale).clamp(4.0, 8.0),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pt.potBorder,
              width: 0.5,
            ),
          ),
          child: _AnimatedPotValue(
            pot: pot,
            style: TextStyle(
              color: pt.potText,
              fontSize: (14 * scale).clamp(11.0, 16.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Side ${i + 1}: ${_formatChips(sidePots[i].amount)}',
                      style: TextStyle(
                        color: pt.potText.withValues(alpha: 0.8),
                        fontSize: (10 * scale).clamp(8.0, 11.0),
                      ),
                    ),
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

/// Animated pot value that smoothly transitions between amounts.
class _AnimatedPotValue extends StatelessWidget {
  final double pot;
  final TextStyle style;

  const _AnimatedPotValue({required this.pot, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: pot),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          'Pot: ${PotDisplay._formatChips(value)}',
          style: style,
        );
      },
    );
  }
}
