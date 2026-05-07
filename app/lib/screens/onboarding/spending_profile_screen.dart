import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';

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

    return Scaffold(
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  _personalityCard(
                    context,
                    value: 'saver',
                    label: 'Saver',
                    icon: AppIcons.saver,
                  ),
                  const SizedBox(width: 8),
                  _personalityCard(
                    context,
                    value: 'balanced',
                    label: 'Balanced',
                    icon: AppIcons.balanced,
                  ),
                  const SizedBox(width: 8),
                  _personalityCard(
                    context,
                    value: 'free_spender',
                    label: 'Free spender',
                    icon: AppIcons.freeSpender,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Monthly income',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._incomeOptions.map((option) {
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
                          color: selected ? colors.primary : colors.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        color: selected ? colors.primaryContainer : colors.surface,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(label)),
                          if (selected)
                            Icon(AppIcons.check, size: 18, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 28),
              FilledButton(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _personalityCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = _personality == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _personality = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colors.primaryContainer : colors.surface,
          ),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
