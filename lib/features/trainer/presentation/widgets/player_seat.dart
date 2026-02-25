import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';

/// Displays a single player seat showing name, stack, cards, and status.
class PlayerSeat extends StatefulWidget {
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

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isCurrentPlayer) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPlayer && !oldWidget.isCurrentPlayer) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrentPlayer && oldWidget.isCurrentPlayer) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      opacity: isFolded ? 0.35 : 1.0,
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
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: MiniCardWidget(card: c, scale: scale),
                        ))
                    .toList(),
              ),
            ),
          // Main seat container with animated glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
                padding: EdgeInsets.symmetric(
                  horizontal: (8 * scale).clamp(4.0, 8.0),
                  vertical: (5 * scale).clamp(3.0, 5.0),
                ),
                decoration: BoxDecoration(
                  color: widget.isCurrentPlayer
                      ? pt.seatActive
                      : pt.seatBackground,
                  borderRadius: BorderRadius.circular(10 * scale),
                  border: Border.all(
                    color: widget.isCurrentPlayer
                        ? pt.seatActiveBorder
                        : isAllIn
                            ? pt.seatBorderAllIn
                            : pt.seatBorderDefault,
                    width: widget.isCurrentPlayer ? 1.5 : 1,
                  ),
                  boxShadow: widget.isCurrentPlayer
                      ? [
                          BoxShadow(
                            color: pt.seatActiveGlow
                                .withValues(alpha: _pulseAnimation.value * 0.6),
                            blurRadius: 12 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                          ),
                        ]
                      : isAllIn
                          ? [
                              BoxShadow(
                                color:
                                    pt.seatBorderAllIn.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                ),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Player name row with optional dealer chip
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isDealer)
                      Container(
                        margin: EdgeInsets.only(right: 3 * scale),
                        width: (14 * scale).clamp(10.0, 16.0),
                        height: (14 * scale).clamp(10.0, 16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              pt.dealerChip,
                              pt.dealerChip.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pt.dealerChip.withValues(alpha: 0.4),
                              blurRadius: 3,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                  _StatusBadge(
                    label: 'ALL IN',
                    color: pt.badgeAllIn,
                    textColor: Colors.white,
                    scale: scale,
                  ),
                if (isFolded)
                  _StatusBadge(
                    label: 'FOLD',
                    color: pt.badgeFold,
                    textColor: pt.textMuted,
                    scale: scale,
                  ),
              ],
            ),
          ),
          // Current bet display
          if (player.currentBet > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: pt.chipBet.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
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

/// A compact status badge (ALL IN / FOLD).
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
