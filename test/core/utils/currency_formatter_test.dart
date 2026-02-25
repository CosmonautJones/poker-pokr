import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('format', () {
      test('formats zero', () {
        expect(CurrencyFormatter.format(0), '\$0.00');
      });

      test('formats positive whole number', () {
        expect(CurrencyFormatter.format(100), '\$100.00');
      });

      test('formats cents', () {
        expect(CurrencyFormatter.format(42.5), '\$42.50');
      });

      test('formats large amounts with comma separators', () {
        expect(CurrencyFormatter.format(1234.56), '\$1,234.56');
      });

      test('formats negative amounts', () {
        expect(CurrencyFormatter.format(-50), '-\$50.00');
      });

      test('rounds to two decimal places', () {
        expect(CurrencyFormatter.format(9.999), '\$10.00');
      });
    });

    group('formatSigned', () {
      test('positive amount gets + prefix', () {
        expect(CurrencyFormatter.formatSigned(100), '+\$100.00');
      });

      test('zero gets + prefix', () {
        expect(CurrencyFormatter.formatSigned(0), '+\$0.00');
      });

      test('negative amount keeps - prefix', () {
        expect(CurrencyFormatter.formatSigned(-50), '-\$50.00');
      });

      test('large positive amount with comma', () {
        expect(CurrencyFormatter.formatSigned(1500), '+\$1,500.00');
      });
    });
  });
}
