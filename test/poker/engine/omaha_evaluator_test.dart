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
      // Hole: Ah, Ks, 2c, 3d  — only 1 heart (Ah) in the hole.
      // Community: Jh, Th, 9h, 8h, 4d — 4 hearts on board.
      //
      // A Hold'em-style evaluator could freely pick Ah+Jh+Th+9h+8h for a
      // flush, but Omaha requires exactly 2 from hole and 3 from community.
      // With only 1 heart in hole, no 2-hole-card combo produces 2 hearts,
      // so no flush is possible. Best hand is Ace-high (Ah+Ks + Jh,Th,9h).
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

      // Must NOT be a flush — the Omaha constraint prevents it.
      expect(best.rank, isNot(HandRank.flush));
      expect(best.rank, isNot(HandRank.straightFlush));
      // The best achievable hand is a straight: 8-9-T-J-Q? No Q available.
      // Ah+Ks + Jh,Th,9h = {A,K,J,T,9} = High Card Ace.
      // Ah+Ks + Jh,Th,8h = {A,K,J,T,8} = High Card Ace.
      // Ah+Ks + Jh,9h,8h = {A,K,J,9,8} = High Card Ace.
      // Ah+Ks + Th,9h,8h = {A,K,T,9,8} = High Card Ace.
      // Ah+Ks + Jh,Th,4d = {A,K,J,T,4} = High Card Ace.
      // All combos top out at High Card.
      expect(best.rank, HandRank.highCard);
    });

    test('Omaha flush requires 2 hole cards of that suit', () {
      // Hole: Ah, Kh, Qc, Jd — 2 hearts in hole (Ah, Kh).
      // Community: 2h, 3h, 4h, 8s, 9c — 3 hearts on board.
      //
      // Using Ah+Kh from hole + 2h+3h+4h from community = 5 hearts = flush.
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
      // Ace-high flush.
      expect(best.values.first, Rank.ace.value);
    });

    test('must use exactly 3 community cards', () {
      // Hole: Ac, Ad, Kc, Kd
      // Community: As, Ks, 2h, 3h, 4h
      //
      // Despite having AA+KK in hole, a full house is impossible because you
      // must use exactly 2 hole + 3 community.
      //
      // Best combos:
      //   Ac+Ad (hole) + As,Ks,2h = {Ac,Ad,As,Ks,2h} = Three Aces (+ K + 2)
      //   Ac+Ad (hole) + As,Ks,3h = {Ac,Ad,As,Ks,3h} = Three Aces (+ K + 3)
      //   Kc+Kd (hole) + As,Ks,2h = {Kc,Kd,Ks,As,2h} = Three Kings (+ A + 2)
      //
      // No combination yields a Full House (would need 3+2 from exactly
      // 2 hole + 3 community, but there's no pair in any community triple
      // that matches any hole pair to form the required 3+2 pattern without
      // using 3 of one rank from the combined 5).
      //
      // Best hand: Three of a Kind, Aces.
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
      // It's three aces, not a full house.
      expect(best.rank, isNot(HandRank.fullHouse));
      expect(best.description, contains('Ace'));
    });

    test('Omaha vs Hold\'em same cards different results', () {
      // Hole: Ah, 2h, 3c, 4d
      // Community: Kh, Qh, Jh, Ts, 5s
      //
      // Hold'em-style (evaluateBest with texasHoldem) treats all 9 cards as
      // a pool and picks the best 5 freely. It can use Ah+Kh+Qh+Jh + one
      // more heart? Only 2h left = Ah,Kh,Qh,Jh,2h = flush! Or even better:
      // Ah,Kh,Qh,Jh,Ts = A-K-Q-J-T = broadway straight (not flush, mixed
      // suits). Actually Ah+Kh+Qh+Jh+Ts = A,K,Q,J,T — that's a straight!
      // And Ah+Kh+Qh+Jh+2h = flush. Flush beats straight, so Hold'em = flush.
      //
      // Omaha: must use exactly 2 from hole + 3 from community.
      // Hearts in hole: Ah, 2h. Using Ah+2h + Kh,Qh,Jh = 5 hearts = flush.
      // But also check: Ah+2h + Kh,Qh,Jh is A,K,Q,J,2 = flush (A-high).
      // Or: Ah+4d + Kh,Qh,Jh = A,K,Q,J,4 — not all same suit (4d breaks it).
      // So Omaha can also make a flush here.
      //
      // Let's modify to show a real difference: use hole cards where the
      // flush is only possible in Hold'em but not Omaha.
      //
      // Hole: Ah, Ks, 3c, 4d  — only 1 heart
      // Community: Kh, Qh, Jh, Ts, 5s
      //
      // Hold'em (all 9 cards freely): can pick Ah,Kh,Qh,Jh + Ts =
      //   A,K,Q,J,T = straight (mixed suits). Or Ah,Kh,Qh,Jh,5s? Not flush.
      //   Actually Ah is a heart, Kh,Qh,Jh are hearts, but Ts is spades.
      //   Only 4 hearts available total (Ah,Kh,Qh,Jh), need 5 for flush.
      //   Best 5: Ah,Ks,Kh,Qh,Jh? No, two Ks... actually Ks and Kh are
      //   different cards, and we can use both. A,K,K,Q,J = pair of kings.
      //   Or: Ah,Kh,Qh,Jh,Ts = A,K,Q,J,T = straight!
      //   Hold'em result: Straight, Ace-high.
      //
      // Omaha: must use exactly 2 from {Ah, Ks, 3c, 4d} + 3 from community.
      //   Ah+Ks + Kh,Qh,Jh = {A,K,K,Q,J} = pair of Kings
      //   Ah+Ks + Kh,Qh,Ts = {A,K,K,Q,T} = pair of Kings
      //   Ah+Ks + Kh,Jh,Ts = {A,K,K,J,T} = pair of Kings
      //   Ah+Ks + Qh,Jh,Ts = {A,K,Q,J,T} = straight!
      //   So Omaha can also make the straight here. Hmm.
      //
      // I need a case where Hold'em gives a better hand than Omaha.
      // Use: Hole: Ah, Kc, 7d, 6d. Community: Qh, Jh, Th, 9h, 2s.
      //
      // Hold'em: freely pick best 5 from 9. Ah,Qh,Jh,Th,9h = flush (A high).
      //   Also A,K,Q,J,T = straight. Flush > straight, so Hold'em = flush.
      //
      // Omaha: must use 2 from {Ah,Kc,7d,6d} + 3 from {Qh,Jh,Th,9h,2s}.
      //   Ah+Kc + Qh,Jh,Th = {A,K,Q,J,T} = straight! (not flush, Kc breaks it)
      //   Ah+Kc + Qh,Jh,9h = {A,K,Q,J,9} = high card
      //   Ah+Kc + Qh,Th,9h = {A,K,Q,T,9} = high card
      //   Ah+Kc + Jh,Th,9h = {A,K,J,T,9} = high card
      //   Ah+7d + Qh,Jh,Th = {A,Q,J,T,7} = high card
      //   Ah+6d + ... same pattern
      //   Kc+7d + ... no good
      //   Kc+6d + ... no good
      //   7d+6d + ... no good
      //   Best Omaha hand: straight (A-high) from Ah+Kc + Qh,Jh,Th.
      //
      // Hold'em = flush (Ah,Qh,Jh,Th,9h), Omaha = straight (Ah,Kc,Qh,Jh,Th).
      // Flush > straight, so Hold'em result is strictly better!
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

      // Hold'em can freely pick Ah+Qh+Jh+Th+9h = flush.
      expect(holdEmResult.rank, HandRank.flush);
      // Omaha best is a straight: Ah+Kc from hole + Qh+Jh+Th from community.
      expect(omahaResult.rank, HandRank.straight);
      // The Hold'em result is strictly better.
      expect(holdEmResult > omahaResult, true);
    });

    test('Omaha with exactly 3 community cards (flop)', () {
      // With 4 hole + 3 community, there are C(4,2) * C(3,3) = 6 * 1 = 6
      // combinations. Each combination is exactly 2 hole + all 3 community.
      //
      // Hole: As, Ks, Qs, Js
      // Community: Ts, 9s, 2c (only 3 community cards — the flop)
      //
      // All community cards must be used (C(3,3) = 1).
      // Combos (each uses all 3 community: Ts,9s,2c):
      //   As+Ks + Ts,9s,2c = {A,K,T,9,2} all spades except 2c => not flush
      //   As+Qs + Ts,9s,2c = {A,Q,T,9,2} => not flush
      //   As+Js + Ts,9s,2c = {A,J,T,9,2} => not flush
      //   Ks+Qs + Ts,9s,2c = {K,Q,T,9,2} => not flush
      //   Ks+Js + Ts,9s,2c = {K,J,T,9,2} => not flush
      //   Qs+Js + Ts,9s,2c = {Q,J,T,9,2} => not flush (2c breaks it)
      //
      // None are flushes because 2c is a club. Best hand is high card A.
      // Actually, let's make it more interesting. Let me change community:
      //
      // Hole: As, Ks, Qh, Jd
      // Community: Ts, 9s, 8s (3 community cards)
      //
      // As+Ks + Ts,9s,8s = {As,Ks,Ts,9s,8s} = flush! (all spades)
      // As+Qh + Ts,9s,8s = {A,Q,T,9,8} = high card
      // As+Jd + Ts,9s,8s = {A,J,T,9,8} = high card. Or J,T,9,8 is 4
      //   consecutive, need 7 or Q for straight... no.
      // Ks+Qh + Ts,9s,8s = {K,Q,T,9,8} = high card (Q breaks straight)
      // Ks+Jd + Ts,9s,8s = {K,J,T,9,8} = high card. J,T,9,8 needs 7 or Q.
      // Qh+Jd + Ts,9s,8s = {Q,J,T,9,8} = straight! (8-9-T-J-Q)
      //
      // Flush > straight, so best = flush (As,Ks,Ts,9s,8s).
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
      // Set up cards so the winning combo is not the most obvious one.
      //
      // Hole: Td, Tc, 9h, 8d
      // Community: Ts, 9d, 9c, 5h, 2s
      //
      // Key combos:
      //   Td+Tc (hole) + Ts,9d,9c (comm) = {T,T,T,9,9} = Full House (Ts full of 9s)
      //   Td+Tc (hole) + Ts,9d,5h (comm) = {T,T,T,9,5} = Three Tens
      //   Td+9h (hole) + Ts,9d,9c (comm) = {T,T,9,9,9} = Full House (9s full of Ts)
      //   Tc+9h (hole) + Ts,9d,9c (comm) = {T,T,9,9,9} = Full House (9s full of Ts)
      //   9h+8d (hole) + Ts,9d,9c (comm) = {T,9,9,9,8} = Three Nines
      //   Td+8d (hole) + Ts,9d,9c (comm) = {T,T,9,9,8} = Two Pair
      //   Tc+8d (hole) + Ts,9d,9c (comm) = {T,T,9,9,8} = Two Pair
      //
      // Best hand: Full House, Tens full of Nines (Td+Tc + Ts,9d,9c).
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

      // Royal flush: Ah, Kh, Qh, Jh, Th.
      expect(result.rank, HandRank.straightFlush);
      expect(result.description, 'Royal Flush');
    });

    test('dispatches to Omaha evaluator for omaha', () {
      // Omaha: 4 hole + 5 community, must use exactly 2+3.
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

      // With 2 hearts in hole (Ah,Kh) + 3 hearts on board (Qh,Jh,Th),
      // the best hand is Ah+Kh + Qh,Jh,Th = A,K,Q,J,T all hearts =
      // straight flush (Royal Flush).
      expect(result.rank, HandRank.straightFlush);
      expect(result.description, 'Royal Flush');
    });
  });

  // -------------------------------------------------------------------------
  // determineWinners with Omaha
  // -------------------------------------------------------------------------
  group('determineWinners with Omaha', () {
    test('Omaha winner uses correct evaluation rules', () {
      // Set up a scenario where Hold'em and Omaha produce different winners.
      //
      // Community: Qh, Jh, Th, 3s, 2c
      //
      // Player A (Alice): Ah, 7c, 6d, 5s
      //   Hold'em: freely pick Ah+Qh+Jh+Th + any = flush (Ah,Qh,Jh,Th + need
      //     5th heart, but no 5th heart available; 7c,6d,5s aren't hearts).
      //     Best: Ah,Qh,Jh,Th,7c? That's not a flush. Actually:
      //     All 9 cards: Ah,7c,6d,5s,Qh,Jh,Th,3s,2c.
      //     Hearts: Ah,Qh,Jh,Th = only 4 hearts, can't make flush.
      //     Straight? A,Q,J,T... need K for broadway. 7,6,5... + ? No straight.
      //     Best: Pair? No pairs. High card A,Q,J,T,7.
      //
      //   Omaha: 2 from {Ah,7c,6d,5s} + 3 from {Qh,Jh,Th,3s,2c}.
      //     Ah+7c + Qh,Jh,Th = {A,Q,J,T,7} = high card
      //     Ah+5s + Qh,Jh,3s = {A,Q,J,5,3} = high card
      //     All combos are high card. Best: A,Q,J,T,7.
      //
      // This doesn't create a difference. Let me redesign.
      //
      // Better scenario: one player's strength comes from using 3+ hole cards
      // (which Hold'em allows but Omaha forbids), while the other player has a
      // hand that works under Omaha rules.
      //
      // Community: Kh, Qh, 8c, 4d, 3s
      //
      // Player A: Ah, Jh, Th, 2c  (3 hearts in hole)
      //   Hold'em: can use Ah+Kh+Qh+Jh+Th = flush (5 hearts). But wait,
      //     Kh and Qh are on the board, and Ah,Jh,Th are in hole. That's
      //     3 hole + 2 community. In Hold'em with 4 hole cards, the evaluator
      //     picks the best 5 from all 9, so this flush is valid.
      //   Omaha: must use exactly 2 from {Ah,Jh,Th,2c} + 3 from community.
      //     Ah+Jh + Kh,Qh,8c = {A,K,Q,J,8} — 4 hearts + 1 club, not flush.
      //     Ah+Jh + Kh,Qh,4d = {A,K,Q,J,4} — 4 hearts + 1 diamond, not flush.
      //     Ah+Jh + Kh,Qh,3s = {A,K,Q,J,3} — 4 hearts + 1 spade, not flush.
      //     Ah+Th + Kh,Qh,8c = {A,K,Q,T,8} — 4 hearts + 1 club, not flush.
      //     Ah+Jh + Kh,8c,4d = {A,K,J,8,4} = high card.
      //     Best Omaha for A: A,K,Q,J,8 = High Card Ace.
      //
      // Player B: Kc, Kd, 5s, 6s
      //   Hold'em: Kc+Kd+Kh + Qh + 8c = Three Kings.
      //     Or is pair of K better? Kc+Kd+Kh = three of a kind Kings. That's
      //     what we'd get. Three of a kind > high card.
      //   Omaha: must use 2 from {Kc,Kd,5s,6s} + 3 from {Kh,Qh,8c,4d,3s}.
      //     Kc+Kd + Kh,Qh,8c = {K,K,K,Q,8} = Three Kings.
      //     Kc+Kd + Kh,Qh,4d = {K,K,K,Q,4} = Three Kings.
      //     Best Omaha for B: Three of a Kind, Kings.
      //
      // Hold'em: A gets flush (better than B's three-of-a-kind).
      //   Wait, A gets flush only if the evaluator for Hold'em with 4 hole
      //   cards uses all 9 cards. Let's verify: evaluateBestHand merges all
      //   cards and picks best 5 from 9. A's 9 cards include Ah,Jh,Th,2c +
      //   Kh,Qh,8c,4d,3s. Best 5: Ah,Kh,Qh,Jh,Th = flush (A-high) ✓.
      //   B's 9 cards: Kc,Kd,5s,6s + Kh,Qh,8c,4d,3s. Best 5:
      //   Kc,Kd,Kh,Qh,8c = Three Kings.
      //   Flush > Three of a Kind, so Hold'em winner = A.
      //
      // Omaha: A gets High Card (Ace), B gets Three Kings.
      //   Three of a Kind > High Card, so Omaha winner = B.
      //
      // Under Hold'em rules A wins; under Omaha rules B wins.

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

      // Under Hold'em rules: Alice wins with a flush.
      final holdEmWinners = HandEvaluator.determineWinners(
        players,
        community,
        [0, 1],
        gameType: GameType.texasHoldem,
      );
      expect(holdEmWinners, [0]); // Alice

      // Under Omaha rules: Bob wins with three kings.
      final omahaWinners = HandEvaluator.determineWinners(
        players,
        community,
        [0, 1],
        gameType: GameType.omaha,
      );
      expect(omahaWinners, [1]); // Bob
    });

    test('determineWinners with < 3 community cards returns all eligible', () {
      // When there are fewer than 3 community cards (e.g. preflop all-in
      // before any board cards are dealt), the evaluator cannot determine a
      // winner and should return all eligible players.
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

      // Only 2 community cards — not enough for evaluation.
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

      // Both players should be returned since evaluation is not possible.
      expect(winners.length, 2);
      expect(winners, containsAll([0, 1]));
    });
  });
}
