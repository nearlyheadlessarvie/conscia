import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(
    double amount, {
    required String currencyCode,
    String? locale,
  }) {
    final formatter = NumberFormat.simpleCurrency(
      name: currencyCode,
      locale: locale,
    );
    return formatter.format(amount);
  }

  static String formatCompact(
    double amount, {
    required String currencyCode,
    String? locale,
  }) {
    final formatter = NumberFormat.compactSimpleCurrency(
      name: currencyCode,
      locale: locale,
    );
    return formatter.format(amount);
  }

  static String formatSigned(
    double amount, {
    required String currencyCode,
    String? locale,
  }) {
    final formatted = format(amount.abs(), currencyCode: currencyCode, locale: locale);
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}
