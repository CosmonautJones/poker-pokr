import 'package:flutter/material.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// Displays the community cards (0-5) in a horizontal row.
class CommunityCardsWidget extends StatelessWidget {
  final List<PokerCard> cards;
  final double scale;

  const CommunityCardsWidget({
    super.key,
    required this.cards,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < cards.length) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * scale),
            child: _CardFace(card: cards[i], scale: scale),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2 * scale),
          child: _CardPlaceholder(scale: scale),
        );
      }),
    );
  }
}

/// Renders a single playing card with rank and suit symbols.
class _CardFace extends StatelessWidget {
  final PokerCard card;
  final double scale;

  const _CardFace({required this.card, this.scale = 1.0});

  Color get _suitColor {
    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return Colors.red.shade400;
      case Suit.clubs:
      case Suit.spades:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = (44 * scale).clamp(30.0, 48.0);
    final h = (62 * scale).clamp(42.0, 68.0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.grey.shade600, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: (18 * scale).clamp(12.0, 20.0),
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: (16 * scale).clamp(10.0, 18.0),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A grayed-out placeholder for an undealt card.
class _CardPlaceholder extends StatelessWidget {
  final double scale;

  const _CardPlaceholder({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final w = (44 * scale).clamp(30.0, 48.0);
    final h = (62 * scale).clamp(42.0, 68.0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.help_outline,
          color: Colors.grey.shade800,
          size: (18 * scale).clamp(12.0, 20.0),
        ),
      ),
    );
  }
}

/// A small card widget for display in player seats (hole cards).
class MiniCardWidget extends StatelessWidget {
  final PokerCard card;
  final bool faceDown;
  final double scale;

  const MiniCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.scale = 1.0,
  });

  Color get _suitColor {
    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return Colors.red.shade400;
      case Suit.clubs:
      case Suit.spades:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = (30 * scale).clamp(22.0, 34.0);
    final h = (42 * scale).clamp(30.0, 46.0);

    if (faceDown) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4 * scale),
          border: Border.all(color: Colors.grey.shade600, width: 0.5),
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(color: Colors.grey.shade600, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: (12 * scale).clamp(9.0, 14.0),
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: (10 * scale).clamp(8.0, 12.0),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
