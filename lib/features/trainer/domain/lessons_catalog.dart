/// Hardcoded catalog of interactive poker lessons.
///
/// Pure Dart - no Flutter imports.
library;

import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:poker_trainer/poker/models/street.dart';

// ignore_for_file: non_constant_identifier_names

/// Shorthand card constructor.
PokerCard _c(Rank r, Suit s) => PokerCard.from(r, s);

/// All available lessons.
final List<Lesson> lessonsCatalog = [
  _drawingHandsLesson,
  _handProtectionLesson,
];

// ---------------------------------------------------------------------------
// Drawing Hands
// ---------------------------------------------------------------------------

final _drawingHandsLesson = Lesson(
  id: 'drawing_hands',
  title: 'Drawing Hands',
  subtitle: 'Flush draws, straight draws, and combo draws',
  introduction:
      'A drawing hand needs improvement to win. You invest chips now '
      'hoping to complete a powerful hand later. This lesson covers the '
      'most common draw types, how to count outs, and when the price is '
      'right to chase.',
  iconCodePoint: 0xe87d, // Icons.trending_up
  scenarios: [
    _flushDrawScenario,
    _oesdScenario,
    _gutshotScenario,
    _comboDrawScenario,
  ],
);

// ---- Flush Draw ----
final _flushDrawScenario = LessonScenario(
  title: 'Nut Flush Draw',
  description:
      'You hold A\u2665 Q\u2665 on the button. The flop brings two hearts '
      'giving you a flush draw with overcards.',
  heroIndex: 2, // BTN in 3-player
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 2,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Villain 2', 'Hero'],
  gameType: GameType.texasHoldem,
  holeCards: [
    [_c(Rank.jack, Suit.spades), _c(Rank.ten, Suit.clubs)],
    [_c(Rank.king, Suit.diamonds), _c(Rank.nine, Suit.diamonds)],
    [_c(Rank.ace, Suit.hearts), _c(Rank.queen, Suit.hearts)], // Hero
  ],
  flopCards: [
    _c(Rank.seven, Suit.hearts),
    _c(Rank.two, Suit.hearts),
    _c(Rank.king, Suit.clubs),
  ],
  turnCard: _c(Rank.five, Suit.spades),
  riverCard: _c(Rank.jack, Suit.hearts),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'Strong starting hand',
      body:
          'AQ suited is a premium hand, especially on the button. '
          'You have position on all opponents post-flop.',
      stat: 'Top 5% hand',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Nut flush draw',
      body:
          'Two hearts on the flop give you 9 outs to the nut flush '
          '(best possible flush). With two cards to come you have '
          'roughly 35% chance to complete it. Your overcards add '
          'extra outs if you pair the ace.',
      stat: '9 outs | ~35% by river',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'Still drawing',
      body:
          'The turn missed your flush. With one card to come, '
          'multiply outs by 2 for a quick estimate: 9 \u00d7 2 = ~18%. '
          'Check your pot odds \u2014 you need the pot to offer at least '
          '4:1 to call profitably.',
      stat: '9 outs | ~18% on river',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Flush complete!',
      body:
          'The J\u2665 completes your nut flush. Time to extract maximum '
          'value. Consider how much your opponent will call \u2014 a '
          'pot-sized bet is often best with the nuts.',
      stat: 'Nut flush \u2014 bet for value',
    ),
  ],
);

// ---- Open-Ended Straight Draw ----
final _oesdScenario = LessonScenario(
  title: 'Open-Ended Straight Draw',
  description:
      'You hold 6\u2660 7\u2666 in middle position. The flop gives you '
      'an open-ended straight draw \u2014 either end completes it.',
  heroIndex: 1,
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 0,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Hero', 'Villain 2'],
  gameType: GameType.texasHoldem,
  holeCards: [
    [_c(Rank.ace, Suit.clubs), _c(Rank.king, Suit.spades)],
    [_c(Rank.six, Suit.spades), _c(Rank.seven, Suit.diamonds)], // Hero
    [_c(Rank.queen, Suit.hearts), _c(Rank.jack, Suit.hearts)],
  ],
  flopCards: [
    _c(Rank.five, Suit.clubs),
    _c(Rank.eight, Suit.hearts),
    _c(Rank.king, Suit.spades),
  ],
  turnCard: _c(Rank.two, Suit.diamonds),
  riverCard: _c(Rank.nine, Suit.clubs),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'Suited connector',
      body:
          '67 suited connectors play well in position and multiway pots. '
          'They make straights, two-pairs, and occasional flushes.',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Open-ended straight draw',
      body:
          'With 5-8 on the board and 6-7 in hand, any 4 or any 9 '
          'completes your straight. That is 8 outs \u2014 about 31% '
          'to hit by the river.',
      stat: '8 outs | ~31% by river',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'One card left',
      body:
          'The turn bricked. 8 outs \u00d7 2 \u2248 16% on the river. '
          'A semi-bluff (bet/raise) adds fold equity \u2014 you can '
          'win by making the opponent fold OR by hitting your straight.',
      stat: '8 outs | ~16% on river',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Straight!',
      body:
          'The 9 completes your straight (5-6-7-8-9). You have the '
          'second-nut straight. Value-bet but be cautious if someone '
          'could have T-J for a higher straight.',
      stat: 'Straight made \u2014 value-bet',
    ),
  ],
);

