/// Contextual pro tips computed from game state and educational context.
///
/// Pure Dart - no Flutter imports.
library;

import 'package:poker_trainer/features/trainer/domain/educational_context.dart';

class ProTip {
  /// Short title for the tip.
  final String title;

  /// The tip body (1-2 sentences).
  final String body;

  /// Category label for styling.
  final String category;

  const ProTip({
    required this.title,
    required this.body,
    required this.category,
  });
}

class ProTipEngine {
  ProTipEngine._();

  /// Compute the most relevant pro tip for the current situation.
  ///
  /// Returns `null` if no tip applies (e.g. hand is complete).
  static ProTip? compute(EducationalContext ctx) {
    // Collect all applicable tips, ordered by priority (first match wins).
    for (final rule in _rules) {
      final tip = rule(ctx);
      if (tip != null) return tip;
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Rule functions — each returns a tip or null.
  // Order matters: higher-priority rules come first.
  // -----------------------------------------------------------------------

  static final List<ProTip? Function(EducationalContext)> _rules = [
    _facingBetWithPotOdds,
    _lowSprTip,
    _highSprTip,
    _earlyPositionTip,
    _latePositionTip,
    _blindsDefenseTip,
    _headsUpTip,
    _multiWayPotTip,
    _lastToActTip,
    _firstToActTip,
    _mediumSprTip,
    _checkedToYouTip,
  ];

  static ProTip? _facingBetWithPotOdds(EducationalContext ctx) {
    if (ctx.potOdds == null) return null;
    final pct = (ctx.potOdds! * 100).round();
    if (pct <= 20) {
      return ProTip(
        title: 'Good price to call',
        body:
            'You only need ${pct}% equity to break even. '
            'Most draws and marginal hands are worth continuing with.',
        category: 'Pot Odds',
      );
    }
    if (pct >= 40) {
      return ProTip(
        title: 'Expensive call',
        body:
            'You need ${pct}% equity to justify calling. '
            'Only continue with strong made hands or big combo draws.',
        category: 'Pot Odds',
      );
    }
    return ProTip(
      title: 'Evaluate your equity',
      body:
          'You need ${pct}% equity to call profitably. '
          'Count your outs and multiply by 2 (turn) or 4 (flop) for a quick estimate.',
      category: 'Pot Odds',
    );
  }

  static ProTip? _lowSprTip(EducationalContext ctx) {
    if (ctx.stackToPotRatio >= 4) return null;
    if (ctx.stackToPotRatio <= 0) return null;
    return const ProTip(
      title: 'Low SPR — commit or fold',
      body:
          'With an SPR under 4, top pair+ is usually strong enough to commit. '
          'Drawing hands lose value because there aren\'t enough chips behind to make up for missed draws.',
      category: 'SPR',
    );
  }

  static ProTip? _highSprTip(EducationalContext ctx) {
    if (ctx.stackToPotRatio < 13) return null;
    return const ProTip(
      title: 'Deep stacks — play speculative hands',
      body:
          'High SPR means implied odds are great. '
          'Suited connectors and small pairs can call to hit big hands cheaply.',
      category: 'SPR',
    );
  }

  static ProTip? _earlyPositionTip(EducationalContext ctx) {
    if (ctx.positionCategory != 'early') return null;
    if (ctx.potOdds != null) return null; // Facing a bet takes priority
    return const ProTip(
      title: 'Early position — play tight',
      body:
          'Many players still to act behind you. '
          'Stick to premium hands (big pairs, AK, AQ) to avoid tough spots out of position.',
      category: 'Position',
    );
  }

  static ProTip? _latePositionTip(EducationalContext ctx) {
    if (ctx.positionCategory != 'late') return null;
    if (ctx.potOdds != null) return null;
    return const ProTip(
      title: 'Late position — widen your range',
      body:
          'You\'ll act last post-flop, giving a huge information advantage. '
          'Open wider and look for steal opportunities when it\'s folded to you.',
      category: 'Position',
    );
  }

  static ProTip? _blindsDefenseTip(EducationalContext ctx) {
    if (ctx.positionCategory != 'blinds') return null;
    if (ctx.potOdds == null) return null;
    return ProTip(
      title: 'Blind defense',
      body:
          'You already have chips invested. '
          'With ${((ctx.potOdds! * 100).round())}% pot odds, you can defend a wide range — but be cautious out of position post-flop.',
      category: 'Position',
    );
  }

  static ProTip? _headsUpTip(EducationalContext ctx) {
    if (ctx.playersInHand != 2) return null;
    return const ProTip(
      title: 'Heads up — be aggressive',
      body:
          'With only one opponent, ranges are wide. '
          'Top pair is a strong hand and continuation bets are effective.',
      category: 'Situation',
    );
  }

  static ProTip? _multiWayPotTip(EducationalContext ctx) {
    if (ctx.playersInHand < 4) return null;
    return const ProTip(
      title: 'Multiway pot — tighten up',
      body:
          'With 4+ players, someone likely has a strong hand. '
          'Bluffs are less effective. Focus on value betting your strong hands.',
      category: 'Situation',
    );
  }

  static ProTip? _lastToActTip(EducationalContext ctx) {
    if (ctx.playersYetToAct != 0) return null;
    if (ctx.potOdds != null) return null;
    return const ProTip(
      title: 'Last to act — use your position',
      body:
          'Everyone has checked to you. '
          'This is a great spot to bet for thin value or pick up the pot with a bluff.',
      category: 'Position',
    );
  }

  static ProTip? _firstToActTip(EducationalContext ctx) {
    if (ctx.playersYetToAct < 3) return null;
    if (ctx.potOdds != null) return null;
    if (ctx.positionCategory == 'early') return null; // Already covered
    return ProTip(
      title: '${ctx.playersYetToAct} players behind',
      body:
          'Several players yet to act. '
          'Consider the likelihood of a raise behind you before opening light.',
      category: 'Situation',
    );
  }

  static ProTip? _mediumSprTip(EducationalContext ctx) {
    if (ctx.stackToPotRatio < 4 || ctx.stackToPotRatio > 13) return null;
    if (ctx.potOdds != null) return null; // Pot odds tip takes priority
    if (ctx.stackToPotRatio >= 7 && ctx.stackToPotRatio <= 10) {
      return const ProTip(
        title: 'Medium SPR — balanced play',
        body:
            'With SPR 7-10, both made hands and draws have value. '
            'Consider your hand strength and draws before committing.',
        category: 'SPR',
      );
    }
    return null;
  }

  static ProTip? _checkedToYouTip(EducationalContext ctx) {
    if (ctx.potOdds != null) return null; // Facing a bet
    if (ctx.playersYetToAct != 0) return null; // Not last to act
    if (ctx.playersInHand < 3) return null; // Already covered by heads-up
    return const ProTip(
      title: 'Checked around to you',
      body:
          'Everyone has shown weakness by checking. '
          'This is a prime spot for a bet — even with marginal hands, you may take it down.',
      category: 'Situation',
    );
  }
}
