import 'package:flutter/material.dart';

/// Maps lesson icon code points to const [IconData] references.
///
/// Flutter's icon tree shaker requires constant [IconData] instances.
/// This lookup replaces dynamic `IconData(codePoint, ...)` calls with
/// pre-defined const values so the web build can tree-shake unused icons.
const _iconMap = <int, IconData>{
  0xe87d: Icons.trending_up,
  0xe8e8: Icons.shield,
};

/// Returns a const [IconData] for the given [codePoint], falling back to
/// [Icons.school] for unknown values.
IconData lessonIcon(int codePoint) => _iconMap[codePoint] ?? Icons.school;
