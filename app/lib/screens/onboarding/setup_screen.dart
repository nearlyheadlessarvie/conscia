import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conscia_app/core/theme/app_colors.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/widgets/currency_picker_sheet.dart';
import 'package:conscia_app/widgets/inline_notice.dart';
import 'package:conscia_app/widgets/locale_picker_sheet.dart';
import 'package:conscia_app/widgets/screen_section.dart';

import 'widgets/onboarding_step_scaffold.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late String _currencyCode;
  late String _locale;
  late String _deviceCurrencyCode;

  static const _regionLabels = {
    'en_US': 'Default',
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
    return _regionLabels[_locale] ?? 'Default';
  }

  void _openCurrencyPicker() {
    CurrencyPickerSheet.show(
      context,
      selectedCode: _currencyCode,
      priorityCode: _deviceCurrencyCode,
      isPremium: true,
      onSelected: (code) => setState(() {
        _currencyCode = code;
      }),
    );
  }

  void _openLocalePicker() {
    LocalePickerSheet.show(
      context,
      selectedLocale: _locale,
      onSelected: (locale) => setState(() {
        _locale = locale;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return OnboardingStepScaffold(
      appBarTitle: 'Set Up Your Profile',
      stepLabel: 'Before we start',
      heroTitle: 'Make money feel native',
      heroSubtitle:
          'Choose the currency and number format Conscia should use from the first screen onward.',
      heroChips: [
        OnboardingHeroChip(label: '$_currencyCode currency'),
        OnboardingHeroChip(label: '${_localeName()} numbers'),
      ],
      bottom: FilledButton(
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
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: const Text("Let's Go!"),
      ),
      children: [
        ScreenSection(
          title: 'Your defaults',
          subtitle:
              'These only affect currency, numbers, and dates. App language stays English.',
          child: OnboardingActionList(
            children: [
              _SetupActionRow(
                icon: Icons.monetization_on_outlined,
                label: 'Currency',
                value: _currencyCode,
                onTap: _openCurrencyPicker,
              ),
              _SetupActionRow(
                icon: Icons.language,
                label: 'Region Format',
                value: _localeName(),
                onTap: _openLocalePicker,
              ),
            ],
          ),
        ),
        const InlineNotice(
          message:
              'Changes how numbers and dates are shown. App language stays in English.',
          tone: InlineNoticeTone.info,
          icon: Icon(Icons.info_outline_rounded),
        ),
        const SizedBox(height: 22),
        ScreenSection(
          title: 'Preview',
          compact: true,
          child: Center(
            child: Text(
              _formattedSample(),
              style: textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).appColors.deepNavy,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupActionRow extends StatelessWidget {
  const _SetupActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.navySoft.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: colors.deepNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.mutedInk,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.deepNavy.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
