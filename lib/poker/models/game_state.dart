/// Immutable game state for a single poker hand.
///
/// Pure Dart - no Flutter imports.
library;

import 'card.dart';
import 'game_type.dart';
import 'street.dart';
import 'action.dart';
import 'player.dart';
import 'pot.dart';

class GameState {
  final List<PlayerState> players;
  final List<PokerCard> communityCards;
  final Deck deck;
  final Street street;
  final double pot;
  final List<SidePot> sidePots;
  final int currentPlayerIndex;
  final double currentBet;
  final double lastRaiseSize;
  final int? lastAggressorIndex;
  final List<PokerAction> actionHistory;
  final double smallBlind;
  final double bigBlind;
  final double ante;
  final int dealerIndex;
  final bool isHandComplete;
  final List<int>? winnerIndices;
  final int playersActedThisStreet;

  /// Index into [actionHistory] where the current street's actions begin.
  /// Preflop starts at 0. Updated when streets advance.
  final int streetStartActionIndex;

  /// Per-player hand description at showdown (e.g. {0: "Pair of Kings"}).
  /// Only populated when the hand reaches showdown (not when won by fold).
  final Map<int, String> handDescriptions;

  /// The game variant being played.
  final GameType gameType;

  /// Straddle amount (0 if no straddle).
  final double straddle;

  /// Index of the player who posted the straddle (null if no straddle).
  final int? straddlePlayerIndex;

  const GameState({
    required this.players,
    this.communityCards = const [],
    required this.deck,
    this.street = Street.preflop,
    this.pot = 0,
    this.sidePots = const [],
    this.currentPlayerIndex = 0,
    this.currentBet = 0,
    this.lastRaiseSize = 0,
    this.lastAggressorIndex,
    this.actionHistory = const [],
    required this.smallBlind,
    required this.bigBlind,
    this.ante = 0,
    required this.dealerIndex,
    this.isHandComplete = false,
    this.winnerIndices,
    this.playersActedThisStreet = 0,
    this.streetStartActionIndex = 0,
    this.handDescriptions = const {},
    this.gameType = GameType.texasHoldem,
    this.straddle = 0,
    this.straddlePlayerIndex,
  });

  /// All players who have not folded (still eligible for pots).
  List<PlayerState> get activePlayers =>
      players.where((p) => !p.isFolded).toList();

  /// Players who have not folded and are not all-in (can still act).
  List<PlayerState> get activeNonAllInPlayers =>
      players.where((p) => p.isActive).toList();

  /// Number of players at the table.
  int get playerCount => players.length;

  /// Whether this is a heads-up (2-player) game.
  bool get isHeadsUp => playerCount == 2;

  GameState copyWith({
    List<PlayerState>? players,
    List<PokerCard>? communityCards,
    Deck? deck,
    Street? street,
    double? pot,
    List<SidePot>? sidePots,
    int? currentPlayerIndex,
    double? currentBet,
    double? lastRaiseSize,
    int? Function()? lastAggressorIndex,
    List<PokerAction>? actionHistory,
    double? smallBlind,
    double? bigBlind,
    double? ante,
    int? dealerIndex,
    bool? isHandComplete,
    List<int>? Function()? winnerIndices,
    int? playersActedThisStreet,
    int? streetStartActionIndex,
    Map<int, String>? handDescriptions,
    GameType? gameType,
    double? straddle,
    int? Function()? straddlePlayerIndex,
  }) {
    return GameState(
      players: players ?? this.players,
      communityCards: communityCards ?? this.communityCards,
      deck: deck ?? this.deck,
      street: street ?? this.street,
      pot: pot ?? this.pot,
      sidePots: sidePots ?? this.sidePots,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentBet: currentBet ?? this.currentBet,
      lastRaiseSize: lastRaiseSize ?? this.lastRaiseSize,
      lastAggressorIndex: lastAggressorIndex != null
          ? lastAggressorIndex()
          : this.lastAggressorIndex,
      actionHistory: actionHistory ?? this.actionHistory,
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      ante: ante ?? this.ante,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      isHandComplete: isHandComplete ?? this.isHandComplete,
      winnerIndices:
          winnerIndices != null ? winnerIndices() : this.winnerIndices,
      playersActedThisStreet:
          playersActedThisStreet ?? this.playersActedThisStreet,
      streetStartActionIndex:
          streetStartActionIndex ?? this.streetStartActionIndex,
      handDescriptions: handDescriptions ?? this.handDescriptions,
      gameType: gameType ?? this.gameType,
      straddle: straddle ?? this.straddle,
      straddlePlayerIndex: straddlePlayerIndex != null
          ? straddlePlayerIndex()
          : this.straddlePlayerIndex,
    );
  }

  @override
  String toString() =>
      'GameState(street: ${street.name}, pot: $pot, '
      'currentBet: $currentBet, currentPlayer: $currentPlayerIndex, '
      'community: $communityCards, complete: $isHandComplete, '
      'gameType: ${gameType.name}, straddle: $straddle)';
}
