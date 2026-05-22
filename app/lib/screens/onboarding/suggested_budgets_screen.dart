import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/constants/category_visibility.dart';
import '../../core/constants/generated/app_constants.g.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/localized_number_input.dart';
import '../../providers/budget_providers.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/budget_service.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/screen_section.dart';
import 'widgets/onboarding_step_scaffold.dart';

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
  String? _errorMessage;

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
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConsciaSheetHandle(),
            const SizedBox(height: 18),
            ConsciaSheetHeader(
              title: 'Edit ${draft.categoryName}',
              subtitle:
                  'Set the monthly limit for this suggested budget category.',
            ),
            const SizedBox(height: 16),
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
      builder: (context) => _BudgetCategorySheet(
        selectedCategories: _drafts.map((draft) => draft.categoryName).toSet(),
        onSelected: (category) {
          setState(() {
            _drafts.add(_BudgetDraft(categoryName: category, amount: 0));
            _errorMessage = null;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _createBudgets() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
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
      setState(() => _errorMessage = error.userMessage);
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
    final total = _drafts.fold<double>(
      0,
      (sum, draft) => sum + (ratesAvailable ? draft.amount : 0),
    );

    return OnboardingStepScaffold(
      appBarTitle: 'Suggested Budgets',
      stepLabel: 'Step 2 of 3',
      heroTitle: 'Your first budget map',
      heroSubtitle:
          'Based on ${_personalityLabel(widget.spendingPersonality)} · ${_incomeLabel(widget.incomeRange)}. Tune anything before Conscia creates the set.',
      heroChips: [
        OnboardingHeroChip(
          label: ratesAvailable ? formatter.format(total) : 'Preparing totals',
          icon: AppIconKey.walletOutline,
        ),
        OnboardingHeroChip(
          label: '${_drafts.length} categories',
          icon: AppIconKey.label,
        ),
        const OnboardingHeroChip(
          label: 'Editable',
          icon: AppIconKey.tune,
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Skip',
          onPressed: _saving ? null : _skip,
          icon: AppIcons.icon(
            AppIconKey.chevronRight,
            color: Theme.of(context).appColors.deepNavy,
            size: 20,
          ),
        ),
      ],
      bottom: FilledButton(
        onPressed: ratesAvailable && !_saving ? _createBudgets : null,
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
            : const Text('Create budgets'),
      ),
      children: [
        if (helperText != null) ...[
          Text(
            helperText,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
        ScreenSection(
          title: 'Budget set',
          subtitle:
              'Tap a row to adjust the monthly cap before creating budgets.',
          child: OnboardingActionList(
            children: [
              ..._drafts.asMap().entries.map((entry) {
                final index = entry.key;
                final draft = entry.value;
                return _SuggestedBudgetRow(
                  categoryName: draft.categoryName,
                  amountLabel:
                      ratesAvailable ? formatter.format(draft.amount) : '—',
                  enabled: ratesAvailable,
                  onTap: () => _editAmount(index),
                );
              }),
              _AddBudgetCategoryRow(onTap: _addCategory),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          OnboardingInlineNote(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
      ],
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

class _BudgetCategorySheet extends StatefulWidget {
  const _BudgetCategorySheet({
    required this.selectedCategories,
    required this.onSelected,
  });

  final Set<String> selectedCategories;
  final ValueChanged<String> onSelected;

  @override
  State<_BudgetCategorySheet> createState() => _BudgetCategorySheetState();
}

class _BudgetCategorySheetState extends State<_BudgetCategorySheet> {
  String? _notice;

  @override
  Widget build(BuildContext context) {
    final categories = visibleBudgetCategories(
      isPremium: true,
      categories: expenseCategories,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: ConsciaSheetHandle(),
              ),
              const SizedBox(height: 20),
              const ConsciaSheetHeader(
                title: 'Add budget category',
                subtitle:
                    'Pick another category to include in your first budget set.',
              ),
              if (_notice != null) ...[
                const SizedBox(height: 14),
                OnboardingInlineNote(message: _notice!),
              ],
              const SizedBox(height: 18),
              OnboardingActionList(
                children: [
                  for (final category in categories)
                    _BudgetCategoryOptionRow(
                      categoryName: category,
                      alreadyAdded:
                          widget.selectedCategories.contains(category),
                      onTap: () {
                        if (widget.selectedCategories.contains(category)) {
                          setState(
                            () => _notice =
                                '$category is already in your budget set.',
                          );
                          return;
                        }
                        widget.onSelected(category);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCategoryOptionRow extends StatelessWidget {
  const _BudgetCategoryOptionRow({
    required this.categoryName,
    required this.alreadyAdded,
    required this.onTap,
  });

  final String categoryName;
  final bool alreadyAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Opacity(
              opacity: alreadyAdded ? 0.48 : 1,
              child: CategoryIcons.badge(
                categoryName,
                size: AppLayout.listIconSize,
                type: 'Expense',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                categoryName,
                style: textTheme.bodyLarge?.copyWith(
                  color: alreadyAdded ? colors.mutedInk : colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (alreadyAdded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.navySoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Added',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              AppIcons.icon(
                AppIconKey.add,
                size: 20,
                color: colors.deepNavy,
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedBudgetRow extends StatelessWidget {
  const _SuggestedBudgetRow({
    required this.categoryName,
    required this.amountLabel,
    required this.enabled,
    required this.onTap,
  });

  final String categoryName;
  final String amountLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CategoryIcons.badge(
              categoryName,
              size: AppLayout.listIconSize,
              type: 'Expense',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountLabel,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            AppIcons.icon(
              AppIconKey.chevronRight,
              size: 18,
              color: enabled
                  ? colors.deepNavy.withValues(alpha: 0.54)
                  : colors.softInk.withValues(alpha: 0.48),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetCategoryRow extends StatelessWidget {
  const _AddBudgetCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: AppLayout.listIconSize + 12,
              height: AppLayout.listIconSize + 12,
              decoration: BoxDecoration(
                color: colors.navySoft.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: AppIcons.icon(
                  AppIconKey.add,
                  size: 19,
                  color: colors.deepNavy,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Add category',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppIcons.icon(
              AppIconKey.chevronRight,
              size: 18,
              color: colors.deepNavy.withValues(alpha: 0.54),
            ),
          ],
        ),
      ),
    );
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
