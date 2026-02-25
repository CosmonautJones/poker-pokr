import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';

/// Displays a single player seat showing name, stack, cards, and status.
class PlayerSeat extends StatelessWidget {
  final PlayerState player;
  final bool isCurrentPlayer;
  final bool isDealer;
  final double scale;

  const PlayerSeat({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.isDealer = false,
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
    final pt = context.poker;
    final isFolded = player.isFolded;
    final isAllIn = player.isAllIn;
    final opacity = isFolded ? 0.4 : 1.0;
    final minW = (72 * scale).clamp(60.0, 80.0);
    final maxW = (100 * scale).clamp(76.0, 100.0);

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
                          child: MiniCardWidget(card: c, scale: scale),
                        ))
                    .toList(),
              ),
            ),
          // Main seat container
          Container(
            constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
            padding: EdgeInsets.symmetric(
              horizontal: (8 * scale).clamp(4.0, 8.0),
              vertical: (4 * scale).clamp(2.0, 4.0),
            ),
            decoration: BoxDecoration(
              color: isCurrentPlayer ? pt.seatActive : pt.seatBackground,
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(
                color: isCurrentPlayer
                    ? pt.seatActiveBorder
                    : isAllIn
                        ? pt.seatBorderAllIn
                        : pt.seatBorderDefault,
                width: isCurrentPlayer ? 2 : 1,
              ),
              boxShadow: isCurrentPlayer
                  ? [
                      BoxShadow(
                        color: pt.seatActiveGlow,
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
                        margin: EdgeInsets.only(right: 3 * scale),
                        width: (14 * scale).clamp(10.0, 16.0),
                        height: (14 * scale).clamp(10.0, 16.0),
                        decoration: BoxDecoration(
                          color: pt.dealerChip,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'D',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: (9 * scale).clamp(7.0, 10.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (11 * scale).clamp(9.0, 12.0),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2 * scale),
                // Stack
                Text(
                  _formatChips(player.stack),
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: (12 * scale).clamp(9.0, 13.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Status badges
                if (isAllIn)
                  Container(
                    margin: EdgeInsets.only(top: 2 * scale),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4 * scale,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: pt.badgeAllIn,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ALL IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (8 * scale).clamp(6.0, 9.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isFolded)
                  Container(
                    margin: EdgeInsets.only(top: 2 * scale),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4 * scale,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: pt.badgeFold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FOLD',
                      style: TextStyle(
                        color: pt.textMuted,
                        fontSize: (8 * scale).clamp(6.0, 9.0),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 4 * scale,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatChips(player.currentBet),
                  style: TextStyle(
                    color: pt.chipBet,
                    fontSize: (10 * scale).clamp(8.0, 11.0),
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
