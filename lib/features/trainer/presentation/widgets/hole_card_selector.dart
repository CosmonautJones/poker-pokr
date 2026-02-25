import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/card_picker.dart';

/// Displays tappable card slots for a player's hole cards,
/// plus a random-deal button. Supports 2 cards (Hold'em) or 4 cards (Omaha).
class HoleCardSelector extends StatelessWidget {
  final int playerIndex;
  final List<PokerCard>? holeCards;
  final Set<int> unavailableCardValues;
  final VoidCallback? onRandomDeal;

  /// Number of card slots to display (2 for Hold'em, 4 for Omaha).
  final int cardCount;

  /// Called when a card is selected at the given index.
  final void Function(int cardIndex, PokerCard card)? onCardSelected;

  /// Called when a card is cleared at the given index.
  final void Function(int cardIndex)? onCardCleared;

  // Legacy callbacks for backwards compatibility.
  final ValueChanged<PokerCard>? onCard1Selected;
  final ValueChanged<PokerCard>? onCard2Selected;
  final VoidCallback? onCard1Cleared;
  final VoidCallback? onCard2Cleared;

  const HoleCardSelector({
    super.key,
    required this.playerIndex,
    this.holeCards,
    this.unavailableCardValues = const {},
    this.onCard1Selected,
    this.onCard2Selected,
    this.onCard1Cleared,
    this.onCard2Cleared,
    this.onRandomDeal,
    this.cardCount = 2,
    this.onCardSelected,
    this.onCardCleared,
  });

  PokerCard? _cardAt(int index) {
    if (holeCards == null || index >= holeCards!.length) return null;
    return holeCards![index];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cardCount; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _CardSlot(
            card: _cardAt(i),
            unavailableCardValues: unavailableCardValues,
            onTap: () => _pickCard(context, i, _cardAt(i)),
            onLongPress: _cardAt(i) != null ? () => _clearCard(i) : null,
          ),
        ],
        const SizedBox(width: 6),
        _RandomButton(onTap: onRandomDeal),
      ],
    );
  }

  void _clearCard(int cardIndex) {
    if (onCardCleared != null) {
      onCardCleared!(cardIndex);
    } else if (cardIndex == 0) {
      onCard1Cleared?.call();
    } else if (cardIndex == 1) {
      onCard2Cleared?.call();
    }
  }

  void _pickCard(BuildContext context, int cardIndex, PokerCard? current) async {
    // Exclude this player's own other cards from unavailable set.
    final excluded = Set<int>.of(unavailableCardValues);
    if (holeCards != null) {
      for (int i = 0; i < holeCards!.length; i++) {
        if (i != cardIndex) excluded.add(holeCards![i].value);
      }
    }
    // Remove the current card from unavailable (so it stays selectable).
    if (current != null) excluded.remove(current.value);

    final picked = await CardPickerBottomSheet.show(
      context,
      unavailableCardValues: excluded,
      initialCard: current,
    );
    if (picked != null) {
      if (onCardSelected != null) {
        onCardSelected!(cardIndex, picked);
      } else if (cardIndex == 0) {
        onCard1Selected?.call(picked);
      } else if (cardIndex == 1) {
        onCard2Selected?.call(picked);
      }
    }
  }
}

/// A tappable card slot that shows either a card face or a placeholder.
class _CardSlot extends StatelessWidget {
  final PokerCard? card;
  final Set<int> unavailableCardValues;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CardSlot({
    this.card,
    this.unavailableCardValues = const {},
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card != null ? _buildFace(context, card!) : _buildEmpty(context),
    );
  }

  Widget _buildFace(BuildContext context, PokerCard card) {
    final pt = context.poker;
    final suitColor = (card.suit == Suit.hearts || card.suit == Suit.diamonds)
        ? pt.suitRed
        : pt.suitBlack;

    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: pt.cardFace,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: pt.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: suitColor,
              fontSize: 13,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final pt = context.poker;
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: pt.cardPlaceholder,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: pt.borderSubtle, width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: pt.borderSubtle,
          size: 18,
        ),
      ),
    );
  }
}

/// Small dice icon button that deals random cards.
class _RandomButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _RandomButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Tooltip(
        message: 'Random hand',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: pt.borderSubtle,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.casino,
            color: pt.accent,
            size: 18,
          ),
        ),
      ),
    );
  }
}
