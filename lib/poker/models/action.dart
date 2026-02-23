/// Poker action types and the immutable PokerAction value object.
///
/// Pure Dart - no Flutter imports.
library;

enum ActionType {
  fold,
  check,
  call,
  bet,
  raise,
  allIn;
}

/// An immutable record of a single player action.
class PokerAction {
  final int playerIndex;
  final ActionType type;
  final double amount;

  const PokerAction({
    required this.playerIndex,
    required this.type,
    this.amount = 0,
  });

  @override
  String toString() =>
      'PokerAction(player: $playerIndex, type: ${type.name}, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PokerAction &&
          other.playerIndex == playerIndex &&
          other.type == type &&
          other.amount == amount);

  @override
  int get hashCode => Object.hash(playerIndex, type, amount);
}
