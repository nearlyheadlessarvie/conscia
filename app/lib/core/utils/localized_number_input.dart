import 'package:flutter/services.dart';

class LocalizedNumberInput {
  LocalizedNumberInput._();

  static String decimalSeparator(String? locale) {
    final normalized = _normalize(locale);
    return switch (normalized) {
      'de_DE' || 'fr_FR' => ',',
      _ => '.',
    };
  }

  static TextInputFormatter formatter(
    String? locale, {
    int decimalDigits = 2,
    bool useGrouping = true,
  }) {
    final normalized = _normalize(locale);
    return _LocalizedAmountInputFormatter(
      decimalDigits: decimalDigits,
      decimalSeparator: decimalSeparator(locale),
      groupSeparator: groupSeparator(locale),
      useGrouping: useGrouping,
      useIndianGrouping: normalized == 'en_IN',
    );
  }

  static String groupSeparator(String? locale) {
    final normalized = _normalize(locale);
    return switch (normalized) {
      'de_DE' => '.',
      'fr_FR' => ' ',
      _ => ',',
    };
  }

  static double? parseAmount(String input, {String? locale}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final decimal = decimalSeparator(locale);
    if (!RegExp(r'^[0-9.,\s\u00A0]+$').hasMatch(trimmed)) {
      return null;
    }
    if (_count(trimmed, decimal) > 1) {
      return null;
    }

    var normalized = trimmed
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll('\u202F', '');

    if (decimal == ',') {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }

    return double.tryParse(normalized);
  }

  static String formatForInput(
    double amount, {
    String? locale,
    int decimalDigits = 2,
  }) {
    final fixed = amount.toStringAsFixed(decimalDigits);
    final decimal = decimalSeparator(locale);
    final parts = fixed.split('.');
    final integer = _formatInteger(
      parts.first,
      groupSeparator: groupSeparator(locale),
      useGrouping: true,
      useIndianGrouping: _normalize(locale) == 'en_IN',
    );
    if (decimalDigits == 0) return integer;
    return '$integer$decimal${parts.last}';
  }

  static String _normalize(String? locale) =>
      (locale ?? '').replaceAll('-', '_');

  static int _count(String value, String needle) {
    return needle.allMatches(value).length;
  }

  static String _formatInteger(
    String digits, {
    required String groupSeparator,
    required bool useGrouping,
    required bool useIndianGrouping,
  }) {
    final normalizedDigits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (!useGrouping || normalizedDigits.length <= 3) {
      return normalizedDigits;
    }

    if (useIndianGrouping) {
      final lastThree = normalizedDigits.substring(normalizedDigits.length - 3);
      var remaining =
          normalizedDigits.substring(0, normalizedDigits.length - 3);
      final groups = <String>[lastThree];
      while (remaining.length > 2) {
        groups.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      if (remaining.isNotEmpty) {
        groups.insert(0, remaining);
      }
      return groups.join(groupSeparator);
    }

    final groups = <String>[];
    var remaining = normalizedDigits;
    while (remaining.length > 3) {
      groups.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    groups.insert(0, remaining);
    return groups.join(groupSeparator);
  }
}

class _LocalizedAmountInputFormatter extends TextInputFormatter {
  const _LocalizedAmountInputFormatter({
    required this.decimalDigits,
    required this.decimalSeparator,
    required this.groupSeparator,
    required this.useGrouping,
    required this.useIndianGrouping,
  });

  final int decimalDigits;
  final String decimalSeparator;
  final String groupSeparator;
  final bool useGrouping;
  final bool useIndianGrouping;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (!RegExp(r'^[0-9.,\s\u00A0]*$').hasMatch(text)) {
      return oldValue;
    }
    if (LocalizedNumberInput._count(text, decimalSeparator) > 1) {
      return oldValue;
    }

    if (text.isEmpty) {
      return newValue;
    }

    final hasDecimal = decimalDigits > 0 && text.contains(decimalSeparator);
    final parts = text.split(decimalSeparator);
    final integerDigits = parts.first.replaceAll(RegExp(r'\D'), '');
    final fractionDigits = hasDecimal && parts.length > 1
        ? parts[1].replaceAll(RegExp(r'\D'), '')
        : '';

    if (integerDigits.isEmpty && !hasDecimal) {
      return const TextEditingValue();
    }

    final integerText = LocalizedNumberInput._formatInteger(
      integerDigits.isEmpty ? '0' : integerDigits,
      groupSeparator: groupSeparator,
      useGrouping: useGrouping,
      useIndianGrouping: useIndianGrouping,
    );
    final formatted = hasDecimal
        ? '$integerText$decimalSeparator${fractionDigits.substring(
            0,
            fractionDigits.length.clamp(0, decimalDigits),
          )}'
        : integerText;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
