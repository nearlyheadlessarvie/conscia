class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  final String code;
  final String name;
  final String symbol;
  final String flag;
}

class Currencies {
  Currencies._();

  static const List<CurrencyInfo> all = [
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$', flag: '🇨🇦'),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: 'MX\$', flag: '🇲🇽'),
    CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    CurrencyInfo(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
    CurrencyInfo(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', flag: '🇳🇴'),
    CurrencyInfo(code: 'DKK', name: 'Danish Krone', symbol: 'kr', flag: '🇩🇰'),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
    CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', flag: '🇳🇿'),
    CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    CurrencyInfo(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    CurrencyInfo(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', flag: '🇵🇱'),
    CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
    CurrencyInfo(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
    CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩'),
    CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
    CurrencyInfo(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', flag: '🇨🇿'),
    CurrencyInfo(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', flag: '🇭🇺'),
    CurrencyInfo(code: 'RON', name: 'Romanian Leu', symbol: 'lei', flag: '🇷🇴'),
    CurrencyInfo(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', flag: '🇮🇱'),
    CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    CurrencyInfo(code: 'COP', name: 'Colombian Peso', symbol: 'CO\$', flag: '🇨🇴'),
    CurrencyInfo(code: 'ARS', name: 'Argentine Peso', symbol: 'AR\$', flag: '🇦🇷'),
    CurrencyInfo(code: 'CLP', name: 'Chilean Peso', symbol: 'CL\$', flag: '🇨🇱'),
    CurrencyInfo(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', flag: '🇵🇪'),
  ];

  static CurrencyInfo? byCode(String code) {
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Maps ISO 3166-1 country codes to their primary currency.
  /// Single source of truth — used by device-default inference and onboarding.
  static const Map<String, String> countryToCurrency = {
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

  /// Infer currency code from ISO country code, defaults to USD.
  static String fromCountry(String countryCode) =>
      countryToCurrency[countryCode] ?? 'USD';
}
