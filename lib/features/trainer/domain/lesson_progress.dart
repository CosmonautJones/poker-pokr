/// Per-lesson scenario completion model.
///
/// Pure Dart - no Flutter or storage imports so the logic can be unit-tested
/// in isolation. Persistence lives under `data/`, provider wiring under
/// `providers/`.
library;

import 'dart:collection';
import 'dart:convert';

/// Immutable snapshot of which scenarios the player has finished, keyed by
/// lesson id. Each value is a sorted map of scenarioIndex -> firstCompletedAt.
///
/// Sorting is enforced via [SplayTreeMap] so iteration is deterministic for
/// serialization and rendering, and so set membership is O(log n).
class LessonProgress {
  /// SharedPreferences key. Versioned so the schema can evolve.
  static const storageKey = 'lesson_progress_v1';

  final Map<String, SplayTreeMap<int, DateTime>> _completed;

  const LessonProgress._(this._completed);

  /// Empty progress for a fresh install.
  LessonProgress.empty() : _completed = const {};

  /// Defensive deep-copy constructor.
  factory LessonProgress.fromMap(Map<String, Map<int, DateTime>> raw) {
    final out = <String, SplayTreeMap<int, DateTime>>{};
    for (final entry in raw.entries) {
      if (entry.value.isEmpty) continue;
      final sorted = SplayTreeMap<int, DateTime>();
      sorted.addAll(entry.value);
      out[entry.key] = sorted;
    }
    return LessonProgress._(out);
  }

  /// Whether [scenarioIndex] of [lessonId] has been completed.
  bool isComplete(String lessonId, int scenarioIndex) {
    final scenarios = _completed[lessonId];
    return scenarios != null && scenarios.containsKey(scenarioIndex);
  }

  /// Number of completed scenarios within [lessonId].
  int completedCount(String lessonId) =>
      _completed[lessonId]?.length ?? 0;

  /// All lesson ids with at least one completed scenario.
  Iterable<String> get completedLessonIds => _completed.keys;

  /// Total scenarios completed across every lesson.
  int get totalScenariosCompleted {
    var n = 0;
    for (final m in _completed.values) {
      n += m.length;
    }
    return n;
  }

  /// First completion timestamp for a scenario, or null if never completed.
  DateTime? completedAt(String lessonId, int scenarioIndex) =>
      _completed[lessonId]?[scenarioIndex];

  /// Returns a new [LessonProgress] with [scenarioIndex] of [lessonId] marked
  /// complete at [now]. If the scenario was already completed, the existing
  /// timestamp is preserved so first-completion is the canonical anchor.
  LessonProgress markComplete(
    String lessonId,
    int scenarioIndex,
    DateTime now,
  ) {
    final existing = _completed[lessonId];
    if (existing != null && existing.containsKey(scenarioIndex)) {
      return this;
    }

    final next = <String, SplayTreeMap<int, DateTime>>{};
    for (final e in _completed.entries) {
      final clone = SplayTreeMap<int, DateTime>();
      clone.addAll(e.value);
      next[e.key] = clone;
    }
    final lessonMap = next[lessonId] ?? SplayTreeMap<int, DateTime>();
    lessonMap[scenarioIndex] = now;
    next[lessonId] = lessonMap;
    return LessonProgress._(next);
  }

  /// JSON shape: `{"lessonId": {"0": "iso", "2": "iso"}}`.
  Map<String, dynamic> toJson() {
    final out = <String, Map<String, String>>{};
    for (final entry in _completed.entries) {
      final inner = <String, String>{};
      for (final s in entry.value.entries) {
        inner[s.key.toString()] = s.value.toIso8601String();
      }
      out[entry.key] = inner;
    }
    return out;
  }

  String encode() => jsonEncode(toJson());

  /// Tolerant decode - returns null on garbage so callers can fall back to
  /// [LessonProgress.empty]. Malformed inner entries are skipped, not thrown.
  static LessonProgress? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final root = jsonDecode(raw);
      if (root is! Map) return null;
      final out = <String, SplayTreeMap<int, DateTime>>{};
      for (final entry in root.entries) {
        final lessonId = entry.key.toString();
        final inner = entry.value;
        if (inner is! Map) continue;
        final indexMap = SplayTreeMap<int, DateTime>();
        for (final s in inner.entries) {
          final idx = int.tryParse(s.key.toString());
          if (idx == null) continue;
          final ts = s.value is String
              ? DateTime.tryParse(s.value as String)
              : null;
          if (ts == null) continue;
          indexMap[idx] = ts;
        }
        if (indexMap.isNotEmpty) {
          out[lessonId] = indexMap;
        }
      }
      return LessonProgress._(out);
    } catch (_) {
      return null;
    }
  }
}
