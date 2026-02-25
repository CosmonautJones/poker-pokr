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

        // Winner set for highlighting.
        final winners = gameState.isHandComplete
            ? (gameState.winnerIndices ?? <int>{})
            : <int>{};

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Table felt with premium visuals
            Positioned(
              left: (width - tableWidth) / 2,
              top: (height - tableHeight) / 2,
              child: _TableFelt(
                width: tableWidth,
                height: tableHeight,
                scale: scale,
              ),
            ),
            // Street indicator (top center of table) — metallic badge
            Positioned(
              left: centerX - 50,
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
                      isStraddler: i == gameState.straddlePlayerIndex,
                      isWinner: winners.contains(i),
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

/// Premium table felt with gold rail, directional lighting, and vignette.
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
    final railWidth = (5 * scale).clamp(3.0, 6.0);
    final radius = BorderRadius.circular(height / 2);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Deep drop shadow for floating effect
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          // Gold ambient glow from the rail
          BoxShadow(
            color: pt.goldDark.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Base felt — 3-stop radial with directional lamp
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    pt.feltCenter,
                    pt.feltHighlight,
                    pt.feltEdge,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                  radius: 0.9,
                  center: const Alignment(-0.15, -0.25),
                ),
              ),
            ),
            // Directional highlight — simulates overhead lamp
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7],
                  radius: 0.6,
                  center: const Alignment(-0.3, -0.4),
                ),
              ),
            ),
            // Vignette — darkens edges, draws eye to center
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  radius: 0.85,
                  center: Alignment.center,
                ),
              ),
            ),
            // Gold rail — multi-stop gradient simulating cylindrical wood/gold
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: pt.goldDark,
                  width: railWidth,
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: pt.goldPrimary.withValues(alpha: 0.4),
                  width: railWidth * 0.5,
                ),
              ),
            ),
            // Inner rail highlight — specular reflection
            Container(
              margin: EdgeInsets.all(railWidth),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(height / 2 - railWidth),
                border: Border.all(
                  color: pt.goldLight.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            // Inner edge shadow — depth between felt and rail
            Container(
              margin: EdgeInsets.all(railWidth + 1),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(height / 2 - railWidth - 1),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
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

/// Metallic gold street badge with cinematic transitions.
class _AnimatedStreetBadge extends StatelessWidget {
  final Street street;
  final double scale;

  const _AnimatedStreetBadge({
    required this.street,
    required this.scale,
  });

  String _streetLabel(Street s) {
    return switch (s) {
      Street.preflop => 'PREFLOP',
      Street.flop => 'FLOP',
      Street.turn => 'TURN',
      Street.river => 'RIVER',
      Street.showdown => 'SHOWDOWN',
    };
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(
                    parent: animation, curve: Curves.elasticOut),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        key: ValueKey(street),
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              pt.goldDark,
              pt.goldPrimary,
              pt.goldDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pt.goldLight.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: pt.goldPrimary.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _streetLabel(street),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: (11 * scale).clamp(9.0, 12.0),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
