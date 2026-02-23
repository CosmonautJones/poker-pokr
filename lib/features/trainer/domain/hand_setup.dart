import 'package:poker_trainer/poker/models/card.dart';

/// Configuration for starting a new poker hand.
class HandSetup {
  final int playerCount;
  final double smallBlind;
  final double bigBlind;
  final double ante;
  final int dealerIndex;
  final List<String> playerNames;
  final List<double> stacks;
  final List<List<PokerCard>?>? holeCards;

  const HandSetup({
    required this.playerCount,
    required this.smallBlind,
    required this.bigBlind,
    this.ante = 0,
    this.dealerIndex = 0,
    required this.playerNames,
    required this.stacks,
    this.holeCards,
  });

  HandSetup copyWith({
    int? playerCount,
    double? smallBlind,
    double? bigBlind,
    double? ante,
    int? dealerIndex,
    List<String>? playerNames,
    List<double>? stacks,
    List<List<PokerCard>?>? holeCards,
  }) {
    return HandSetup(
      playerCount: playerCount ?? this.playerCount,
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      ante: ante ?? this.ante,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      playerNames: playerNames ?? this.playerNames,
      stacks: stacks ?? this.stacks,
      holeCards: holeCards ?? this.holeCards,
    );
  }

  /// Creates a default setup for quick start.
  factory HandSetup.defaults({int playerCount = 6}) {
    final bb = 2.0;
    return HandSetup(
      playerCount: playerCount,
      smallBlind: 1,
      bigBlind: bb,
      ante: 0,
      dealerIndex: 0,
      playerNames: List.generate(playerCount, (i) => 'Player ${i + 1}'),
      stacks: List.generate(playerCount, (_) => bb * 100),
    );
  }
}
