import 'package:flutter/material.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// Displays the community cards (0-5) in a horizontal row.
class CommunityCardsWidget extends StatelessWidget {
  final List<PokerCard> cards;

  const CommunityCardsWidget({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < cards.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _CardFace(card: cards[i]),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _CardPlaceholder(),
        );
      }),
    );
  }
}

/// Renders a single playing card with rank and suit symbols.
class _CardFace extends StatelessWidget {
  final PokerCard card;

  const _CardFace({required this.card});

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
    return Container(
      width: 44,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(6),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: 16,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.help_outline,
          color: Colors.grey.shade800,
          size: 18,
        ),
      ),
    );
  }
}

/// A small card widget for display in player seats (hole cards).
class MiniCardWidget extends StatelessWidget {
  final PokerCard card;
  final bool faceDown;

  const MiniCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
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
    if (faceDown) {
      return Container(
        width: 30,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade600, width: 0.5),
        ),
      );
    }

    return Container(
      width: 30,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade600, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: _suitColor,
              fontSize: 10,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
