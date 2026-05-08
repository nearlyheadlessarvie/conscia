// GENERATED — do not edit by hand.
// Regenerate: dotnet run --project tools/ConstantsGen
// Source: Conscia.Domain + tools/ConstantsGen/Metadata/CurrencyMetadata.cs

// ── Freemium limits ──────────────────────────────────────────────
class FreemiumLimits {
  FreemiumLimits._();
  static const int freeBudgetCategories = 3;
  static const int freeAiAssistsPerMonth = 5;
  static const int freeReflectionsPerMonth = 10;
  static const int freeCurrencies = 1;
}

// ── Enums ────────────────────────────────────────────────────────
enum RegretLevel { worthIt, notSure, regret }
enum SubscriptionTier { free, premium }

// ── Categories ───────────────────────────────────────────────────
const List<String> expenseCategories = [
  'Groceries',
  'Dining',
  'Transport',
  'Entertainment',
  'Gaming',
  'Shopping',
  'Health',
  'Bills',
  'Education',
  'Travel',
  'Coffee',
  'Subscriptions',
  'Gift',
  'Other',
];

const List<String> incomeCategories = [
  'Salary',
  'Freelance',
  'Business',
  'Investment',
  'Rental Income',
  'Bonus',
  'Gift',
  'Other',
];

