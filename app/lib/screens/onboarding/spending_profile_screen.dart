import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/selection_card_group.dart';

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
    setState(() => _saving = true);
    final incomeRange = _incomeRange ?? 'prefer_not_to_say';
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = ref.watch(userPreferencesProvider);
    final currencyCode = widget.initialCurrencyCode ?? prefs.currency;
    final locale = widget.initialLocale ?? prefs.locale;
    final formatter = NumberFormat.currency(
      locale: locale.replaceAll('_', '-'),
      symbol: '$currencyCode ',
      decimalDigits: 0,
    );

    return HeroScreenScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Spending Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _saving ? null : _next,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 1 of 3',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text('How do you spend?', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Helps us suggest realistic budgets.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          ScreenSection(
            title: 'Spending style',
            subtitle:
                'Choose the one that feels closest to your default spending instinct.',
            child: SelectionCardGroup<String>(
              value: _personality,
              options: const ['saver', 'balanced', 'free_spender'],
              semantics: SelectionCardSemantics.radio,
              titleBuilder: (option) => switch (option) {
                'saver' => 'Saver',
                'free_spender' => 'Free spender',
                _ => 'Balanced',
              },
              subtitleBuilder: (option) => switch (option) {
                'saver' => 'Careful, deliberate, goal-focused',
                'free_spender' => 'Live in the moment, worry later',
                _ => 'Mix of saving and enjoying money',
              },
              leadingBuilder: (option, selected) => AppIcons.spendingStyleBadge(
                option,
                size: 24,
                selected: selected,
              ),
              onChanged: (value) => setState(() => _personality = value),
            ),
          ),
          ScreenSection(
            title: 'Monthly income',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _incomeOptions.map((option) {
                final selected = _incomeRange == option.$1;
                final label = switch (option.$1) {
                  'low' => '${option.$3} ${formatter.format(option.$2)}',
                  'mid' =>
                    '${formatter.format(20000)} - ${formatter.format(option.$2)}',
                  'high' =>
                    '${formatter.format(50000)} - ${formatter.format(option.$2)}',
                  'very_high' => '${option.$3} ${formatter.format(option.$2)}',
                  _ => option.$3,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _incomeRange = option.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? colors.primary : colors.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        color:
                            selected ? colors.primaryContainer : colors.surface,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(label)),
                          if (selected)
                            Icon(AppIcons.check,
                                size: 18, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
