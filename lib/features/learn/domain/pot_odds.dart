/// Pot-odds reference data + a tiny decision helper.
///
/// Pure Dart - no Flutter imports. Helps players translate "X to call into
/// a Y pot" into the equity threshold needed to break even.
library;

import 'dart:math' as math;

/// Result of a pot-odds calculation.
class PotOdds {
  /// Total pot the player is calling into (already includes any bet they
  /// must call).
  final double potBeforeCall;

  /// Amount the player must call to continue.
  final double toCall;

  /// Equity needed to break even on the call, expressed as 0.0–1.0.
  final double breakEvenEquity;

  /// Pot-odds ratio, e.g. 3.0 means "3 to 1" (need to win 1 in 4 = 25%).
  final double ratio;

  const PotOdds({
    required this.potBeforeCall,
    required this.toCall,
    required this.breakEvenEquity,
    required this.ratio,
  });

  /// Human-readable form like "3.0 : 1".
  String get ratioLabel => '${ratio.toStringAsFixed(1)} : 1';

  /// Break-even equity as a percent string like "25.0%".
  String get equityPercentLabel =>
      '${(breakEvenEquity * 100).toStringAsFixed(1)}%';
}

/// Compute the equity threshold required to make calling break-even.
///
/// Formula: equity = call / (pot + call)
///
/// [potBeforeCall] is the total pot you're calling into (including the
/// villain's bet that you have to match). [toCall] is the additional chips
/// you must put in to continue.
PotOdds computePotOdds({
  required double potBeforeCall,
  required double toCall,
}) {
  if (toCall <= 0 || potBeforeCall < 0) {
    return PotOdds(
      potBeforeCall: math.max(0, potBeforeCall),
      toCall: math.max(0, toCall),
      breakEvenEquity: 0,
      ratio: 0,
    );
  }
  final totalAfterCall = potBeforeCall + toCall;
  final equity = toCall / totalAfterCall;
  final ratio = potBeforeCall / toCall;
  return PotOdds(
    potBeforeCall: potBeforeCall,
    toCall: toCall,
    breakEvenEquity: equity,
    ratio: ratio,
  );
}

/// A single row in the canonical pot-odds quick-reference table.
class PotOddsRow {
  /// Bet sizing as a fraction of the pot (e.g. 0.5 = half pot).
  final double betFractionOfPot;

  /// Display label for the bet sizing column.
  final String betLabel;

  /// Resulting equity threshold (0.0–1.0).
  final double breakEvenEquity;

  /// "X : 1" ratio.
  final String ratioLabel;

  /// Common scenario hint.
  final String scenarioHint;

  const PotOddsRow({
    required this.betFractionOfPot,
    required this.betLabel,
    required this.breakEvenEquity,
    required this.ratioLabel,
    required this.scenarioHint,
  });

  String get equityPercentLabel =>
      '${(breakEvenEquity * 100).toStringAsFixed(1)}%';
}

/// Canonical pot-odds reference table — the bet sizes pros memorize.
///
/// All rows assume the pot before the bet is "1 pot" and the villain bets
/// the listed fraction. The break-even equity is `bet / (pot + 2*bet)`.
class PotOddsReference {
  PotOddsReference._();

  static final List<PotOddsRow> rows = [
    _row(0.25, '¼ pot', 'Small probe / blocker bet — call wide'),
    _row(0.33, '⅓ pot', 'Cheap bluff catcher spot'),
    _row(0.50, '½ pot', 'Most common c-bet sizing'),
    _row(0.66, '⅔ pot', 'Standard value-bet sizing'),
    _row(0.75, '¾ pot', 'Polarised value range'),
    _row(1.00, 'Pot', 'Polarised — strong value or bluff'),
    _row(1.50, '1.5× pot', 'Overbet — narrow range'),
    _row(2.00, '2× pot', 'Big overbet — usually nuts or bluff'),
  ];

  static PotOddsRow _row(double frac, String label, String hint) {
    // pot before bet = 1
    // bet = frac
    // total after villain bet = 1 + frac
    // pot to call into = 1 + frac
    // toCall = frac
    // breakEven = frac / (1 + 2*frac)
    final breakEven = frac / (1 + 2 * frac);
    final ratio = (1 + frac) / frac;
    return PotOddsRow(
      betFractionOfPot: frac,
      betLabel: label,
      breakEvenEquity: breakEven,
      ratioLabel: '${ratio.toStringAsFixed(2)} : 1',
      scenarioHint: hint,
    );
  }

  /// Common quick-math shortcut: "rule of 2 and 4".
  ///
  /// On the flop with two cards to come, multiply outs by ~4 to estimate
  /// equity %. On the turn with one card to come, multiply by ~2.
  /// Returns approximate equity (0.0–1.0).
  static double ruleOfTwoAndFour({
    required int outs,
    required bool flopWithTwoToCome,
  }) {
    final mult = flopWithTwoToCome ? 4 : 2;
    final pct = (outs * mult).clamp(0, 100);
    return pct / 100.0;
  }
}
