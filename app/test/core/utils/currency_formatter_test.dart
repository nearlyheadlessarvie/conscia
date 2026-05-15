import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('uses locale separators without moving the currency symbol', () {
      expect(
        CurrencyFormatter.format(
          14385,
          currencyCode: 'PHP',
          locale: 'de_DE',
        ),
        '₱14.385,00',
      );
      expect(
        CurrencyFormatter.format(
          1234567.89,
          currencyCode: 'PHP',
          locale: 'en_IN',
        ),
        '₱12,34,567.89',
      );
    });
  });
}
