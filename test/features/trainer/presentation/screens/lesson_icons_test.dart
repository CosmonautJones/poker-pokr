import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';

void main() {
  group('lessonIcon', () {
    test('returns Icons.trending_up for drawing_hands code point', () {
      expect(lessonIcon(0xe87d), Icons.trending_up);
    });

    test('returns Icons.shield for hand_protection code point', () {
      expect(lessonIcon(0xe8e8), Icons.shield);
    });

    test('returns Icons.school fallback for unknown code point', () {
      expect(lessonIcon(0x0000), Icons.school);
    });

    test('returns Icons.school fallback for arbitrary unmapped code point', () {
      expect(lessonIcon(0xFFFF), Icons.school);
    });

    test('every lesson in the catalog has a mapped icon', () {
      // This test fails if someone adds a new lesson to lessonsCatalog
      // without also adding its iconCodePoint to the icon map.
      for (final lesson in lessonsCatalog) {
        final icon = lessonIcon(lesson.iconCodePoint);
        expect(
          icon,
          isNot(Icons.school),
          reason:
              'Lesson "${lesson.id}" (iconCodePoint: 0x${lesson.iconCodePoint.toRadixString(16)}) '
              'is missing from the lessonIcon map. Add it to lesson_icons.dart.',
        );
      }
    });

    test('mapped icons are valid MaterialIcons IconData', () {
      for (final lesson in lessonsCatalog) {
        final icon = lessonIcon(lesson.iconCodePoint);
        expect(icon.fontFamily, 'MaterialIcons');
      }
    });
  });
}
