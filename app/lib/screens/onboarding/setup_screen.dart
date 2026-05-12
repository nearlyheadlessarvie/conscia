import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/widgets/currency_picker_sheet.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:conscia_app/widgets/hero_screen_scaffold.dart';
import 'package:conscia_app/widgets/inline_notice.dart';
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
  late final TextEditingController _currencyController;
  late final TextEditingController _localeController;

  static const _regionLabels = {
    'en_US': 'Philippines / US',
    'de_DE': 'European',
    'fr_FR': 'French / Swiss',
    'en_IN': 'Indian',
  };

  @override
  void initState() {
    super.initState();
    final defaults = deviceDefaults();
    _locale = defaults.locale;
    _currencyCode = defaults.currency;
    _deviceCurrencyCode = defaults.currency;
    _currencyController = TextEditingController(text: _currencyCode);
    _localeController = TextEditingController(text: _localeName());
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _localeController.dispose();
    super.dispose();
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
    return _regionLabels[_locale] ?? 'Philippines / US';
  }

  void _openCurrencyPicker() {
    CurrencyPickerSheet.show(
      context,
      selectedCode: _currencyCode,
      priorityCode: _deviceCurrencyCode,
      isPremium: true,
      onSelected: (code) => setState(() {
        _currencyCode = code;
        _currencyController.text = code;
      }),
    );
  }

  void _openLocalePicker() {
    LocalePickerSheet.show(
      context,
      selectedLocale: _locale,
      onSelected: (locale) => setState(() {
        _locale = locale;
        _localeController.text = _localeName();
      }),
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
                'Pick the currency and region format that should feel native from the very first screen.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FloatingLabelTextField(
                  controller: _currencyController,
                  label: 'Currency',
                  prefix: const Icon(Icons.monetization_on_outlined),
                  readOnly: true,
                  onTap: _openCurrencyPicker,
                  trailing: const Icon(Icons.expand_more_rounded),
                ),
                const SizedBox(height: 16),
                FloatingLabelTextField(
                  controller: _localeController,
                  label: 'Region Format',
                  prefix: const Icon(Icons.language),
                  readOnly: true,
                  onTap: _openLocalePicker,
                  trailing: const Icon(Icons.expand_more_rounded),
                ),
              ],
            ),
          ),
          InlineNotice(
            message:
                'Changes how numbers and dates are shown. App language stays in English.',
            tone: InlineNoticeTone.info,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        ],
      ),
    );
  }
}
