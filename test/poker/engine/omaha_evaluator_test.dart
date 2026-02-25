import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/hand_evaluator.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:poker_trainer/poker/models/player.dart';

PokerCard c(Rank rank, Suit suit) => PokerCard.from(rank, suit);

void main() {
  // -------------------------------------------------------------------------
  // evaluateBestHandOmaha
  // -------------------------------------------------------------------------
  group('evaluateBestHandOmaha', () {
    test('must use exactly 2 hole cards - flush test', () {
      // Hole: Ah, Ks, 2c, 3d  -- only 1 heart (Ah) in the hole.
      // Community: Jh, Th, 9h, 8h, 4d  -- 4 hearts on board.
      //
      // A Hold'em-style evaluator could freely pick Ah+Jh+Th+9h+8h for a
      // flush, but Omaha requires exactly 2 from hole and 3 from community.
      // With only 1 heart in hole, no 2-hole-card combo yields 2 hearts,
      // so no flush is possible. Best hand: Ah+Ks + Jh,Th,9h = A,K,J,T,9
      // = High Card, Ace.
      final hole = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.spades),
        c(Rank.two, Suit.clubs),
        c(Rank.three, Suit.diamonds),
      ];
      final community = [
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.hearts),
        c(Rank.nine, Suit.hearts),
        c(Rank.eight, Suit.hearts),
        c(Rank.four, Suit.diamonds),
      ];

      final best = HandEvaluator.evaluateBestHandOmaha(hole, community);

      expect(best.rank, isNot(HandRank.flush));
      expect(best.rank, isNot(HandRank.straightFlush));
      expect(best.rank, HandRank.highCard);
    });

    test('Omaha flush requires 2 hole cards of that suit', () {
      // Hole: Ah, Kh, Qc, Jd  -- 2 hearts in hole (Ah, Kh).
      // Community: 2h, 3h, 4h, 8s, 9c  -- 3 hearts on board.
      //
      // Ah+Kh from hole + 2h+3h+4h from community = 5 hearts = Ace-high flush.
      final hole = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.clubs),
        c(Rank.jack, Suit.diamonds),
      ];
      final community = [
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.hearts),
        c(Rank.four, Suit.hearts),
        c(Rank.eight, Suit.spades),
        c(Rank.nine, Suit.clubs),
      ];

      final best = HandEvaluator.evaluateBestHandOmaha(hole, community);

      expect(best.rank, HandRank.flush);
      expect(best.values.first, Rank.ace.value);
    });

    test('must use exactly 3 community cards', () {
      // Hole: Ac, Ad, Kc, Kd
      // Community: As, Ks, 2h, 3h, 4h
      //
      // Despite having AA+KK in hole, a full house is impossible because
      // exactly 2 hole + 3 community must be used.
      //
      // Best combo: Ac+Ad + As,Ks,Xh = Three Aces (+ K kicker).
      // Cannot form a full house: to get AAA+KK, you'd need 2 aces from hole
      // + 1 ace + 2 kings from community, but community only has 1 king (Ks).
      // To get KKK+AA, you'd need 2 kings from hole + 1 king + 2 aces from
      // community, but community only has 1 ace (As).
      final hole = [
        c(Rank.ace, Suit.clubs),
        c(Rank.ace, Suit.diamonds),
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
      ];
      final community = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.spades),
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.hearts),
        c(Rank.four, Suit.hearts),
      ];

      final best = HandEvaluator.evaluateBestHandOmaha(hole, community);

      expect(best.rank, HandRank.threeOfAKind);
      expect(best.rank, isNot(HandRank.fullHouse));
      expect(best.description, contains('Ace'));
    });

    test('Omaha vs Hold\'em same cards different results', () {
      // Hole: Ah, Kc, 7d, 6d
      // Community: Qh, Jh, Th, 9h, 2s
      //
      // Hold'em (best 5 from all 9 freely):
      //   Ah+Qh+Jh+Th+9h = Ace-high heart flush.
      //
      // Omaha (exactly 2 hole + 3 community):
      //   Ah+Kc + Qh,Jh,Th = {A,K,Q,J,T} = Ace-high straight (not a flush
      //   because Kc is a club). No other combo beats a straight.
      //
      // Hold'em = Flush; Omaha = Straight. Flush > Straight.
      final hole = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.clubs),
        c(Rank.seven, Suit.diamonds),
        c(Rank.six, Suit.diamonds),
      ];
      final community = [
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.hearts),
        c(Rank.nine, Suit.hearts),
        c(Rank.two, Suit.spades),
      ];

      final holdEmResult = HandEvaluator.evaluateBest(
        hole,
        community,
        GameType.texasHoldem,
      );
      final omahaResult = HandEvaluator.evaluateBest(
        hole,
        community,
        GameType.omaha,
      );

      expect(holdEmResult.rank, HandRank.flush);
      expect(omahaResult.rank, HandRank.straight);
      expect(holdEmResult > omahaResult, true);
    });

    test('Omaha with exactly 3 community cards (flop)', () {
      // 4 hole + 3 community = C(4,2) * C(3,3) = 6 * 1 = 6 combinations.
      // Each uses all 3 community cards.
      //
      // Hole: As, Ks, Qh, Jd
      // Community: Ts, 9s, 8s
      //
      // As+Ks + Ts,9s,8s = all spades = Ace-high flush.
      // Qh+Jd + Ts,9s,8s = Q,J,T,9,8 = straight (but flush beats straight).
      final hole = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.diamonds),
      ];
      final community = [
        c(Rank.ten, Suit.spades),
        c(Rank.nine, Suit.spades),
        c(Rank.eight, Suit.spades),
      ];

      final best = HandEvaluator.evaluateBestHandOmaha(hole, community);

      expect(best.rank, HandRank.flush);
      expect(best.values.first, Rank.ace.value);
    });

    test('Omaha best hand from 60 combinations', () {
      // 4 hole + 5 community = C(4,2)*C(5,3) = 6*10 = 60 combinations.
      //
      // Hole: Td, Tc, 9h, 8d
      // Community: Ts, 9d, 9c, 5h, 2s
      //
      // The winning combo is Td+Tc (hole) + Ts,9d,9c (community)
      // = {T,T,T,9,9} = Full House, Tens full of Nines.
      //
      // Other notable combos produce only Three of a Kind or Two Pair,
      // so the full house wins across all 60 combinations.
      final hole = [
        c(Rank.ten, Suit.diamonds),
        c(Rank.ten, Suit.clubs),
        c(Rank.nine, Suit.hearts),
        c(Rank.eight, Suit.diamonds),
      ];
      final community = [
        c(Rank.ten, Suit.spades),
        c(Rank.nine, Suit.diamonds),
        c(Rank.nine, Suit.clubs),
        c(Rank.five, Suit.hearts),
        c(Rank.two, Suit.spades),
      ];

      final best = HandEvaluator.evaluateBestHandOmaha(hole, community);

      expect(best.rank, HandRank.fullHouse);
      expect(best.description, 'Tens full of Nines');
    });
  });

  // -------------------------------------------------------------------------
  // evaluateBest dispatch
  // -------------------------------------------------------------------------
  group('evaluateBest dispatch', () {
    test('dispatches to Hold\'em evaluator for texasHoldem', () {
      // Standard Hold'em: 2 hole + 5 community, best 5 from all 7.
      final hole = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.hearts),
      ];
      final community = [
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.hearts),
        c(Rank.two, Suit.clubs),
        c(Rank.three, Suit.diamonds),
      ];

      final result = HandEvaluator.evaluateBest(
        hole,
        community,
        GameType.texasHoldem,
      );

      expect(result.rank, HandRank.straightFlush);
      expect(result.description, 'Royal Flush');
    });

    test('dispatches to Omaha evaluator for omaha', () {
      // Omaha: 4 hole + 5 community, must use exactly 2 hole + 3 community.
      // Ah+Kh from hole + Qh+Jh+Th from community = Royal Flush.
      final hole = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.clubs),
        c(Rank.jack, Suit.diamonds),
      ];
      final community = [
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.hearts),
        c(Rank.two, Suit.clubs),
        c(Rank.three, Suit.diamonds),
      ];

      final result = HandEvaluator.evaluateBest(
        hole,
        community,
        GameType.omaha,
      );

      expect(result.rank, HandRank.straightFlush);
      expect(result.description, 'Royal Flush');
    });
  });

  // -------------------------------------------------------------------------
  // determineWinners with Omaha
  // -------------------------------------------------------------------------
  group('determineWinners with Omaha', () {
    test('Omaha winner uses correct evaluation rules', () {
      // Community: Kh, Qh, 8c, 4d, 3s
      //
      // Player A (Alice): Ah, Jh, Th, 2c  -- 3 hearts in hole.
      //   Hold'em: picks best 5 from all 9 freely. Ah+Kh+Qh+Jh+Th = flush.
      //   Omaha: must use exactly 2 hole + 3 community. With only 2 hearts
      //     from hole + at most 2 hearts from community = 4 hearts total
      //     (never 5). Best: Ah+Jh + Kh,Qh,8c = {A,K,Q,J,8} = High Card.
      //
      // Player B (Bob): Kc, Kd, 5s, 6s
      //   Hold'em: Kc+Kd+Kh = Three Kings (weaker than Alice's flush).
      //   Omaha: Kc+Kd + Kh,Qh,8c = Three Kings (beats Alice's High Card).
      //
      // Hold'em winner: Alice (flush > three of a kind).
      // Omaha winner:   Bob   (three of a kind > high card).
      final community = [
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.hearts),
        c(Rank.eight, Suit.clubs),
        c(Rank.four, Suit.diamonds),
        c(Rank.three, Suit.spades),
      ];

      final playerA = PlayerState(
        index: 0,
        name: 'Alice',
        stack: 100,
        holeCards: [
          c(Rank.ace, Suit.hearts),
          c(Rank.jack, Suit.hearts),
          c(Rank.ten, Suit.hearts),
          c(Rank.two, Suit.clubs),
        ],
      );

      final playerB = PlayerState(
        index: 1,
        name: 'Bob',
        stack: 100,
        holeCards: [
          c(Rank.king, Suit.clubs),
          c(Rank.king, Suit.diamonds),
          c(Rank.five, Suit.spades),
          c(Rank.six, Suit.spades),
        ],
      );

      final players = [playerA, playerB];

      // Hold'em: Alice wins with a flush.
      final holdEmWinners = HandEvaluator.determineWinners(
        players,
        community,
        [0, 1],
        gameType: GameType.texasHoldem,
      );
      expect(holdEmWinners, [0]);

      // Omaha: Bob wins with three kings.
      final omahaWinners = HandEvaluator.determineWinners(
        players,
        community,
        [0, 1],
        gameType: GameType.omaha,
      );
      expect(omahaWinners, [1]);
    });

    test('determineWinners with < 3 community cards returns all eligible', () {
      // When fewer than 3 community cards are available (e.g. preflop all-in),
      // hand evaluation is not possible and all eligible players are returned.
      final players = [
        PlayerState(
          index: 0,
          name: 'Alice',
          stack: 100,
          holeCards: [
            c(Rank.ace, Suit.hearts),
            c(Rank.king, Suit.hearts),
            c(Rank.queen, Suit.hearts),
            c(Rank.jack, Suit.hearts),
          ],
        ),
        PlayerState(
          index: 1,
          name: 'Bob',
          stack: 100,
          holeCards: [
            c(Rank.two, Suit.clubs),
            c(Rank.three, Suit.clubs),
            c(Rank.four, Suit.clubs),
            c(Rank.five, Suit.clubs),
          ],
        ),
      ];

      // Only 2 community cards -- not enough for evaluation.
      final community = [
        c(Rank.seven, Suit.spades),
        c(Rank.eight, Suit.spades),
      ];

      final winners = HandEvaluator.determineWinners(
        players,
        community,
        [0, 1],
        gameType: GameType.omaha,
      );

      expect(winners.length, 2);
      expect(winners, containsAll([0, 1]));
    });
  });
}
