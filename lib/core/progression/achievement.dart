import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/poker_theme.dart';
import 'user_stats.dart';

/// Visual tier for an achievement: drives badge color and connotes difficulty.
enum AchievementTier { bronze, silver, gold }

/// A single unlockable goal evaluated against a [UserStats] snapshot.
///
/// Catalog entries are `const`-friendly so they can live in a static list.
@immutable
class Achievement {
  /// Stable, snake_case identifier used for persistence. Never rename.
  final String id;
  final String title;
  final String description;
  /// Shown in place of [description] when the achievement is locked.
  final String hint;
  final IconData icon;
  final AchievementTier tier;
  /// Pure predicate against the latest stats. Must be deterministic.
  final bool Function(UserStats) test;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.tier,
    required this.test,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Achievement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Maps an [AchievementTier] to a palette color from [pt].
///
/// Bronze uses a literal coppery hex since there is no equivalent token in
/// the existing palette; silver borrows `seatActiveBorder` (cool metallic
/// green-blue) and gold uses `goldPrimary` so the brand identity stays.
Color tierColor(PokerTheme pt, AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return const Color(0xFFCD7F32);
    case AchievementTier.silver:
      return pt.seatActiveBorder;
    case AchievementTier.gold:
      return pt.goldPrimary;
  }
}
