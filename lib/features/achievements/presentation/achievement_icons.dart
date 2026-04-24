import 'package:flutter/material.dart';

/// Maps achievement icon code points to const [IconData] references.
///
/// Flutter's icon tree shaker requires constant [IconData] instances; this
/// lookup replaces dynamic `IconData(codePoint, ...)` calls so the web
/// build can tree-shake unused icons. Mirrors the approach used by
/// `lesson_icons.dart`.
const _iconMap = <int, IconData>{
  0xe037: Icons.play_arrow_rounded,
  0xe3a9: Icons.emoji_events_rounded,
  0xe8e8: Icons.shield_rounded,
  0xe87d: Icons.trending_up_rounded,
  0xef55: Icons.local_fire_department_rounded,
  0xe80c: Icons.school_rounded,
  0xe838: Icons.star_rounded,
};

/// Returns a const [IconData] for the given [codePoint], falling back to
/// [Icons.emoji_events_rounded].
IconData achievementIcon(int codePoint) =>
    _iconMap[codePoint] ?? Icons.emoji_events_rounded;
