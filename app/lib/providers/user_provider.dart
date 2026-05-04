import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(dioProvider));
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getProfile();
});

({String currency, String locale}) deviceDefaults() {
  final deviceLocale = _bestDeviceLocale();
  final country = _resolveCountryCode(deviceLocale);
  return (
    currency: _currencyFromCountry(country),
    locale: '${deviceLocale.languageCode}_$country',
  );
}

String _currencyFromCountry(String countryCode) {
  const countryToCurrency = {
    'US': 'USD', 'GB': 'GBP', 'MX': 'MXN', 'ES': 'EUR',
    'FR': 'EUR', 'DE': 'EUR', 'IT': 'EUR', 'NL': 'EUR',
    'BE': 'EUR', 'AT': 'EUR', 'IE': 'EUR', 'PT': 'EUR',
    'FI': 'EUR', 'GR': 'EUR', 'SK': 'EUR', 'SI': 'EUR',
    'LT': 'EUR', 'LV': 'EUR', 'EE': 'EUR', 'MT': 'EUR',
    'CY': 'EUR', 'LU': 'EUR',
    'JP': 'JPY', 'CN': 'CNY', 'BR': 'BRL', 'CA': 'CAD',
    'AU': 'AUD', 'IN': 'INR', 'KR': 'KRW', 'PH': 'PHP',
    'SG': 'SGD', 'TH': 'THB', 'ID': 'IDR', 'MY': 'MYR',
    'NZ': 'NZD', 'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK',
    'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK', 'HU': 'HUF',
    'RO': 'RON', 'ZA': 'ZAR', 'AE': 'AED', 'SA': 'SAR',
    'IL': 'ILS', 'TR': 'TRY', 'HK': 'HKD',
    'CL': 'CLP', 'CO': 'COP', 'AR': 'ARS', 'PE': 'PEN',
  };
  return countryToCurrency[countryCode] ?? 'USD';
}

ui.Locale _bestDeviceLocale() {
  final dispatcher = ui.PlatformDispatcher.instance;
  return dispatcher.locales.isNotEmpty
      ? dispatcher.locales.first
      : dispatcher.locale;
}

String _resolveCountryCode(ui.Locale locale) {
  final normalizedCountry = locale.countryCode?.toUpperCase();
  if (normalizedCountry != null && normalizedCountry.isNotEmpty) {
    return normalizedCountry;
  }

  const languageToCountry = {
    'en': 'US',
    'es': 'ES',
    'fr': 'FR',
    'de': 'DE',
    'pt': 'BR',
    'ja': 'JP',
    'zh': 'CN',
    'ko': 'KR',
    'th': 'TH',
    'id': 'ID',
    'ms': 'MY',
    'tl': 'PH',
    'fil': 'PH',
  };

  return languageToCountry[locale.languageCode.toLowerCase()] ?? 'US';
}

final userPreferencesProvider =
    Provider<({String currency, String locale})>((ref) {
  final user = ref.watch(currentUserProvider);
  final defaults = deviceDefaults();
  return user.maybeWhen(
    data: (profile) => (currency: profile.currencyCode, locale: profile.locale),
    orElse: () => defaults,
  );
});
