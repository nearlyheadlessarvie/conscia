import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/single_select_list.dart';
import 'widgets/onboarding_step_scaffold.dart';

class SpendingProfileScreen extends ConsumerStatefulWidget {
  final String? initialCurrencyCode;
  final String? initialLocale;

  const SpendingProfileScreen({
    super.key,
    this.initialCurrencyCode,
    this.initialLocale,
  });

  @override
  ConsumerState<SpendingProfileScreen> createState() =>
      _SpendingProfileScreenState();
}

class _SpendingProfileScreenState extends ConsumerState<SpendingProfileScreen> {
  String _personality = 'balanced';
  String? _incomeRange;
  bool _saving = false;
  bool _showIncomeRequired = false;

  static const _incomeOptions = [
    ('low', 20000.0, 'Under'),
    ('mid', 50000.0, 'Up to'),
    ('high', 100000.0, 'Up to'),
    ('very_high', 100000.0, 'Over'),
    ('prefer_not_to_say', 0.0, 'Prefer not to say'),
  ];

  Future<void> _persistSelection({String? incomeRangeOverride}) async {
    final service = ref.read(userServiceProvider);
    await service.updateProfile(
      spendingPersonality: _personality,
      incomeRange: incomeRangeOverride ?? _incomeRange,
    );
  }

  Future<void> _next() async {
    if (_incomeRange == null) {
      setState(() => _showIncomeRequired = true);
      return;
    }
    setState(() => _saving = true);
    final incomeRange = _incomeRange!;
    try {
      await _persistSelection(incomeRangeOverride: incomeRange);
    } catch (_) {}
    if (!mounted) return;
    context.go(
      AppRoutes.suggestedBudgets,
      extra: {
        'spendingPersonality': _personality,
        'incomeRange': incomeRange,
      },
    );
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      await _persistSelection();
    } catch (_) {}
    if (!mounted) return;
    context.go(AppRoutes.aboutYou);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final currencyCode = widget.initialCurrencyCode ?? prefs.currency;
    final locale = widget.initialLocale ?? prefs.locale;
    final formatter = NumberFormat.currency(
      locale: locale.replaceAll('_', '-'),
      symbol: '$currencyCode ',
      decimalDigits: 0,
    );

    return OnboardingStepScaffold(
      appBarTitle: 'Spending Profile',
      stepLabel: 'Step 1 of 3',
      heroTitle: 'Shape your money starting point',
      heroSubtitle:
          'A quick read on your default rhythm helps Conscia suggest budgets that feel realistic.',
      heroChips: const [
        OnboardingHeroChip(label: '2 minute setup', icon: Icons.timer_outlined),
        OnboardingHeroChip(label: 'Editable later', icon: Icons.tune_rounded),
      ],
      actions: [
        IconButton(
          tooltip: 'Skip',
          onPressed: _saving ? null : _skip,
          icon: Icon(
            AppIcons.chevronRight,
            color: Theme.of(context).appColors.deepNavy,
          ),
        ),
      ],
      bottom: FilledButton(
        onPressed: _saving ? null : _next,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Next'),
      ),
      children: [
        ScreenSection(
          title: 'Spending style',
          subtitle:
              'Choose the one that feels closest to your default spending instinct.',
          child: SingleSelectList<String>(
            value: _personality,
            options: const ['saver', 'balanced', 'free_spender'],
            titleBuilder: (option) => switch (option) {
              'saver' => 'Planner',
              'free_spender' => 'Flexible',
              _ => 'Balanced',
            },
            subtitleBuilder: (option) => switch (option) {
              'saver' => 'I like clear limits and steady progress',
              'free_spender' => 'I want room for spontaneous choices',
              _ => 'I want structure without feeling boxed in',
            },
            leadingBuilder: (context, option, selected) =>
                AppIcons.spendingStyleBadge(
              option,
              size: 30,
              selected: selected,
            ),
            onChanged: (value) => setState(() => _personality = value),
          ),
        ),
        ScreenSection(
          title: 'Monthly income',
          subtitle:
              'Required for suggestions. Choose Prefer not to say if you want to keep this private.',
          child: OnboardingGroupedOptionList<(String, double, String)>(
            options: _incomeOptions,
            value: _selectedIncomeOption(),
            labelBuilder: (option) => switch (option.$1) {
              'low' => '${option.$3} ${formatter.format(option.$2)}',
              'mid' =>
                '${formatter.format(20000)} - ${formatter.format(option.$2)}',
              'high' =>
                '${formatter.format(50000)} - ${formatter.format(option.$2)}',
              'very_high' => '${option.$3} ${formatter.format(option.$2)}',
              _ => option.$3,
            },
            onChanged: (option) => setState(() {
              _incomeRange = option.$1;
              _showIncomeRequired = false;
            }),
          ),
        ),
        if (_showIncomeRequired)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: OnboardingInlineNote(
              message:
                  'Choose a monthly income range, or select Prefer not to say.',
            ),
          ),
      ],
    );
  }

  (String, double, String)? _selectedIncomeOption() {
    for (final option in _incomeOptions) {
      if (option.$1 == _incomeRange) return option;
    }
    return null;
  }
}
