import 'package:flutter/material.dart';

/// Maps achievement icon string keys to const [IconData] references so
/// Flutter's icon tree-shaker can keep only the icons we actually use.
///
/// Mirrors the lesson_icons.dart pattern. Add a new entry here whenever a
/// new key is introduced in the achievements catalog.
const _iconMap = <String, IconData>{
  'play_arrow': Icons.play_arrow_rounded,
  'school': Icons.school_rounded,
  'trophy': Icons.emoji_events_rounded,
  'bar_chart': Icons.bar_chart_rounded,
  'insights': Icons.insights_rounded,
  'workspace_premium': Icons.workspace_premium_rounded,
  'fire': Icons.local_fire_department_rounded,
  'menu_book': Icons.menu_book_rounded,
  'star': Icons.star_rounded,
  'calendar': Icons.calendar_today_rounded,
};

/// Returns the [IconData] for [key], falling back to a generic medal icon
/// for unknown keys so newly-added achievements still render something.
IconData achievementIcon(String key) =>
    _iconMap[key] ?? Icons.military_tech_rounded;
