/// Canonical poker positions for a 9-max table.
///
/// Pure Dart - no Flutter imports. The Learn Hub's Position Chart screen
/// renders these around a table-shaped visual; the playing engine has its
/// own seat indexing (this is a learning aid, not a runtime model).
library;

/// The strategic "tier" a position falls into.
enum PositionTier {
  /// Seats that act first preflop (UTG family). Tightest ranges.
  early,

  /// Middle position — moderate ranges.
  middle,

  /// LJ, HJ, CO, BTN. Widest ranges, biggest informational edge.
  late,

  /// SB and BB. Forced bets; out of position post-flop.
  blinds,
}

extension PositionTierLabel on PositionTier {
  String get label => switch (this) {
        PositionTier.early => 'Early',
        PositionTier.middle => 'Middle',
        PositionTier.late => 'Late',
        PositionTier.blinds => 'Blinds',
      };
}

/// One seat's metadata — name, abbreviation, tier, and a one-liner on
/// strategic role.
class PokerPosition {
  /// Seat index for a 9-max table, 0 = UTG, 8 = BB. Useful for ordering.
  final int seatIndex;
  final String name;
  final String abbreviation;
  final PositionTier tier;

  /// One-line role summary, used as the main caption on the Position Chart.
  final String role;

  /// Suggested opening-range note (qualitative).
  final String openingNote;

  const PokerPosition({
    required this.seatIndex,
    required this.name,
    required this.abbreviation,
    required this.tier,
    required this.role,
    required this.openingNote,
  });
}

class PokerPositions {
  PokerPositions._();

  /// All 9-max positions in order from UTG (first to act preflop) to BB.
  ///
  /// 6-max tables omit UTG, UTG+1, MP — start at LJ. The chart UI surfaces
  /// both layouts via a toggle.
  static const List<PokerPosition> ninemax = [
    PokerPosition(
      seatIndex: 0,
      name: 'Under the Gun',
      abbreviation: 'UTG',
      tier: PositionTier.early,
      role: 'First to act. Tightest range — premium hands only.',
      openingNote: 'About 10–12% of hands: TT+, AQ+, AKs, KQs.',
    ),
    PokerPosition(
      seatIndex: 1,
      name: 'Under the Gun +1',
      abbreviation: 'UTG+1',
      tier: PositionTier.early,
      role: 'Second to act. Still very tight.',
      openingNote: 'Add 99, AJs, KQ, suited broadways.',
    ),
    PokerPosition(
      seatIndex: 2,
      name: 'Middle Position',
      abbreviation: 'MP',
      tier: PositionTier.middle,
      role: 'Transition seat. Moderate ranges.',
      openingNote: 'Add 88, AT+, KJs, QJs, suited connectors.',
    ),
    PokerPosition(
      seatIndex: 3,
      name: 'Lojack',
      abbreviation: 'LJ',
      tier: PositionTier.middle,
      role: 'First seat with a real positional edge post-flop.',
      openingNote: 'Add 77, A9s+, KTs, QTs, JTs.',
    ),
    PokerPosition(
      seatIndex: 4,
      name: 'Hijack',
      abbreviation: 'HJ',
      tier: PositionTier.late,
      role: 'Late position. Steal opportunities open up.',
      openingNote: 'Add 66, A7s+, K9s+, suited gappers.',
    ),
    PokerPosition(
      seatIndex: 5,
      name: 'Cutoff',
      abbreviation: 'CO',
      tier: PositionTier.late,
      role: 'Second-best seat. Wide opens, frequent steals.',
      openingNote: 'Add 55, any suited ace, A9o+, K9o+.',
    ),
    PokerPosition(
      seatIndex: 6,
      name: 'Button',
      abbreviation: 'BTN',
      tier: PositionTier.late,
      role: 'Best seat. Acts last post-flop on every street.',
      openingNote: 'About 40–45%: any pair, any suited card with A/K, broadways.',
    ),
    PokerPosition(
      seatIndex: 7,
      name: 'Small Blind',
      abbreviation: 'SB',
      tier: PositionTier.blinds,
      role: 'Posts half a BB. Worst post-flop position — out of position to BB.',
      openingNote: 'Defend tight; 3-bet or fold most spots when facing a raise.',
    ),
    PokerPosition(
      seatIndex: 8,
      name: 'Big Blind',
      abbreviation: 'BB',
      tier: PositionTier.blinds,
      role: 'Posts a full BB. Closes the action preflop — defend wide vs late opens.',
      openingNote: 'Defend ~40% vs BTN open; tighter vs early opens.',
    ),
  ];

  /// 6-max layout (most online cash games).
  static List<PokerPosition> get sixmax =>
      ninemax.where((p) => !{'UTG', 'UTG+1', 'MP'}.contains(p.abbreviation)).toList();

  /// Heads-up: BTN/SB and BB only.
  static List<PokerPosition> get heads => ninemax
      .where((p) => p.abbreviation == 'BTN' || p.abbreviation == 'BB')
      .toList();
}