// ---- Gutshot (Inside Straight Draw) ----
final _gutshotScenario = LessonScenario(
  title: 'Gutshot Straight Draw',
  description:
      'You hold 6\u2660 8\u2666 and flop an inside straight draw. '
      'Only one rank completes it \u2014 a much weaker draw.',
  heroIndex: 1,
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 0,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Hero', 'Villain 2'],
  gameType: GameType.texasHoldem,
  holeCards: [
    [_c(Rank.ace, Suit.hearts), _c(Rank.queen, Suit.clubs)],
    [_c(Rank.six, Suit.spades), _c(Rank.eight, Suit.diamonds)], // Hero
    [_c(Rank.ten, Suit.hearts), _c(Rank.jack, Suit.clubs)],
  ],
  flopCards: [
    _c(Rank.five, Suit.clubs),
    _c(Rank.nine, Suit.hearts),
    _c(Rank.king, Suit.spades),
  ],
  turnCard: _c(Rank.queen, Suit.diamonds),
  riverCard: _c(Rank.seven, Suit.clubs),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'Speculative hand',
      body:
          '68 offsuit is weak but playable cheaply. You are looking to '
          'hit the flop hard or fold.',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Gutshot straight draw',
      body:
          'You need exactly a 7 to complete 5-6-7-8-9. That is only '
          '4 outs \u2014 about 17% by the river. Much weaker than an '
          'open-ended draw. Only continue if the price is very cheap.',
      stat: '4 outs | ~17% by river',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'Gutshot on the turn',
      body:
          '4 outs \u00d7 2 = ~8% on the river. You need exceptional '
          'pot odds (12:1) to call. Folding is usually correct here '
          'unless the pot is huge relative to the bet.',
      stat: '4 outs | ~8% on river',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Straight hits!',
      body:
          'The 7 completes your gutshot (5-6-7-8-9). This is why '
          'implied odds matter \u2014 your hand is disguised and '
          'opponents rarely see it coming. Extract value carefully.',
      stat: 'Hidden straight \u2014 value-bet',
    ),
  ],
);

// ---- Combo Draw (Omaha) ----
final _comboDrawScenario = LessonScenario(
  title: 'Combo Draw (PLO)',
  description:
      'In Pot-Limit Omaha you hold T\u2665 J\u2665 Q\u2660 9\u2660 '
      'and flop a monster combo draw: flush draw plus wrap straight draw.',
  heroIndex: 2,
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 2,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Villain 2', 'Hero'],
  gameType: GameType.omaha,
  holeCards: [
    [
      _c(Rank.ace, Suit.clubs),
      _c(Rank.king, Suit.clubs),
      _c(Rank.five, Suit.diamonds),
      _c(Rank.four, Suit.spades),
    ],
    [
      _c(Rank.king, Suit.hearts),
      _c(Rank.queen, Suit.diamonds),
      _c(Rank.three, Suit.clubs),
      _c(Rank.two, Suit.clubs),
    ],
    [
      _c(Rank.ten, Suit.hearts),
      _c(Rank.jack, Suit.hearts),
      _c(Rank.queen, Suit.spades),
      _c(Rank.nine, Suit.spades),
    ], // Hero
  ],
  flopCards: [
    _c(Rank.eight, Suit.hearts),
    _c(Rank.seven, Suit.hearts),
    _c(Rank.king, Suit.spades),
  ],
  turnCard: _c(Rank.two, Suit.diamonds),
  riverCard: _c(Rank.six, Suit.hearts),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'Connected rundown',
      body:
          'T-J-Q-9 double-suited is a powerhouse Omaha starting hand. '
          'It makes straights, flushes, and combined draws frequently.',
      stat: 'Top 10% PLO hand',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Monster combo draw',
      body:
          'You have a flush draw in hearts (9 outs) PLUS a wrap '
          'straight draw (any 6, 9, T, J completes a straight). '
          'Combined you have 15+ outs. In Omaha, this draw is often '
          'a favorite even against top set!',
      stat: '15+ outs | ~55% equity',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'Still drawing strong',
      body:
          'The turn missed but you still have massive equity. In PLO, '
          'pot-sized bets and raises are correct with this many outs. '
          'A semi-bluff puts maximum pressure on made hands.',
      stat: '15+ outs | ~30% on river',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Flush and straight!',
      body:
          'The 6\u2665 completes both your flush AND a straight '
          '(6-7-8-9-T). In Omaha you must use exactly 2 hole cards, '
          'so your best hand is the flush (T\u2665 J\u2665 with '
          '8\u2665 7\u2665 6\u2665). Bet the pot for value.',
      stat: 'Flush \u2014 pot for value',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Hand Protection
// ---------------------------------------------------------------------------

final _handProtectionLesson = Lesson(
  id: 'hand_protection',
  title: 'Hand Protection',
  subtitle: 'Betting to deny equity and protect made hands',
  introduction:
      'When you have a strong made hand on a draw-heavy board, you need '
      'to bet to "protect" it \u2014 charge opponents the wrong price to '
      'chase their draws. If you check and let them see free cards, you '
      'give away equity. This lesson teaches when and how much to bet.',
  iconCodePoint: 0xe8e8, // Icons.shield
  scenarios: [
    _protectSetScenario,
    _protectTopPairScenario,
  ],
);

// ---- Protect Top Set ----
final _protectSetScenario = LessonScenario(
  title: 'Protect Top Set',
  description:
      'You hold K\u2663 K\u2660 and flop top set on a three-heart board. '
      'Strong hand, but very vulnerable to a flush draw.',
  heroIndex: 1,
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 0,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Hero', 'Villain 2'],
  gameType: GameType.texasHoldem,
  holeCards: [
    [_c(Rank.ace, Suit.hearts), _c(Rank.ten, Suit.hearts)],
    [_c(Rank.king, Suit.clubs), _c(Rank.king, Suit.spades)], // Hero
    [_c(Rank.jack, Suit.diamonds), _c(Rank.nine, Suit.clubs)],
  ],
  flopCards: [
    _c(Rank.king, Suit.hearts),
    _c(Rank.seven, Suit.hearts),
    _c(Rank.six, Suit.hearts),
  ],
  turnCard: _c(Rank.five, Suit.hearts),
  riverCard: _c(Rank.seven, Suit.clubs),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'Premium pair',
      body:
          'Pocket kings is the second-best starting hand. Raise for '
          'value and to thin the field.',
      stat: 'Top 1% hand',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Top set on a wet board',
      body:
          'You flopped top set \u2014 the best possible hand right now. '
          'But all three cards are hearts, meaning any opponent with a '
          'single heart has a flush draw (9 outs, ~35%). You MUST bet '
          'large (75-100% pot) to charge them the wrong price to draw.',
      stat: 'Bet 75%+ pot to protect',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'The flush completes',
      body:
          'A fourth heart hit the turn. Anyone with a single heart now '
          'has a flush. Your set is no longer ahead unless the board '
          'pairs. THIS is why protection betting on the flop matters '
          '\u2014 making opponents pay on the flop prevents this.',
      stat: 'Board pair needed \u2014 10 outs',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Full house!',
      body:
          'The board paired giving you kings full! Even though the '
          'flush got there on the turn, the river saved you. Bet for '
          'value \u2014 flush holders will often call.',
      stat: 'Full house \u2014 value-bet big',
    ),
  ],
);

