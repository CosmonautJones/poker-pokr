/// Side-pot calculation for multi-way all-in scenarios.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/player.dart';
import '../models/pot.dart';

class PotCalculator {
  /// Calculate the main pot and any side pots from the players' total
  /// investments.
  ///
  /// Algorithm:
  ///   1. Consider only non-folded players who have invested chips.
  ///   2. Sort them by totalInvested ascending.
  ///   3. For each unique investment level, create a pot that includes all
  ///      players at that level or higher, collecting the marginal investment
  ///      from each contributor (including folded players for the main pot).
  ///
  /// Folded players contribute to pots up to their investment level but are
  /// not eligible to win any pot.
  static List<SidePot> calculateSidePots(List<PlayerState> players) {
    // Gather all non-zero investments with fold status.
    final contributors = <_Contributor>[];
    for (final p in players) {
      if (p.totalInvested > 0) {
        contributors.add(_Contributor(
          index: p.index,
          invested: p.totalInvested,
          isFolded: p.isFolded,
        ));
      }
    }

    if (contributors.isEmpty) return const [];

    // Get sorted unique investment levels from non-folded players.
    final inHandInvestments = contributors
        .where((c) => !c.isFolded)
        .map((c) => c.invested)
        .toSet()
        .toList()
      ..sort();

    if (inHandInvestments.isEmpty) return const [];

    final pots = <SidePot>[];
    double previousLevel = 0;

    for (final level in inHandInvestments) {
      if (level <= previousLevel) continue;
      final marginal = level - previousLevel;

      // Every contributor who invested at least up to this level contributes
      // the marginal amount (or whatever they have above the previous level).
      double potAmount = 0;
      final eligible = <int>[];

      for (final c in contributors) {
        if (c.invested > previousLevel) {
          // This contributor has chips in this tier.
          final contribution =
              (c.invested - previousLevel).clamp(0, marginal);
          potAmount += contribution;
        }
        // Only non-folded players at or above this level are eligible.
        if (!c.isFolded && c.invested >= level) {
          eligible.add(c.index);
        }
      }

      if (potAmount > 0 && eligible.isNotEmpty) {
        pots.add(SidePot(amount: potAmount, eligiblePlayerIndices: eligible));
      }

      previousLevel = level;
    }

    return pots;
  }
}

class _Contributor {
  final int index;
  final double invested;
  final bool isFolded;

  const _Contributor({
    required this.index,
    required this.invested,
    required this.isFolded,
  });
}
