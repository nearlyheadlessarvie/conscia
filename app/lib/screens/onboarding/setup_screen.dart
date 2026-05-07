import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/widgets/currency_picker_sheet.dart';
import 'package:conscia_app/widgets/feed_card.dart';
import 'package:conscia_app/widgets/hero_screen_scaffold.dart';
import 'package:conscia_app/widgets/locale_picker_sheet.dart';
import 'package:conscia_app/widgets/screen_section.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late String _currencyCode;
  late String _locale;
  late String _deviceCurrencyCode;

  @override
  void initState() {
    super.initState();
    final defaults = deviceDefaults();
    _locale = defaults.locale;
    _currencyCode = defaults.currency;
    _deviceCurrencyCode = defaults.currency;
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
    final display = {
      'en_US': 'English (US)',
      'en_GB': 'English (UK)',
      'es_MX': 'Español (México)',
      'es_ES': 'Español (España)',
      'fr_FR': 'Français',
      'de_DE': 'Deutsch',
      'pt_BR': 'Português (Brasil)',
      'ja_JP': '日本語',
      'zh_CN': '中文 (简体)',
      'ko_KR': '한국어',
    };
    return display[_locale] ?? _locale;
  }

  void _openCurrencyPicker() {
    CurrencyPickerSheet.show(
      context,
      selectedCode: _currencyCode,
      priorityCode: _deviceCurrencyCode,
      isPremium: true,
      onSelected: (code) => setState(() => _currencyCode = code),
    );
  }

  void _openLocalePicker() {
    LocalePickerSheet.show(
      context,
      selectedLocale: _locale,
      onSelected: (locale) => setState(() => _locale = locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return HeroScreenScaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
      ),
      bottom: SizedBox(
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
            GoRouter.of(this.context).go(
              '/onboarding/profile',
              extra: {
                'currencyCode': _currencyCode,
                'locale': _locale,
              },
            );
          },
          child: const Text("Let's Go!"),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          ScreenSection(
            title: 'Your defaults',
            subtitle:
                'Pick the currency and number format that should feel native from the very first screen.',
            child: Column(
              children: [
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
              ],
            ),
          ),
          FeedCard(
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
        ],
      ),
    );
  }
}
