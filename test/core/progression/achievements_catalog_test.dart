import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';

void main() {
  group('AchievementsCatalog', () {
    test('contains at least 12 entries', () {
      expect(AchievementsCatalog.all.length, greaterThanOrEqualTo(12));
    });

    test('every entry has a unique id', () {
      final ids = AchievementsCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate ids: $ids');
    });

    test('every entry has non-empty title, description, hint', () {
      for (final a in AchievementsCatalog.all) {
        expect(a.id.trim(), isNotEmpty, reason: 'id blank');
        expect(a.title.trim(), isNotEmpty, reason: '${a.id} title');
        expect(a.description.trim(), isNotEmpty, reason: '${a.id} description');
        expect(a.hint.trim(), isNotEmpty, reason: '${a.id} hint');
      }
    });

    test('every entry has a valid tier', () {
      for (final a in AchievementsCatalog.all) {
        expect(AchievementTier.values, contains(a.tier));
      }
    });

    test('byId round-trips for known ids and returns null for unknown', () {
      for (final a in AchievementsCatalog.all) {
        expect(AchievementsCatalog.byId(a.id), same(a));
      }
      expect(AchievementsCatalog.byId('does_not_exist'), isNull);
    });

    test('expected core ids are present', () {
      const required = {
        'first_hand',
        'first_lesson',
        'hands_50',
        'hands_250',
        'lessons_5',
        'lessons_complete',
        'streak_3',
        'streak_7',
        'streak_30',
        'level_5',
        'level_10',
        'xp_1000',
      };
      final ids = AchievementsCatalog.all.map((a) => a.id).toSet();
      expect(ids.containsAll(required), isTrue,
          reason: 'missing: ${required.difference(ids)}');
    });
  });
}
