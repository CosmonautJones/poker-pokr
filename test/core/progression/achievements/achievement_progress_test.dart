import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements/achievement_progress.dart';

void main() {
  group('AchievementProgress', () {
    test('round-trips through JSON when locked', () {
      const p = AchievementProgress(value: 3);
      final restored = AchievementProgress.fromJson(p.toJson());
      expect(restored.value, 3);
      expect(restored.unlockedAt, isNull);
      expect(restored.isUnlocked, isFalse);
    });

    test('round-trips through JSON when unlocked', () {
      final at = DateTime.utc(2026, 5, 6, 12, 30);
      final p = AchievementProgress(value: 10, unlockedAt: at);
      final restored = AchievementProgress.fromJson(p.toJson());
      expect(restored.value, 10);
      expect(restored.unlockedAt, at);
      expect(restored.isUnlocked, isTrue);
    });

    test('copyWith preserves prior unlockedAt by default', () {
      final at = DateTime.utc(2026, 1, 1);
      final p = AchievementProgress(value: 1, unlockedAt: at);
      final next = p.copyWith(value: 2);
      expect(next.value, 2);
      expect(next.unlockedAt, at);
    });
  });

  group('AchievementsState', () {
    test('empty state has no progress and no unlocks', () {
      const s = AchievementsState.empty();
      expect(s.byId, isEmpty);
      expect(s.unlockedCount, 0);
      expect(s.progressFor('anything').value, 0);
      expect(s.progressFor('anything').isUnlocked, isFalse);
    });

    test('encode/decode round-trip preserves unlocks', () {
      final at = DateTime.utc(2026, 5, 6);
      final s = AchievementsState(byId: {
        'a': const AchievementProgress(value: 5),
        'b': AchievementProgress(value: 1, unlockedAt: at),
      });
      final restored = AchievementsState.tryDecode(s.encode());
      expect(restored, isNotNull);
      expect(restored!.byId.length, 2);
      expect(restored.byId['a']!.value, 5);
      expect(restored.byId['b']!.unlockedAt, at);
      expect(restored.unlockedCount, 1);
    });

    test('decode of malformed raw returns null', () {
      expect(AchievementsState.tryDecode(null), isNull);
      expect(AchievementsState.tryDecode(''), isNull);
      expect(AchievementsState.tryDecode('not json'), isNull);
      // Wrong shape: tolerated — entries that don't match are skipped.
      expect(AchievementsState.tryDecode('{"a":42}')?.byId, isEmpty);
    });

    test('withProgress overlays a single id immutably', () {
      const s = AchievementsState.empty();
      final next =
          s.withProgress('x', const AchievementProgress(value: 7));
      expect(s.byId, isEmpty); // original untouched
      expect(next.byId['x']!.value, 7);
    });
  });
}
