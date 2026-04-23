import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/settings/domain/personalization.dart';

void main() {
  group('PersonalizationSettings', () {
    test('defaults are stable', () {
      const defaults = PersonalizationSettings.defaults();
      expect(defaults.cardBack, CardBackStyle.classicBlue);
      expect(defaults.felt, TableFeltColor.classicGreen);
      expect(defaults.sound, SoundProfile.subtle);
    });

    test('JSON roundtrip across all enum combos', () {
      for (final back in CardBackStyle.values) {
        for (final felt in TableFeltColor.values) {
          for (final sound in SoundProfile.values) {
            final s = PersonalizationSettings(
              cardBack: back,
              felt: felt,
              sound: sound,
            );
            final decoded = PersonalizationSettings.tryDecode(s.encode());
            expect(decoded, isNotNull);
            expect(decoded!.cardBack, back);
            expect(decoded.felt, felt);
            expect(decoded.sound, sound);
          }
        }
      }
    });

    test('tryDecode returns null for invalid or empty input', () {
      expect(PersonalizationSettings.tryDecode(null), isNull);
      expect(PersonalizationSettings.tryDecode(''), isNull);
      expect(PersonalizationSettings.tryDecode('{not json'), isNull);
    });

    test('tryDecode with unknown enum name falls back to default field', () {
      const raw =
          '{"cardBack":"unknown","felt":"midnightBlue","sound":"full"}';
      final decoded = PersonalizationSettings.tryDecode(raw);
      expect(decoded, isNotNull);
      expect(decoded!.cardBack, CardBackStyle.classicBlue);
      expect(decoded.felt, TableFeltColor.midnightBlue);
      expect(decoded.sound, SoundProfile.full);
    });

    test('feltOverrides returns distinct center colors per enum value', () {
      final centers = {
        for (final v in TableFeltColor.values)
          v: PersonalizationSettings.feltOverrides(v).feltCenter,
      };
      final distinct = centers.values.toSet();
      expect(distinct.length, TableFeltColor.values.length);
    });

    test('cardBackOverrides returns distinct primary colors per enum value',
        () {
      final primaries = {
        for (final v in CardBackStyle.values)
          v: PersonalizationSettings.cardBackOverrides(v).cardBackPrimary,
      };
      final distinct = primaries.values.toSet();
      expect(distinct.length, CardBackStyle.values.length);
    });

    test('copyWith preserves untouched fields', () {
      const base = PersonalizationSettings.defaults();
      final next = base.copyWith(felt: TableFeltColor.royalPurple);
      expect(next.felt, TableFeltColor.royalPurple);
      expect(next.cardBack, base.cardBack);
      expect(next.sound, base.sound);
    });
  });
}
