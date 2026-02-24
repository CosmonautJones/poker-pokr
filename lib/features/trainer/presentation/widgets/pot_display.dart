import 'package:flutter/material.dart';
import 'package:poker_trainer/poker/models/pot.dart';

/// Displays the current pot amount and any side pots, centered on the table.
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

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (12 * scale).clamp(8.0, 16.0),
            vertical: (5 * scale).clamp(3.0, 6.0),
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: Text(
            'Pot: ${_formatChips(pot)}',
            style: TextStyle(
              color: Colors.amber,
              fontSize: (14 * scale).clamp(11.0, 16.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (sidePots.isNotEmpty && sidePots.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 3 * scale),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Side ${i + 1}: ${_formatChips(sidePots[i].amount)}',
                      style: TextStyle(
                        color: Colors.amber,
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
}
