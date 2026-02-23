import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  static String format(double amount) => _format.format(amount);

  static String formatSigned(double amount) =>
      amount >= 0 ? '+${format(amount)}' : format(amount);
}