// ── Currencies ───────────────────────────────────────────────────
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  const CurrencyInfo(this.code, this.name, this.symbol, this.flag);
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo('AED', 'UAE Dirham', 'د.إ', '🇦🇪'),
  CurrencyInfo('AFN', 'Afghan Afghani', '؋', '🇦🇫'),
  CurrencyInfo('ALL', 'Albanian Lek', 'L', '🇦🇱'),
  CurrencyInfo('AMD', 'Armenian Dram', '֏', '🇦🇲'),
  CurrencyInfo('ARS', 'Argentine Peso', '\$', '🇦🇷'),
  CurrencyInfo('AUD', 'Australian Dollar', 'A\$', '🇦🇺'),
  CurrencyInfo('AWG', 'Aruban Florin', 'ƒ', '🇦🇼'),
  CurrencyInfo('AZN', 'Azerbaijani Manat', '₼', '🇦🇿'),
  CurrencyInfo('BAM', 'Bosnia-Herzegovina Convertible Mark', 'KM', '🇧🇦'),
  CurrencyInfo('BBD', 'Barbadian Dollar', '\$', '🇧🇧'),
  CurrencyInfo('BDT', 'Bangladeshi Taka', '৳', '🇧🇩'),
  CurrencyInfo('BGN', 'Bulgarian Lev', 'лв', '🇧🇬'),
  CurrencyInfo('BHD', 'Bahraini Dinar', '.د.ب', '🇧🇭'),
  CurrencyInfo('BND', 'Brunei Dollar', '\$', '🇧🇳'),
  CurrencyInfo('BOB', 'Bolivian Boliviano', 'Bs.', '🇧🇴'),
  CurrencyInfo('BRL', 'Brazilian Real', 'R\$', '🇧🇷'),
  CurrencyInfo('BWP', 'Botswanan Pula', 'P', '🇧🇼'),
  CurrencyInfo('BYN', 'Belarusian Ruble', 'Br', '🇧🇾'),
  CurrencyInfo('CAD', 'Canadian Dollar', 'CA\$', '🇨🇦'),
  CurrencyInfo('CHF', 'Swiss Franc', 'CHF', '🇨🇭'),
  CurrencyInfo('CLP', 'Chilean Peso', '\$', '🇨🇱'),
  CurrencyInfo('CNY', 'Chinese Yuan', '¥', '🇨🇳'),
  CurrencyInfo('COP', 'Colombian Peso', '\$', '🇨🇴'),
  CurrencyInfo('CRC', 'Costa Rican Colón', '₡', '🇨🇷'),
  CurrencyInfo('CUP', 'Cuban Peso', '\$', '🇨🇺'),
  CurrencyInfo('CZK', 'Czech Koruna', 'Kč', '🇨🇿'),
  CurrencyInfo('DKK', 'Danish Krone', 'kr', '🇩🇰'),
  CurrencyInfo('DOP', 'Dominican Peso', '\$', '🇩🇴'),
  CurrencyInfo('DZD', 'Algerian Dinar', 'د.ج', '🇩🇿'),
  CurrencyInfo('EGP', 'Egyptian Pound', '£', '🇪🇬'),
  CurrencyInfo('ETB', 'Ethiopian Birr', 'Br', '🇪🇹'),
  CurrencyInfo('EUR', 'Euro', '€', '🇪🇺'),
  CurrencyInfo('FJD', 'Fijian Dollar', '\$', '🇫🇯'),
  CurrencyInfo('GBP', 'British Pound', '£', '🇬🇧'),
  CurrencyInfo('GEL', 'Georgian Lari', '₾', '🇬🇪'),
  CurrencyInfo('GHS', 'Ghanaian Cedi', '₵', '🇬🇭'),
  CurrencyInfo('GTQ', 'Guatemalan Quetzal', 'Q', '🇬🇹'),
  CurrencyInfo('GYD', 'Guyanaese Dollar', '\$', '🇬🇾'),
  CurrencyInfo('HKD', 'Hong Kong Dollar', 'HK\$', '🇭🇰'),
  CurrencyInfo('HNL', 'Honduran Lempira', 'L', '🇭🇳'),
  CurrencyInfo('HTG', 'Haitian Gourde', 'G', '🇭🇹'),
  CurrencyInfo('HUF', 'Hungarian Forint', 'Ft', '🇭🇺'),
  CurrencyInfo('IDR', 'Indonesian Rupiah', 'Rp', '🇮🇩'),
  CurrencyInfo('ILS', 'Israeli New Shekel', '₪', '🇮🇱'),
  CurrencyInfo('INR', 'Indian Rupee', '₹', '🇮🇳'),
  CurrencyInfo('IQD', 'Iraqi Dinar', 'ع.د', '🇮🇶'),
  CurrencyInfo('IRR', 'Iranian Rial', '﷼', '🇮🇷'),
  CurrencyInfo('ISK', 'Icelandic Króna', 'kr', '🇮🇸'),
  CurrencyInfo('JMD', 'Jamaican Dollar', '\$', '🇯🇲'),
  CurrencyInfo('JOD', 'Jordanian Dinar', 'JD', '🇯🇴'),
  CurrencyInfo('JPY', 'Japanese Yen', '¥', '🇯🇵'),
  CurrencyInfo('KES', 'Kenyan Shilling', 'KSh', '🇰🇪'),
  CurrencyInfo('KGS', 'Kyrgystani Som', 'лв', '🇰🇬'),
  CurrencyInfo('KHR', 'Cambodian Riel', '៛', '🇰🇭'),
  CurrencyInfo('KWD', 'Kuwaiti Dinar', 'KD', '🇰🇼'),
  CurrencyInfo('KZT', 'Kazakhstani Tenge', '₸', '🇰🇿'),
  CurrencyInfo('LAK', 'Laotian Kip', '₭', '🇱🇦'),
  CurrencyInfo('LBP', 'Lebanese Pound', '£', '🇱🇧'),
  CurrencyInfo('LKR', 'Sri Lankan Rupee', '₨', '🇱🇰'),
  CurrencyInfo('MAD', 'Moroccan Dirham', 'MAD', '🇲🇦'),
  CurrencyInfo('MDL', 'Moldovan Leu', 'L', '🇲🇩'),
  CurrencyInfo('MGA', 'Malagasy Ariary', 'Ar', '🇲🇬'),
  CurrencyInfo('MKD', 'Macedonian Denar', 'ден', '🇲🇰'),
  CurrencyInfo('MMK', 'Myanmar Kyat', 'K', '🇲🇲'),
  CurrencyInfo('MNT', 'Mongolian Tugrik', '₮', '🇲🇳'),
  CurrencyInfo('MUR', 'Mauritian Rupee', '₨', '🇲🇺'),
  CurrencyInfo('MVR', 'Maldivian Rufiyaa', 'Rf', '🇲🇻'),
  CurrencyInfo('MXN', 'Mexican Peso', 'MX\$', '🇲🇽'),
  CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM', '🇲🇾'),
  CurrencyInfo('MZN', 'Mozambican Metical', 'MT', '🇲🇿'),
  CurrencyInfo('NAD', 'Namibian Dollar', '\$', '🇳🇦'),
  CurrencyInfo('NGN', 'Nigerian Naira', '₦', '🇳🇬'),
  CurrencyInfo('NIO', 'Nicaraguan Córdoba', 'C\$', '🇳🇮'),
  CurrencyInfo('NOK', 'Norwegian Krone', 'kr', '🇳🇴'),
  CurrencyInfo('NPR', 'Nepalese Rupee', '₨', '🇳🇵'),
  CurrencyInfo('NZD', 'New Zealand Dollar', 'NZ\$', '🇳🇿'),
  CurrencyInfo('OMR', 'Omani Rial', '﷼', '🇴🇲'),
  CurrencyInfo('PAB', 'Panamanian Balboa', 'B/.', '🇵🇦'),
  CurrencyInfo('PEN', 'Peruvian Sol', 'S/.', '🇵🇪'),
  CurrencyInfo('PHP', 'Philippine Peso', '₱', '🇵🇭'),
  CurrencyInfo('PKR', 'Pakistani Rupee', '₨', '🇵🇰'),
  CurrencyInfo('PLN', 'Polish Zloty', 'zł', '🇵🇱'),
  CurrencyInfo('PYG', 'Paraguayan Guarani', 'Gs', '🇵🇾'),
  CurrencyInfo('QAR', 'Qatari Rial', '﷼', '🇶🇦'),
  CurrencyInfo('RON', 'Romanian Leu', 'lei', '🇷🇴'),
  CurrencyInfo('RSD', 'Serbian Dinar', 'din', '🇷🇸'),
  CurrencyInfo('SAR', 'Saudi Riyal', '﷼', '🇸🇦'),
  CurrencyInfo('SEK', 'Swedish Krona', 'kr', '🇸🇪'),
  CurrencyInfo('SGD', 'Singapore Dollar', 'S\$', '🇸🇬'),
  CurrencyInfo('SRD', 'Surinamese Dollar', '\$', '🇸🇷'),
  CurrencyInfo('THB', 'Thai Baht', '฿', '🇹🇭'),
  CurrencyInfo('TJS', 'Tajikistani Somoni', 'SM', '🇹🇯'),
  CurrencyInfo('TND', 'Tunisian Dinar', 'DT', '🇹🇳'),
  CurrencyInfo('TRY', 'Turkish Lira', '₺', '🇹🇷'),
  CurrencyInfo('TTD', 'Trinidad & Tobago Dollar', '\$', '🇹🇹'),
  CurrencyInfo('TWD', 'New Taiwan Dollar', 'NT\$', '🇹🇼'),
  CurrencyInfo('TZS', 'Tanzanian Shilling', 'TSh', '🇹🇿'),
  CurrencyInfo('UAH', 'Ukrainian Hryvnia', '₴', '🇺🇦'),
  CurrencyInfo('UGX', 'Ugandan Shilling', 'USh', '🇺🇬'),
  CurrencyInfo('USD', 'US Dollar', '\$', '🇺🇸'),
  CurrencyInfo('UYU', 'Uruguayan Peso', '\$U', '🇺🇾'),
  CurrencyInfo('UZS', 'Uzbekistani Som', 'лв', '🇺🇿'),
  CurrencyInfo('VND', 'Vietnamese Dong', '₫', '🇻🇳'),
  CurrencyInfo('WST', 'Samoan Tala', 'WS\$', '🇼🇸'),
  CurrencyInfo('XAF', 'Central African CFA Franc', 'FCFA', '🌍'),
  CurrencyInfo('XOF', 'West African CFA Franc', 'CFA', '🌍'),
  CurrencyInfo('YER', 'Yemeni Rial', '﷼', '🇾🇪'),
  CurrencyInfo('ZAR', 'South African Rand', 'R', '🇿🇦'),
  CurrencyInfo('ZMW', 'Zambian Kwacha', 'ZK', '🇿🇲'),
];
