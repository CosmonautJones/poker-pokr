import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/player_seat.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/pot_display.dart';

/// The main poker table visualization.
///
/// Positions player seats around an oval table, shows community cards
/// and pot in the center. Includes animations for street transitions.
class PokerTableWidget extends StatelessWidget {
  final GameState gameState;

  const PokerTableWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Scale factor for small screens (baseline: 360px wide).
        final scale = (width / 360).clamp(0.7, 1.3);

        // Table dimensions: an oval that fills most of the space.
        final tableWidth = width * 0.92;
        final tableHeight = height * 0.85;
        final centerX = width / 2;
        final centerY = height / 2;

        // Responsive sizes.
        final seatWidth = (90 * scale).clamp(72.0, 100.0);
        final communityWidth = (240 * scale).clamp(180.0, 260.0);
        final potWidth = (160 * scale).clamp(120.0, 180.0);

        // Compute seat positions around an ellipse.
        final seats = _computeSeatPositions(
          gameState.playerCount,
          tableWidth * 0.44,
          tableHeight * 0.40,
          centerX,
          centerY,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Table felt with enhanced visuals
            Positioned(
              left: (width - tableWidth) / 2,
              top: (height - tableHeight) / 2,
              child: _TableFelt(
                width: tableWidth,
                height: tableHeight,
                scale: scale,
              ),
            ),
            // Street indicator (top center of table) - animated
            Positioned(
              left: centerX - 44,
              top: (height - tableHeight) / 2 + 12,
              child: _AnimatedStreetBadge(
                street: gameState.street,
                scale: scale,
              ),
            ),
            // Community cards
            Positioned(
              left: centerX - communityWidth / 2,
              top: centerY - 40 * scale,
              child: SizedBox(
                width: communityWidth,
                child: Center(
                  child: CommunityCardsWidget(
                    cards: gameState.communityCards,
                    scale: scale,
                  ),
                ),
              ),
            ),
            // Pot display
            Positioned(
              left: centerX - potWidth / 2,
              top: centerY + 16 * scale,
              child: SizedBox(
                width: potWidth,
                child: Center(
                  child: PotDisplay(
                    pot: gameState.pot,
                    sidePots: gameState.sidePots,
                    scale: scale,
                  ),
                ),
              ),
            ),
            // Player seats
            for (int i = 0; i < gameState.playerCount; i++)
              Positioned(
                left: seats[i].dx - seatWidth / 2,
                top: seats[i].dy - 36 * scale,
                child: SizedBox(
                  width: seatWidth,
                  child: Center(
                    child: PlayerSeat(
                      player: gameState.players[i],
                      isCurrentPlayer: i == gameState.currentPlayerIndex &&
                          !gameState.isHandComplete,
                      isDealer: i == gameState.dealerIndex,
                      scale: scale,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Compute positions around an ellipse for the given number of players.
  List<Offset> _computeSeatPositions(
    int count,
    double radiusX,
    double radiusY,
    double centerX,
    double centerY,
  ) {
    final positions = <Offset>[];
    // Start from the bottom center and go clockwise.
    // The "hero" (seat 0) is at the bottom.
    final startAngle = math.pi / 2; // bottom
    for (int i = 0; i < count; i++) {
      final angle = startAngle + (2 * math.pi * i / count);
      final x = centerX + radiusX * math.cos(angle);
      final y = centerY + radiusY * math.sin(angle);
      positions.add(Offset(x, y));
    }
    return positions;
  }
}

/// Enhanced table felt with layered gradients and inner glow.
class _TableFelt extends StatelessWidget {
  final double width;
  final double height;
  final double scale;

  const _TableFelt({
    required this.width,
    required this.height,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final borderWidth = (5 * scale).clamp(3.0, 6.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        // Outer rim shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: pt.tableBorder.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            // Base felt gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [pt.feltCenter, pt.feltEdge],
                  radius: 0.9,
                  center: const Alignment(0, -0.1),
                ),
              ),
            ),
            // Subtle inner highlight (top-left light source)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  radius: 0.6,
                  center: const Alignment(-0.3, -0.4),
                ),
              ),
            ),
            // Border rail
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: pt.tableBorder,
                  width: borderWidth,
                ),
              ),
            ),
            // Inner edge shadow (gives depth to the rail)
            Container(
              margin: EdgeInsets.all(borderWidth),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(height / 2 - borderWidth),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated street badge that smoothly transitions between streets.
class _AnimatedStreetBadge extends StatelessWidget {
  final Street street;
  final double scale;

  const _AnimatedStreetBadge({
    required this.street,
    required this.scale,
  });

  String _streetLabel(Street s) {
    return switch (s) {
      Street.preflop => 'Preflop',
      Street.flop => 'Flop',
      Street.turn => 'Turn',
      Street.river => 'River',
      Street.showdown => 'Showdown',
    };
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(street),
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: pt.surfaceOverlay,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pt.borderSubtle.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          _streetLabel(street),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: pt.textMuted,
            fontSize: (11 * scale).clamp(9.0, 12.0),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
