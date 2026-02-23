/// Immutable player state within a poker hand.
///
/// Pure Dart - no Flutter imports.
library;

import 'card.dart';

class PlayerState {
  final int index;
  final String name;
  final double stack;
  final List<PokerCard> holeCards;
  final bool isFolded;
  final bool isAllIn;
  final double currentBet;
  final double totalInvested;

  const PlayerState({
    required this.index,
    required this.name,
    required this.stack,
    this.holeCards = const [],
    this.isFolded = false,
    this.isAllIn = false,
    this.currentBet = 0,
    this.totalInvested = 0,
  });

  /// A player is active if they have not folded and are not all-in.
  bool get isActive => !isFolded && !isAllIn;

  /// A player is still in the hand (eligible for pots) if they haven't folded.
  bool get isInHand => !isFolded;

  PlayerState copyWith({
    int? index,
    String? name,
    double? stack,
    List<PokerCard>? holeCards,
    bool? isFolded,
    bool? isAllIn,
    double? currentBet,
    double? totalInvested,
  }) {
    return PlayerState(
      index: index ?? this.index,
      name: name ?? this.name,
      stack: stack ?? this.stack,
      holeCards: holeCards ?? this.holeCards,
      isFolded: isFolded ?? this.isFolded,
      isAllIn: isAllIn ?? this.isAllIn,
      currentBet: currentBet ?? this.currentBet,
      totalInvested: totalInvested ?? this.totalInvested,
    );
  }

  @override
  String toString() =>
      'PlayerState($name, stack: $stack, bet: $currentBet, '
      'folded: $isFolded, allIn: $isAllIn)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerState &&
          other.index == index &&
          other.name == name &&
          other.stack == stack &&
          other.isFolded == isFolded &&
          other.isAllIn == isAllIn &&
          other.currentBet == currentBet &&
          other.totalInvested == totalInvested);

  @override
  int get hashCode => Object.hash(
        index,
        name,
        stack,
        isFolded,
        isAllIn,
        currentBet,
        totalInvested,
      );
}
