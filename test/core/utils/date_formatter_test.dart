import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('formatDate', () {
      test('formats date as "MMM d, yyyy"', () {
        final date = DateTime(2024, 1, 15);
        expect(DateFormatter.formatDate(date), 'Jan 15, 2024');
      });

      test('formats different months correctly', () {
        expect(DateFormatter.formatDate(DateTime(2024, 6, 1)), 'Jun 1, 2024');
        expect(
            DateFormatter.formatDate(DateTime(2024, 12, 25)), 'Dec 25, 2024');
      });

      test('handles single-digit day', () {
        final date = DateTime(2024, 3, 5);
        expect(DateFormatter.formatDate(date), 'Mar 5, 2024');
      });
    });

    group('formatDateTime', () {
      test('includes time component', () {
        final dt = DateTime(2024, 1, 15, 14, 30);
        expect(DateFormatter.formatDateTime(dt), 'Jan 15, 2024 2:30 PM');
      });

      test('formats AM correctly', () {
        final dt = DateTime(2024, 6, 1, 9, 0);
        expect(DateFormatter.formatDateTime(dt), 'Jun 1, 2024 9:00 AM');
      });

      test('formats midnight as 12 AM', () {
        final dt = DateTime(2024, 1, 1, 0, 0);
        expect(DateFormatter.formatDateTime(dt), 'Jan 1, 2024 12:00 AM');
      });

      test('formats noon as 12 PM', () {
        final dt = DateTime(2024, 1, 1, 12, 0);
        expect(DateFormatter.formatDateTime(dt), 'Jan 1, 2024 12:00 PM');
      });
    });
  });
}
