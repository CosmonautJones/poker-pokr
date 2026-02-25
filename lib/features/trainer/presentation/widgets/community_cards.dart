import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// Displays the community cards (0-5) in a horizontal row with deal animations.
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
            child: _AnimatedCardDeal(
              key: ValueKey('community_${cards[i].rank}_${cards[i].suit}'),
              child: _CardFace(card: cards[i], scale: scale),
            ),
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

/// Wraps a card widget with a slide-up + fade-in animation on first build.
class _AnimatedCardDeal extends StatefulWidget {
  final Widget child;

  const _AnimatedCardDeal({super.key, required this.child});

  @override
  State<_AnimatedCardDeal> createState() => _AnimatedCardDealState();
}

class _AnimatedCardDealState extends State<_AnimatedCardDeal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Renders a single playing card with rank and suit symbols.
class _CardFace extends StatelessWidget {
  final PokerCard card;
  final double scale;

  const _CardFace({required this.card, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final suitColor = isRed ? pt.suitRed : pt.suitBlack;

    final w = (44 * scale).clamp(30.0, 48.0);
    final h = (62 * scale).clamp(42.0, 68.0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pt.cardFace,
            Color.lerp(pt.cardFace, Colors.white, 0.06)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: pt.cardBorder.withValues(alpha: 0.5), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 1,
            offset: const Offset(-0.5, -0.5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: suitColor,
                fontSize: (18 * scale).clamp(12.0, 20.0),
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: suitColor,
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
    final pt = context.poker;
    final w = (44 * scale).clamp(30.0, 48.0);
    final h = (62 * scale).clamp(42.0, 68.0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: pt.cardPlaceholder,
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          width: 0.5,
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

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final suitColor = isRed ? pt.suitRed : pt.suitBlack;

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
          border: Border.all(color: pt.cardBorder, width: 0.5),
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pt.cardFace,
            Color.lerp(pt.cardFace, Colors.white, 0.04)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(color: pt.cardBorder.withValues(alpha: 0.4), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0.5, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: suitColor,
                fontSize: (12 * scale).clamp(9.0, 14.0),
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: suitColor,
              fontSize: (10 * scale).clamp(8.0, 12.0),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
