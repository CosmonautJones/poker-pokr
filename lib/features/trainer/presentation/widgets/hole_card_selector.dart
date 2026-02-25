import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/card_picker.dart';

/// Displays two tappable card slots for a player's hole cards,
/// plus a random-deal button.
class HoleCardSelector extends StatelessWidget {
  final int playerIndex;
  final List<PokerCard>? holeCards;
  final Set<int> unavailableCardValues;
  final ValueChanged<PokerCard>? onCard1Selected;
  final ValueChanged<PokerCard>? onCard2Selected;
  final VoidCallback? onCard1Cleared;
  final VoidCallback? onCard2Cleared;
  final VoidCallback? onRandomDeal;

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
  });

  @override
  Widget build(BuildContext context) {
    final card1 = (holeCards != null && holeCards!.isNotEmpty)
        ? holeCards![0]
        : null;
    final card2 = (holeCards != null && holeCards!.length > 1)
        ? holeCards![1]
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card 1 slot
        _CardSlot(
          card: card1,
          unavailableCardValues: unavailableCardValues,
          onTap: () => _pickCard(context, 0, card1),
          onLongPress: card1 != null ? onCard1Cleared : null,
        ),
        const SizedBox(width: 4),
        // Card 2 slot
        _CardSlot(
          card: card2,
          unavailableCardValues: unavailableCardValues,
          onTap: () => _pickCard(context, 1, card2),
          onLongPress: card2 != null ? onCard2Cleared : null,
        ),
        const SizedBox(width: 6),
        // Random button
        _RandomButton(onTap: onRandomDeal),
      ],
    );
  }

  void _pickCard(BuildContext context, int cardIndex, PokerCard? current) async {
    // Exclude this player's own other card from unavailable set.
    final excluded = Set<int>.of(unavailableCardValues);
    if (cardIndex == 0 && holeCards != null && holeCards!.length > 1) {
      excluded.add(holeCards![1].value);
    }
    if (cardIndex == 1 && holeCards != null && holeCards!.isNotEmpty) {
      excluded.add(holeCards![0].value);
    }
    // Remove the current card from unavailable (so it stays selectable).
    if (current != null) excluded.remove(current.value);

    final picked = await CardPickerBottomSheet.show(
      context,
      unavailableCardValues: excluded,
      initialCard: current,
    );
    if (picked != null) {
      if (cardIndex == 0) {
        onCard1Selected?.call(picked);
      } else {
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
