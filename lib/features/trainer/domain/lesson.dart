/// Domain models for interactive poker lessons.
///
/// Pure Dart - no Flutter imports.
library;

import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// A single coaching tip shown during lesson play.
class CoachingTip {
  /// The street at which this tip is shown.
  final Street street;

  /// Short heading.
  final String title;

  /// Explanation body (1-3 sentences).
  final String body;

  /// Quick-reference stat (e.g. "9 outs | ~35%").
  final String? stat;

  const CoachingTip({
    required this.street,
    required this.title,
    required this.body,
    this.stat,
  });
}

/// A single interactive scenario within a lesson.
///
/// Defines the exact cards so the player experiences a specific draw type.
class LessonScenario {
  /// Short label (e.g. "Nut Flush Draw on the Flop").
  final String title;

  /// Brief description of the situation.
  final String description;

  /// Which player index the user controls (hero).
  final int heroIndex;

  /// Hole cards for every player (outer list = players).
  final List<List<PokerCard>> holeCards;

  /// Pre-determined community cards: flop (3), turn (1), river (1).
  final List<PokerCard> flopCards;
  final PokerCard turnCard;
  final PokerCard riverCard;

  /// Number of players.
  final int playerCount;

  /// Blinds.
  final double smallBlind;
  final double bigBlind;

  /// Starting stacks for each player.
  final List<double> stacks;

  /// Dealer button position.
  final int dealerIndex;

  /// Game variant.
  final GameType gameType;

  /// Coaching tips keyed to streets.
  final List<CoachingTip> tips;

  /// Player names.
  final List<String> playerNames;

  const LessonScenario({
    required this.title,
    required this.description,
    required this.heroIndex,
    required this.holeCards,
    required this.flopCards,
    required this.turnCard,
    required this.riverCard,
    required this.playerCount,
    required this.smallBlind,
    required this.bigBlind,
    required this.stacks,
    required this.dealerIndex,
    required this.gameType,
    required this.tips,
    required this.playerNames,
  });

  /// All community cards in order.
  List<PokerCard> get allCommunityCards => [...flopCards, turnCard, riverCard];

  /// Build a [Deck] pre-stacked so that community cards come out in the
  /// correct order. The deck must NOT contain any hole cards.
  Deck buildStackedDeck() {
    final holeCardValues = <int>{};
    for (final hand in holeCards) {
      for (final card in hand) {
        holeCardValues.add(card.value);
      }
    }

    final communityValues = <int>{
      ...flopCards.map((c) => c.value),
      turnCard.value,
      riverCard.value,
    };

    final allExcluded = {...holeCardValues, ...communityValues};

    // Filler = every card not used as a hole card or community card.
    final filler = <PokerCard>[
      for (int i = 0; i < 52; i++)
        if (!allExcluded.contains(i)) PokerCard(i),
    ];

    // Need 3 burn cards.
    final burn1 = filler.removeLast();
    final burn2 = filler.removeLast();
    final burn3 = filler.removeLast();

    // Deck deals via removeLast(), so the LAST element is dealt first.
    // Dealing order: burn1, flop[0], flop[1], flop[2], burn2, turn, burn3, river
    return Deck.fromCards([
      ...filler,
      riverCard,
      burn3,
      turnCard,
      burn2,
      flopCards[2],
      flopCards[1],
      flopCards[0],
      burn1,
    ]);
  }
}

/// A lesson containing one or more interactive scenarios on a topic.
class Lesson {
  /// Unique identifier.
  final String id;

  /// Display title (e.g. "Drawing Hands").
  final String title;

  /// Short subtitle (e.g. "Flush draws, straight draws, and more").
  final String subtitle;

  /// Longer introduction shown before play.
  final String introduction;

  /// Icon codepoint (Material Icons).
  final int iconCodePoint;

  /// Scenarios the user can play through.
  final List<LessonScenario> scenarios;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.introduction,
    required this.iconCodePoint,
    required this.scenarios,
  });
}