// ---- Protect Top Pair ----
final _protectTopPairScenario = LessonScenario(
  title: 'Protect Top Pair',
  description:
      'You hold A\u2660 K\u2666 and flop top pair top kicker on a '
      'coordinated board with straight and flush draw possibilities.',
  heroIndex: 2,
  playerCount: 3,
  smallBlind: 1,
  bigBlind: 2,
  dealerIndex: 2,
  stacks: [200, 200, 200],
  playerNames: ['Villain 1', 'Villain 2', 'Hero'],
  gameType: GameType.texasHoldem,
  holeCards: [
    [_c(Rank.nine, Suit.hearts), _c(Rank.eight, Suit.hearts)],
    [_c(Rank.jack, Suit.clubs), _c(Rank.ten, Suit.clubs)],
    [_c(Rank.ace, Suit.spades), _c(Rank.king, Suit.diamonds)], // Hero
  ],
  flopCards: [
    _c(Rank.ace, Suit.hearts),
    _c(Rank.seven, Suit.hearts),
    _c(Rank.queen, Suit.clubs),
  ],
  turnCard: _c(Rank.three, Suit.spades),
  riverCard: _c(Rank.two, Suit.diamonds),
  tips: [
    CoachingTip(
      street: Street.preflop,
      title: 'AK \u2014 Big Slick',
      body:
          'AK is a premium hand. On the button, raise to build the pot '
          'and take initiative.',
      stat: 'Top 3% hand',
    ),
    CoachingTip(
      street: Street.flop,
      title: 'Top pair, vulnerable board',
      body:
          'You have top pair top kicker \u2014 a strong hand. But the '
          'board has A\u2665 7\u2665 (flush draw) and A-Q (straight '
          'draws with K-J, J-T). Bet 60-75% pot to deny cheap draws. '
          'Checking lets opponents realize their equity for free.',
      stat: 'Bet 60-75% pot to protect',
    ),
    CoachingTip(
      street: Street.turn,
      title: 'Blank turn \u2014 keep betting',
      body:
          'The 3\u2660 is a safe card \u2014 no draws completed. Fire '
          'another bet (50-60% pot) to keep denying equity. Opponents '
          'still drawing need to pay every street.',
      stat: 'Continue betting for protection',
    ),
    CoachingTip(
      street: Street.river,
      title: 'Clean runout \u2014 value bet',
      body:
          'No draws completed. Your top pair top kicker is likely best. '
          'A value bet of 40-50% pot targets worse aces and pairs that '
          'called the turn. Your protection bets paid off \u2014 draws '
          'either folded or paid too much.',
      stat: 'TPTK held up \u2014 thin value',
    ),
  ],
);
