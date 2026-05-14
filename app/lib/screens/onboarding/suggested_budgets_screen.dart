import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/localized_number_input.dart';
import '../../providers/budget_providers.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/budget_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../transactions/widgets/category_picker.dart';

class SuggestedBudgetsScreen extends ConsumerStatefulWidget {
  final String spendingPersonality;
  final String incomeRange;

  const SuggestedBudgetsScreen({
    super.key,
    required this.spendingPersonality,
    required this.incomeRange,
  });

  @override
  ConsumerState<SuggestedBudgetsScreen> createState() =>
      _SuggestedBudgetsScreenState();
}

class _SuggestedBudgetsScreenState
    extends ConsumerState<SuggestedBudgetsScreen> {
  final List<_BudgetDraft> _drafts = [];
  bool _budgetsInitialised = false;
  bool _saving = false;

  static const _midpoints = {
    'low': 300.0,
    'mid': 700.0,
    'high': 1400.0,
    'very_high': 2500.0,
    'prefer_not_to_say': 700.0,
  };

  static const _factors = {
    'saver': 0.60,
    'balanced': 0.70,
    'free_spender': 0.85,
  };

  static const _weights = {
    'saver': {
      'Groceries': 0.28,
      'Bills': 0.25,
      'Transport': 0.15,
      'Health': 0.15,
      'Dining': 0.10,
    },
    'balanced': {
      'Groceries': 0.28,
      'Bills': 0.20,
      'Dining': 0.18,
      'Transport': 0.14,
      'Shopping': 0.10,
    },
    'free_spender': {
      'Dining': 0.22,
      'Groceries': 0.15,
      'Shopping': 0.15,
      'Entertainment': 0.14,
      'Bills': 0.12,
    },
  };

  Future<void> _skip() async {
    context.go(AppRoutes.aboutYou);
  }

  Future<void> _editAmount(int index) async {
    final draft = _drafts[index];
    final locale = ref.read(userPreferencesProvider).locale;
    final controller = TextEditingController(
      text: draft.amount > 0
          ? LocalizedNumberInput.formatForInput(
              draft.amount,
              locale: locale,
              decimalDigits: 0,
            )
          : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${draft.categoryName}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [LocalizedNumberInput.formatter(locale)],
              decoration: const InputDecoration(labelText: 'Monthly limit'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final value = LocalizedNumberInput.parseAmount(
                  controller.text,
                  locale: locale,
                );
                if (value != null) {
                  setState(
                      () => _drafts[index] = draft.copyWith(amount: value));
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: CategoryPicker(
              selected: null,
              maxVisible: 100,
              onSelected: (category) {
                if (_drafts.any((draft) => draft.categoryName == category)) {
                  Navigator.of(context).pop();
                  return;
                }
                setState(() {
                  _drafts.add(_BudgetDraft(categoryName: category, amount: 0));
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createBudgets() async {
    if (_saving) return;
    setState(() => _saving = true);
    final currencyCode = ref.read(userPreferencesProvider).currency;
    final notifier = ref.read(budgetListProvider.notifier);

    try {
      for (final draft in _drafts.where((draft) => draft.amount > 0)) {
        await notifier.create(
          CreateBudgetDto(
            category: draft.categoryName,
            monthlyLimit: draft.amount,
            currencyCode: currencyCode,
          ),
        );
      }
      if (!mounted) return;
      context.go(AppRoutes.aboutYou);
    } catch (e, s) {
      if (!mounted) return;
      setState(() => _saving = false);
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = ref.watch(userPreferencesProvider);
    final currencyCode = prefs.currency;
    final formatter = NumberFormat.currency(
      locale: prefs.locale.replaceAll('_', '-'),
      symbol: '$currencyCode ',
      decimalDigits: 0,
    );

    if (currencyCode == 'USD') {
      _initialiseDraftsIfNeeded(1.0);
      return _buildScaffold(
        context,
        textTheme,
        colors,
        formatter,
        ratesAvailable: true,
      );
    }

    final rateAsync = ref.watch(exchangeRateProvider(('USD', currencyCode)));
    return rateAsync.when(
      loading: () => _buildScaffold(
        context,
        textTheme,
        colors,
        formatter,
        ratesAvailable: false,
        helperText: 'Loading exchange rates...',
      ),
      error: (_, __) => _buildScaffold(
        context,
        textTheme,
        colors,
        formatter,
        ratesAvailable: false,
        helperText: 'Rates unavailable',
      ),
      data: (rate) {
        final ratesAvailable = rate != null;
        if (ratesAvailable) {
          _initialiseDraftsIfNeeded(rate);
        }
        return _buildScaffold(
          context,
          textTheme,
          colors,
          formatter,
          ratesAvailable: ratesAvailable,
          helperText: ratesAvailable ? null : 'Rates unavailable',
        );
      },
    );
  }

  void _initialiseDraftsIfNeeded(double rate) {
    if (_budgetsInitialised) return;
    final midpoint = _midpoints[widget.incomeRange] ?? _midpoints['mid']!;
    final factor =
        _factors[widget.spendingPersonality] ?? _factors['balanced']!;
    final weights =
        _weights[widget.spendingPersonality] ?? _weights['balanced']!;
    final spendable = midpoint * rate * factor;

    _drafts
      ..clear()
      ..addAll(
        weights.entries.map(
          (entry) => _BudgetDraft(
            categoryName: entry.key,
            amount: (spendable * entry.value),
          ),
        ),
      );
    _budgetsInitialised = true;
  }

  Widget _buildScaffold(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colors,
    NumberFormat formatter, {
    required bool ratesAvailable,
    String? helperText,
  }) {
    return Scaffold(
      appBar: ConsciaAppBar(
        automaticallyImplyLeading: false,
        title: const Text('Suggested Budgets'),
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
                'Step 2 of 3',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text('Your suggested budgets', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Based on ${_personalityLabel(widget.spendingPersonality)} · ${_incomeLabel(widget.incomeRange)}.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (helperText != null) ...[
                const SizedBox(height: 8),
                Text(
                  helperText,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ..._drafts.asMap().entries.map((entry) {
                final index = entry.key;
                final draft = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CategoryIcons.badge(
                      draft.categoryName,
                      size: 18,
                    ),
                    title: Text(draft.categoryName),
                    trailing: TextButton(
                      onPressed:
                          ratesAvailable ? () => _editAmount(index) : null,
                      child: Text(
                        ratesAvailable ? formatter.format(draft.amount) : '—',
                      ),
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCategory,
                  icon: Icon(AppIcons.add, size: 16),
                  label: const Text('Add category'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: ratesAvailable && !_saving ? _createBudgets : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create budgets'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _personalityLabel(String value) {
    return switch (value) {
      'saver' => 'Saver',
      'free_spender' => 'Free spender',
      _ => 'Balanced',
    };
  }

  String _incomeLabel(String value) {
    return switch (value) {
      'low' => 'Lower income',
      'high' => 'Higher income',
      'very_high' => 'Very high income',
      'prefer_not_to_say' => 'Prefer not to say',
      _ => 'Mid income',
    };
  }
}

class _BudgetDraft {
  final String categoryName;
  final double amount;

  const _BudgetDraft({
    required this.categoryName,
    required this.amount,
  });

  _BudgetDraft copyWith({
    String? categoryName,
    double? amount,
  }) {
    return _BudgetDraft(
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
    );
  }
}
