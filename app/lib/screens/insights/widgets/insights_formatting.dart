import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';

String formatInsightCurrency(
  double amount, {
  required String currencyCode,
  String? locale,
}) {
  final sanitizedLocale = _sanitizeLocale(locale);

  if (sanitizedLocale != null) {
    try {
      return CurrencyFormatter.format(
        amount,
        currencyCode: currencyCode,
        locale: sanitizedLocale,
      );
    } catch (_) {
      // Fall back to a best-effort formatter below.
    }
  }

  try {
    return CurrencyFormatter.format(amount, currencyCode: currencyCode);
  } catch (_) {
    return '${currencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }
}

String formatInsightCompactCurrency(
  double amount, {
  required String currencyCode,
  String? locale,
}) {
  final sanitizedLocale = _sanitizeLocale(locale);

  if (sanitizedLocale != null) {
    try {
      return CurrencyFormatter.formatCompact(
        amount,
        currencyCode: currencyCode,
        locale: sanitizedLocale,
      );
    } catch (_) {
      // Fall back to a best-effort formatter below.
    }
  }

  try {
    return CurrencyFormatter.formatCompact(amount, currencyCode: currencyCode);
  } catch (_) {
    return formatInsightCurrency(
      amount,
      currencyCode: currencyCode,
      locale: sanitizedLocale,
    );
  }
}

String formatInsightDate(
  DateTime date, {
  String? locale,
  String pattern = 'MMM d',
}) {
  final sanitizedLocale = _sanitizeLocale(locale);

  if (sanitizedLocale != null) {
    try {
      return DateFormat(pattern, sanitizedLocale).format(date);
    } catch (_) {
      // Fall back to default locale below.
    }
  }

  return DateFormat(pattern).format(date);
}

String formatInsightLastVisit(
  String rawDate, {
  String? locale,
}) {
  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return rawDate;
  return formatInsightDate(parsed, locale: locale);
}

Color insightRateColor(BuildContext context, double rate) {
  final colors = Theme.of(context).colorScheme;
  if (rate >= 0.6) return colors.error;
  if (rate >= 0.4) return colors.tertiary;
  return colors.primary;
}

({AppIconKey icon, Color color, String label}) insightRegretPresentation(
  BuildContext context,
  String? regretLevel,
) {
  final colors = Theme.of(context).colorScheme;

  return switch (regretLevel?.toLowerCase()) {
    'worthit' => (
        icon: AppIconKey.check,
        color: const Color(0xFF2E7D5B),
        label: 'Worth it',
      ),
    'regret' => (
        icon: AppIconKey.error,
        color: colors.error,
        label: 'Regret',
      ),
    'notsure' => (
        icon: AppIconKey.help,
        color: colors.tertiary,
        label: 'Not sure',
      ),
    _ => (
        icon: AppIconKey.timer,
        color: colors.onSurfaceVariant,
        label: 'Unrated',
      ),
  };
}

int? insightRegretLevelValue(String? regretLevel) {
  return switch (regretLevel?.toLowerCase().replaceAll('_', '')) {
    'worthit' => 0,
    'notsure' => 1,
    'regret' => 2,
    _ => null,
  };
}

String? _sanitizeLocale(String? locale) {
  if (locale == null) return null;
  final trimmed = locale.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
