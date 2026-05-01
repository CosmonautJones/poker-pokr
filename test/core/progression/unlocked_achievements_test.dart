import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/unlocked_achievements.dart';

void main() {
  group('UnlockedAchievements', () {
    test('empty has count 0 and contains nothing', () {
      const u = UnlockedAchievements.empty();
      expect(u.count, 0);
      expect(u.contains('foo'), isFalse);
    });

    test('copyWithUnlock is immutable and adds the entry', () {
      const u = UnlockedAchievements.empty();
      final at = DateTime.utc(2026, 5, 1, 12);
      final u2 = u.copyWithUnlock('first_hand', at);
      expect(u.count, 0);
      expect(u2.count, 1);
      expect(u2.contains('first_hand'), isTrue);
      expect(u2.unlockedAt['first_hand'], at);
    });

    test('copyWithUnlock preserves existing timestamp on duplicate id', () {
      const u = UnlockedAchievements.empty();
      final t1 = DateTime.utc(2026, 5, 1);
      final t2 = DateTime.utc(2026, 5, 2);
      final u2 = u.copyWithUnlock('a', t1);
      final u3 = u2.copyWithUnlock('a', t2);
      expect(u3.unlockedAt['a'], t1);
    });

    test('encode + tryDecode round-trips multiple entries', () {
      const u = UnlockedAchievements.empty();
      final t1 = DateTime.utc(2026, 5, 1, 9, 30);
      final t2 = DateTime.utc(2026, 5, 4, 18, 45, 12);
      final u2 = u.copyWithUnlock('a', t1).copyWithUnlock('b', t2);
      final decoded = UnlockedAchievements.tryDecode(u2.encode());
      expect(decoded.count, 2);
      expect(decoded.unlockedAt['a'], t1);
      expect(decoded.unlockedAt['b'], t2);
    });

    test('tryDecode handles null, empty, and malformed JSON gracefully', () {
      expect(UnlockedAchievements.tryDecode(null).count, 0);
      expect(UnlockedAchievements.tryDecode('').count, 0);
      expect(UnlockedAchievements.tryDecode('{not json').count, 0);
      expect(UnlockedAchievements.tryDecode('"a string"').count, 0);
    });

    test('tryDecode skips entries with non-string or unparseable timestamps',
        () {
      final raw = '{"good":"2026-05-01T00:00:00.000","bad":42,"junk":"nope"}';
      final decoded = UnlockedAchievements.tryDecode(raw);
      expect(decoded.contains('good'), isTrue);
      expect(decoded.contains('bad'), isFalse);
      expect(decoded.contains('junk'), isFalse);
    });
  });
}
