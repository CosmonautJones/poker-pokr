import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// A bottom sheet that lets the user pick a card by scrolling through
/// rank and suit wheels.
class CardPickerBottomSheet extends StatefulWidget {
  /// Cards that are already assigned and should be shown as unavailable.
  final Set<int> unavailableCardValues;

  /// The currently selected card (if editing an existing selection).
  final PokerCard? initialCard;

  const CardPickerBottomSheet({
    super.key,
    this.unavailableCardValues = const {},
    this.initialCard,
  });

  /// Shows the picker and returns the selected card, or null if cancelled.
  static Future<PokerCard?> show(
    BuildContext context, {
    Set<int> unavailableCardValues = const {},
    PokerCard? initialCard,
  }) {
    final pt = context.poker;
    return showModalBottomSheet<PokerCard>(
      context: context,
      backgroundColor: pt.cardFace,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CardPickerBottomSheet(
        unavailableCardValues: unavailableCardValues,
        initialCard: initialCard,
      ),
    );
  }

  @override
  State<CardPickerBottomSheet> createState() => _CardPickerBottomSheetState();
}

class _CardPickerBottomSheetState extends State<CardPickerBottomSheet> {
  late Rank _selectedRank;
  late Suit _selectedSuit;

  late final FixedExtentScrollController _rankController;
  late final FixedExtentScrollController _suitController;

  @override
  void initState() {
    super.initState();
    _selectedRank = widget.initialCard?.rank ?? Rank.ace;
    _selectedSuit = widget.initialCard?.suit ?? Suit.spades;
    _rankController =
        FixedExtentScrollController(initialItem: _selectedRank.index);
    _suitController =
        FixedExtentScrollController(initialItem: _selectedSuit.index);
  }

  @override
  void dispose() {
    _rankController.dispose();
    _suitController.dispose();
    super.dispose();
  }

  bool _isUnavailable(Rank rank, Suit suit) {
    final value = suit.index * 13 + rank.index;
    return widget.unavailableCardValues.contains(value);
  }

  Color _suitColor(BuildContext context, Suit suit) {
    final pt = context.poker;
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? pt.suitRed
        : pt.suitBlack;
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isCurrentUnavailable = _isUnavailable(_selectedRank, _selectedSuit);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pt.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pick a Card',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Card preview
            _CardPreview(
              rank: _selectedRank,
              suit: _selectedSuit,
              isUnavailable: isCurrentUnavailable,
            ),
            const SizedBox(height: 16),
            // Scroll wheels
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Rank wheel
                  Expanded(
                    child: _WheelPicker<Rank>(
                      label: 'Rank',
                      values: Rank.values,
                      controller: _rankController,
                      itemBuilder: (rank) => Text(
                        rank.symbol,
                        style: TextStyle(
                          color: _isUnavailable(rank, _selectedSuit)
                              ? pt.borderSubtle
                              : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onChanged: (rank) {
                        setState(() => _selectedRank = rank);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Suit wheel
                  Expanded(
                    child: _WheelPicker<Suit>(
                      label: 'Suit',
                      values: Suit.values,
                      controller: _suitController,
                      itemBuilder: (suit) => Text(
                        suit.symbol,
                        style: TextStyle(
                          color: _isUnavailable(_selectedRank, suit)
                              ? pt.borderSubtle
                              : _suitColor(context, suit),
                          fontSize: 26,
                        ),
                      ),
                      onChanged: (suit) {
                        setState(() => _selectedSuit = suit);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Confirm / Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pt.textMuted,
                      side: BorderSide(color: pt.seatBorderDefault),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isCurrentUnavailable
                        ? null
                        : () {
                            final card =
                                PokerCard.from(_selectedRank, _selectedSuit);
                            Navigator.pop(context, card);
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                        isCurrentUnavailable ? 'Already Dealt' : 'Select'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview of the currently selected card.
class _CardPreview extends StatelessWidget {
  final Rank rank;
  final Suit suit;
  final bool isUnavailable;

  const _CardPreview({
    required this.rank,
    required this.suit,
    required this.isUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final suitColor = isUnavailable
        ? pt.borderSubtle
        : (suit == Suit.hearts || suit == Suit.diamonds)
            ? pt.suitRed
            : pt.suitBlack;

    return Container(
      width: 64,
      height: 90,
      decoration: BoxDecoration(
        color: isUnavailable ? pt.cardPlaceholder : pt.cardFace,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnavailable ? pt.borderSubtle : pt.cardBorder,
          width: 1.5,
        ),
        boxShadow: isUnavailable
            ? null
            : const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rank.symbol,
              style: TextStyle(
                color: suitColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          Text(
            suit.symbol,
            style: TextStyle(
              color: suitColor,
              fontSize: 24,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A generic scroll-wheel picker using ListWheelScrollView.
class _WheelPicker<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final FixedExtentScrollController controller;
  final Widget Function(T value) itemBuilder;
  final ValueChanged<T> onChanged;

  const _WheelPicker({
    required this.label,
    required this.values,
    required this.controller,
    required this.itemBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: pt.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Stack(
            children: [
              // Selection highlight
              Center(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal:
                          BorderSide(color: pt.seatBorderDefault, width: 1),
                    ),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                onSelectedItemChanged: (index) => onChanged(values[index]),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: values.length,
                  builder: (context, index) {
                    return Center(child: itemBuilder(values[index]));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
