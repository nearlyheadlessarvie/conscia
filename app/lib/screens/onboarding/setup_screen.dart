import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/widgets/currency_picker_sheet.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late String _currencyCode;
  late String _locale;

  static const _locales = [
    ('en_US', 'English (US)', '🇺🇸'),
    ('en_GB', 'English (UK)', '🇬🇧'),
    ('es_MX', 'Español (MX)', '🇲🇽'),
    ('es_ES', 'Español (ES)', '🇪🇸'),
    ('fr_FR', 'Français', '🇫🇷'),
    ('de_DE', 'Deutsch', '🇩🇪'),
    ('pt_BR', 'Português (BR)', '🇧🇷'),
    ('ja_JP', '日本語', '🇯🇵'),
    ('zh_CN', '中文 (简体)', '🇨🇳'),
  ];

  @override
  void initState() {
    super.initState();
    final defaults = deviceDefaults();
    _locale = defaults.locale;
    _currencyCode = defaults.currency;
  }

  String _formattedSample() {
    final format = NumberFormat.currency(
      locale: _locale.replaceAll('_', '-'),
      symbol: _currencyCode,
      decimalDigits: 2,
    );
    return format.format(1234.56);
  }

  String _localeName() {
    final match = _locales.where((l) => l.$1 == _locale);
    if (match.isNotEmpty) return match.first.$2;
    return _locale;
  }

  String _currencyForLocale(String locale) {
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
    final parts = locale.split('_');
    final countryCode = parts.length > 1 ? parts[1].toUpperCase() : 'US';
    return countryToCurrency[countryCode] ?? 'USD';
  }

  void _openCurrencyPicker() {
    CurrencyPickerSheet.show(
      context,
      selectedCode: _currencyCode,
      onSelected: (code) => setState(() => _currencyCode = code),
    );
  }

  void _openLocalePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Region',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final locale in _locales)
              ListTile(
                leading: Text(locale.$3, style: const TextStyle(fontSize: 24)),
                title: Text(locale.$2),
                trailing: locale.$1 == _locale
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _locale = locale.$1;
                    _currencyCode = _currencyForLocale(locale.$1);
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                leading: const Icon(Icons.monetization_on_outlined),
                title: const Text('Currency'),
                subtitle: Text(_currencyCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openCurrencyPicker,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                leading: const Icon(Icons.language),
                title: const Text('Region'),
                subtitle: Text(_localeName()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openLocalePicker,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Preview', style: textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(
                        _formattedSample(),
                        style: textTheme.headlineLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final userService = ref.read(userServiceProvider);
                      await userService.updateProfile(
                        preferredCurrency: _currencyCode,
                        locale: _locale,
                      );
                      ref.invalidate(currentUserProvider);
                    } catch (_) {
                      // Best-effort save; user can update later in Settings
                    }
                    if (!mounted) return;
                    GoRouter.of(this.context).go('/onboarding/profile');
                  },
                  child: const Text("Let's Go!"),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
