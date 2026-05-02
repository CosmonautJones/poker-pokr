import 'package:flutter/material.dart';

/// Maps achievement icon code points to const [IconData] references so
/// Flutter's icon tree shaker can prune unused glyphs.
///
/// Mirrors the pattern used by `lesson_icons.dart`. Keep entries in sync
/// with `core/progression/achievements.dart` codepoints.
const _iconMap = <int, IconData>{
  0xe037: Icons.play_circle_filled_rounded,
  0xe838: Icons.star_rounded,
  0xe263: Icons.wb_iridescent_rounded,
  0xe7fb: Icons.people_alt_rounded,
  0xea14: Icons.local_fire_department_rounded,
  0xe559: Icons.school_rounded,
  0xe865: Icons.menu_book_rounded,
  0xe80c: Icons.emoji_events_rounded,
  0xe87d: Icons.trending_up_rounded,
};

/// Returns a const [IconData] for the given [codePoint], falling back to
/// [Icons.emoji_events_rounded] for any unknown value.
IconData achievementIcon(int codePoint) =>
    _iconMap[codePoint] ?? Icons.emoji_events_rounded;
