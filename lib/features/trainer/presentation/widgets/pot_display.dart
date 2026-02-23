import 'package:flutter/material.dart';
import 'package:poker_trainer/poker/models/pot.dart';

/// Displays the current pot amount and any side pots, centered on the table.
class PotDisplay extends StatelessWidget {
  final double pot;
  final List<SidePot> sidePots;

  const PotDisplay({
    super.key,
    required this.pot,
    this.sidePots = const [],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: Text(
            'Pot: ${_formatChips(pot)}',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (sidePots.isNotEmpty && sidePots.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              children: [
                for (int i = 0; i < sidePots.length; i++)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Side ${i + 1}: ${_formatChips(sidePots[i].amount)}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
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
