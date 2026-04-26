import 'dart:convert';

/// Persisted set of unlocked achievements keyed by id, with the timestamp
/// at which each was first unlocked.
///
/// Mirrors the [UserStats] persistence pattern: a single JSON string under
/// [storageKey] that can evolve without migrations.
class AchievementState {
  static const storageKey = 'achievement_state_v1';

  final Map<String, DateTime> unlockedAt;

  const AchievementState({required this.unlockedAt});

  const AchievementState.empty() : unlockedAt = const {};

  bool isUnlocked(String id) => unlockedAt.containsKey(id);

  DateTime? unlockDate(String id) => unlockedAt[id];

  int get unlockedCount => unlockedAt.length;

  AchievementState copyWithNewUnlock(String id, DateTime when) {
    if (unlockedAt.containsKey(id)) return this;
    return AchievementState(
      unlockedAt: {...unlockedAt, id: when},
    );
  }

  AchievementState copyWithNewUnlocks(Map<String, DateTime> additions) {
    if (additions.isEmpty) return this;
    final next = <String, DateTime>{...unlockedAt};
    additions.forEach((id, when) {
      next.putIfAbsent(id, () => when);
    });
    return AchievementState(unlockedAt: next);
  }

  Map<String, dynamic> toJson() => {
        'unlockedAt': unlockedAt
            .map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  String encode() => jsonEncode(toJson());

  static AchievementState? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final inner = map['unlockedAt'] as Map<String, dynamic>?;
      if (inner == null) return const AchievementState.empty();
      final out = <String, DateTime>{};
      inner.forEach((k, v) {
        if (v is String) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) out[k] = parsed;
        }
      });
      return AchievementState(unlockedAt: out);
    } catch (_) {
      return null;
    }
  }
}
