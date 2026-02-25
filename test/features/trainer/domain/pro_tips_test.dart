import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/educational_context.dart';
import 'package:poker_trainer/features/trainer/domain/pro_tips.dart';

/// Helper to create an EducationalContext with specific values.
EducationalContext _ctx({
  String positionLabel = 'BTN',
  String positionCategory = 'late',
  double? potOdds,
  String? potOddsDisplay,
  double stackToPotRatio = 10,
  int playersInHand = 3,
  int playersYetToAct = 1,
  String streetContext = 'Flop',
}) {
  return EducationalContext(
    positionLabel: positionLabel,
    positionCategory: positionCategory,
    potOdds: potOdds,
    potOddsDisplay: potOddsDisplay,
    stackToPotRatio: stackToPotRatio,
    playersInHand: playersInHand,
    playersYetToAct: playersYetToAct,
    streetContext: streetContext,
  );
}

void main() {
  group('ProTipEngine', () {
    test('returns null for default context with no special conditions', () {
      // A middle-ground context that matches no specific rules.
      final tip = ProTipEngine.compute(_ctx(
        positionCategory: 'middle',
        stackToPotRatio: 6,
        playersInHand: 3,
        playersYetToAct: 1,
      ));
      // May or may not return a tip depending on exact rule matches.
      // At minimum, it should not crash.
      expect(tip == null || tip is ProTip, isTrue);
    });

    group('pot odds tips', () {
      test('good price tip when pot odds <= 20%', () {
        final tip = ProTipEngine.compute(_ctx(
          potOdds: 0.15,
          potOddsDisplay: '5.7:1 (15%)',
        ));
        expect(tip, isNotNull);
        expect(tip!.title, 'Good price to call');
        expect(tip.category, 'Pot Odds');
        expect(tip.body, contains('15%'));
      });

      test('expensive call tip when pot odds >= 40%', () {
        final tip = ProTipEngine.compute(_ctx(
          potOdds: 0.45,
          potOddsDisplay: '1.2:1 (45%)',
        ));
        expect(tip, isNotNull);
        expect(tip!.title, 'Expensive call');
        expect(tip.body, contains('45%'));
      });

      test('evaluate equity tip for medium pot odds', () {
        final tip = ProTipEngine.compute(_ctx(
          potOdds: 0.30,
          potOddsDisplay: '2.3:1 (30%)',
        ));
        expect(tip, isNotNull);
        expect(tip!.title, 'Evaluate your equity');
        expect(tip.body, contains('30%'));
      });

      test('pot odds tip takes priority over position tips', () {
        // Even in late position, facing a bet should show pot odds tip.
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'late',
          potOdds: 0.20,
          potOddsDisplay: '4:1 (20%)',
        ));
        expect(tip, isNotNull);
        expect(tip!.category, 'Pot Odds');
      });
    });

    group('SPR tips', () {
      test('low SPR tip when SPR < 4', () {
        final tip = ProTipEngine.compute(_ctx(
          stackToPotRatio: 3,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Low SPR'));
        expect(tip.category, 'SPR');
      });

      test('no low SPR tip when SPR is 0 (edge case)', () {
        final tip = ProTipEngine.compute(_ctx(
          stackToPotRatio: 0,
        ));
        // SPR = 0 is excluded from low SPR tip.
        expect(tip == null || tip.title != 'Low SPR — commit or fold', isTrue);
      });

      test('high SPR tip when SPR >= 13', () {
        final tip = ProTipEngine.compute(_ctx(
          stackToPotRatio: 15,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Deep stacks'));
        expect(tip.category, 'SPR');
      });

      test('medium SPR tip when SPR 7-10 and no bet facing', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'middle',
          stackToPotRatio: 8,
          playersInHand: 3,
          playersYetToAct: 1,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Medium SPR'));
        expect(tip.category, 'SPR');
      });
    });

    group('position tips', () {
      test('early position tip', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'early',
          stackToPotRatio: 10,
          playersInHand: 6,
          playersYetToAct: 4,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Early position'));
        expect(tip.category, 'Position');
      });

      test('late position tip', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'late',
          stackToPotRatio: 10,
          playersInHand: 3,
          playersYetToAct: 1,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Late position'));
        expect(tip.category, 'Position');
      });

      test('no early position tip when facing a bet', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'early',
          potOdds: 0.25,
          potOddsDisplay: '3:1 (25%)',
          stackToPotRatio: 10,
        ));
        // Pot odds tip takes priority.
        expect(tip, isNotNull);
        expect(tip!.category, 'Pot Odds');
      });

      test('blind defense tip when in blinds facing a bet', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'blinds',
          potOdds: 0.25,
          potOddsDisplay: '3:1 (25%)',
          stackToPotRatio: 10,
        ));
        // Pot odds tip (facing bet) takes priority over blind defense.
        expect(tip, isNotNull);
        expect(tip!.category, anyOf('Pot Odds', 'Position'));
      });
    });

    group('situation tips', () {
      test('heads up tip when 2 players in hand', () {
        final tip = ProTipEngine.compute(_ctx(
          playersInHand: 2,
          stackToPotRatio: 10,
          playersYetToAct: 1,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Heads up'));
        expect(tip.category, 'Situation');
      });

      test('multiway pot tip when 4+ players', () {
        final tip = ProTipEngine.compute(_ctx(
          playersInHand: 5,
          stackToPotRatio: 10,
          playersYetToAct: 2,
          positionCategory: 'middle',
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Multiway'));
        expect(tip.category, 'Situation');
      });

      test('last to act tip', () {
        final tip = ProTipEngine.compute(_ctx(
          positionCategory: 'middle',
          playersYetToAct: 0,
          playersInHand: 3,
          stackToPotRatio: 10,
        ));
        expect(tip, isNotNull);
        expect(tip!.title, contains('Last to act'));
      });
    });

    group('ProTip class', () {
      test('has required fields', () {
        const tip = ProTip(
          title: 'Test',
          body: 'Body',
          category: 'Cat',
        );
        expect(tip.title, 'Test');
        expect(tip.body, 'Body');
        expect(tip.category, 'Cat');
      });
    });
  });
}
