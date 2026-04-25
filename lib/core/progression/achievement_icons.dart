import 'package:flutter/material.dart';

/// Maps achievement icon code points to const [IconData] references.
///
/// Flutter's icon tree shaker requires constant [IconData] values, so we
/// can't construct them dynamically from a code point. Each entry mirrors
/// the codepoint declared in [achievementsCatalog].
const _iconMap = <int, IconData>{
  0xe037: Icons.play_arrow_rounded,
  0xe559: Icons.school_rounded,
  0xe838: Icons.star_rounded,
  0xea77: Icons.workspace_premium_rounded,
  0xef55: Icons.local_fire_department_rounded,
  0xe8e8: Icons.shield_rounded,
  0xea70: Icons.diamond_rounded,
  0xe87d: Icons.trending_up_rounded,
  0xea64: Icons.emoji_events_rounded,
};

/// Const [IconData] for an achievement's [iconCodePoint], falling back to
/// a trophy icon for unknown values.
IconData achievementIcon(int codePoint) =>
    _iconMap[codePoint] ?? Icons.emoji_events_rounded;
