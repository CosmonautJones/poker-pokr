import 'package:flutter/material.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';

/// Displays a single player seat showing name, stack, cards, and status.
class PlayerSeat extends StatelessWidget {
  final PlayerState player;
  final bool isCurrentPlayer;
  final bool isDealer;

  const PlayerSeat({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.isDealer = false,
  });

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isFolded = player.isFolded;
    final isAllIn = player.isAllIn;
    final opacity = isFolded ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hole cards
          if (player.holeCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: player.holeCards
                    .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: MiniCardWidget(card: c),
                        ))
                    .toList(),
              ),
            ),
          // Main seat container
          Container(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentPlayer
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF212121),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrentPlayer
                    ? Colors.greenAccent
                    : isAllIn
                        ? Colors.orange
                        : Colors.grey.shade700,
                width: isCurrentPlayer ? 2 : 1,
              ),
              boxShadow: isCurrentPlayer
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Player name row with optional dealer chip
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDealer)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'D',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Stack
                Text(
                  _formatChips(player.stack),
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Status badges
                if (isAllIn)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ALL IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isFolded)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FOLD',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Current bet display
          if (player.currentBet > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatChips(player.currentBet),
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
