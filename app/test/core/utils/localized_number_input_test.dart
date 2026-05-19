import 'package:conscia_app/core/utils/localized_number_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizedNumberInput', () {
    test('parses English and Indian formatted amounts', () {
      expect(
        LocalizedNumberInput.parseAmount('1,234,567.89', locale: 'en_US'),
        1234567.89,
      );
      expect(
        LocalizedNumberInput.parseAmount('12,34,567.89', locale: 'en_IN'),
        1234567.89,
      );
    });

    test('parses European and French formatted amounts', () {
      expect(
        LocalizedNumberInput.parseAmount('1.234.567,89', locale: 'de_DE'),
        1234567.89,
      );
      expect(
        LocalizedNumberInput.parseAmount('1 234 567,89', locale: 'fr_FR'),
        1234567.89,
      );
    });

    test('rejects alphabetic input', () {
      expect(
        LocalizedNumberInput.parseAmount('dfdfd', locale: 'en_US'),
        isNull,
      );
    });

    test('formats input values with locale decimal separators', () {
      expect(
        LocalizedNumberInput.formatForInput(1234.5, locale: 'en_US'),
        '1,234.50',
      );
      expect(
        LocalizedNumberInput.formatForInput(1234.5, locale: 'de_DE'),
        '1.234,50',
      );
      expect(
        LocalizedNumberInput.formatForInput(1234.5, locale: 'fr_FR'),
        '1 234,50',
      );
      expect(
        LocalizedNumberInput.formatForInput(1234567.5, locale: 'en_IN'),
        '12,34,567.50',
      );
    });

    test('masks money input with grouping and two decimal places', () {
      final formatter = LocalizedNumberInput.formatter('en_US');
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1212312.56465413'),
      );

      expect(value.text, '1,212,312.56');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('masks European money input using comma decimals', () {
      final formatter = LocalizedNumberInput.formatter('de_DE');
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1212312,56465413'),
      );

      expect(value.text, '1.212.312,56');
    });

    test('can opt out of grouping and allow more decimals for rates', () {
      final formatter = LocalizedNumberInput.formatter(
        'en_US',
        decimalDigits: 4,
        useGrouping: false,
      );
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234.56789'),
      );

      expect(value.text, '1234.5678');
    });

    test('rejects invalid money characters in formatter', () {
      final formatter = LocalizedNumberInput.formatter('en_US');
      final value = formatter.formatEditUpdate(
        const TextEditingValue(text: '12'),
        const TextEditingValue(text: '12df'),
      );

      expect(value.text, '12');
    });
  });
}
