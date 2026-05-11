import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../providers/alert_provider.dart';
import '../../providers/budget_providers.dart';
import '../../providers/category_recents_provider.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/family_space_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../models/recurring_schedule.dart';
import '../../services/transaction_service.dart';
import '../../widgets/amount_input_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/recurring_schedule_section.dart';
import '../../widgets/scope_selector.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/smart_suggestions_card.dart';
import 'widgets/transaction_style_category_selector.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? initialAmount;
  final String? initialCurrencyCode;
  final String? initialCategory;
  final String? initialCounterparty;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.initialAmount,
    this.initialCurrencyCode,
    this.initialCategory,
    this.initialCounterparty,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool get _isEditing => widget.transactionId != null;

  bool _categoryExpanded = true;
  bool _detailsExpanded = true;
  bool _recurringExpanded = false;
  bool _isExpense = true;
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String _currencyCode = 'USD';
  bool _currencyManuallyChanged = false;
  String? _selectedCategory;
  final _counterpartyController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _submitting = false;
  bool _prefilled = false;
  bool _hasCheckedLocationPrompt = false;
  Transaction? _originalTransaction;
  bool _recurringEnabled = false;
  String _recurringCadence = 'Monthly';
  DateTime? _recurringEndDate;
  String _scope = 'personal';

  @override
  void initState() {
    super.initState();
    _currencyCode = ref.read(userPreferencesProvider).currency;
    ref.read(budgetListProvider);
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEditData();
      });
    } else {
      _applyInitialPrefill();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePromptForLocationAssistance();
      });
    }
  }

  void _applyInitialPrefill() {
    if (widget.initialAmount case final amount? when amount.trim().isNotEmpty) {
      _amountController.text = amount;
    }
    if (widget.initialCurrencyCode case final currencyCode?
        when currencyCode.trim().isNotEmpty) {
      _currencyCode = currencyCode;
      _currencyManuallyChanged = true;
    }
    if (widget.initialCategory case final category?
        when category.trim().isNotEmpty) {
      _selectedCategory = category;
    }
    if (widget.initialCounterparty case final counterparty?
        when counterparty.trim().isNotEmpty) {
      _counterpartyController.text = counterparty;
    }
  }

  Future<void> _maybePromptForLocationAssistance() async {
    if (_hasCheckedLocationPrompt || _isEditing || !mounted) {
      return;
    }
    _hasCheckedLocationPrompt = true;

    final state = ref.read(locationAssistanceProvider);
    if (!state.shouldPromptOnFeatureOpen) return;

    final accepted = await LocationAssistancePromptSheet.show(context);

    if (!mounted) return;

    final notifier = ref.read(locationAssistanceProvider.notifier);
    if (accepted ?? false) {
      await notifier.enableFromPrompt();
    } else {
      await notifier.declinePrompt();
    }
  }

  Future<void> _loadEditData() async {
    try {
      final service = ref.read(transactionServiceProvider);
      final tx = await service.getById(widget.transactionId!);
      if (!mounted) return;
      setState(() {
        _originalTransaction = tx;
        _prefilled = true;
        _isExpense = tx.type != 'income';
        _amountController.text = tx.amount.toStringAsFixed(2);
        _currencyCode = tx.currencyCode;
        _currencyManuallyChanged = true;
        _selectedCategory = tx.category;
        _counterpartyController.text = tx.description;
        _selectedDate = tx.date;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _counterpartyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final userCurrency = ref.read(userPreferencesProvider).currency;
    final rateOverride = double.tryParse(_exchangeRateController.text);
    final familySpace = ref.read(familySpaceProvider).valueOrNull;
    final isFamilyScope = _scope == 'family' && familySpace != null;

    final dto = CreateTransactionDto(
      amount: double.parse(_amountController.text),
      currencyCode: _currencyCode,
      category: _selectedCategory!,
      counterparty: _counterpartyController.text,
      type: _isExpense ? 'expense' : 'income',
      date: _selectedDate,
      baseCurrencyCode: userCurrency,
      exchangeRateOverride: rateOverride,
      scope: isFamilyScope ? 'family' : 'personal',
      familySpaceId: isFamilyScope ? familySpace.id : null,
      recurring: !_isEditing
          ? RecurringDraft(
              enabled: _recurringEnabled,
              cadence: _recurringCadence,
              endDate: _recurringEndDate,
            )
          : null,
    );

    try {
      final service = ref.read(transactionServiceProvider);
      late final Transaction savedTransaction;
      if (_isEditing) {
        savedTransaction = await service.update(widget.transactionId!, dto);
      } else {
        savedTransaction = await service.create(dto);
      }
      final hasMatchingBudget =
          ref.read(hasBudgetForCategoryProvider(_selectedCategory!));
      final shouldAddBudgetNudge =
          !_isEditing && _isExpense && !hasMatchingBudget;
      if (shouldAddBudgetNudge) {
        ref
            .read(localAlertsProvider.notifier)
            .addBudgetNudge(category: _selectedCategory!);
      }

      final budgetNotifier = ref.read(budgetListProvider.notifier);
      final didUpdateBudget = _isEditing
          ? _originalTransaction != null &&
              budgetNotifier.applyOptimisticTransactionUpdate(
                previousTransaction: _originalTransaction!,
                updatedTransaction: savedTransaction,
              )
          : budgetNotifier.applyOptimisticTransaction(savedTransaction);
      if (didUpdateBudget && ref.read(budgetReconciliationEnabledProvider)) {
        budgetNotifier.scheduleRefreshInBackground();
      }

      if (!mounted) return;
      _originalTransaction = savedTransaction;
      ref.invalidate(transactionListProvider);
      ref.invalidate(filteredTransactionListProvider);
      if (_isEditing) {
        ref.invalidate(transactionDetailProvider(widget.transactionId!));
      }
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(savedTransaction);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldAddBudgetNudge
                  ? '${_isEditing ? 'Transaction updated' : 'Transaction added!'} Budget nudge saved for ${_selectedCategory!}.'
                  : _isEditing
                      ? 'Transaction updated'
                      : 'Transaction added!',
            ),
          ),
        );
      } else {
        setState(() => _submitting = false);
      }
    } catch (e, s) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _isExpense
          ? DateTime.now()
          : DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preferredCurrency = ref.watch(userPreferencesProvider).currency;

    if (!_isEditing &&
        !_currencyManuallyChanged &&
        _currencyCode != preferredCurrency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currencyManuallyChanged) return;
        setState(() => _currencyCode = preferredCurrency);
      });
    }

    if (_isEditing && !_prefilled) {
      return HeroScreenScaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        child: const Column(
          children: [
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
          ],
        ),
      );
    }

    return _buildForm(colors, textTheme);
  }

  Widget _buildForm(ColorScheme colors, TextTheme textTheme) {
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final familySpace = ref.watch(familySpaceProvider).valueOrNull;
    final locationAssistance = ref.watch(locationAssistanceProvider);
    final suggestions = ref.watch(locationAssistanceSuggestionsProvider);
    final hasSuggestions = suggestions.nearbyMerchants.isNotEmpty ||
        suggestions.likelyCategories.isNotEmpty;

    return HeroScreenScaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: () => context.pop(),
        ),
      ),
      bottom: FilledButton(
        onPressed: _isValid && !_submitting ? _submit : null,
        child: _submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditing ? 'Update Transaction' : 'Save Transaction',
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: const Text('Expense'),
                icon: Icon(
                  Icons.arrow_downward,
                  color: _isExpense
                      ? (colors.brightness == Brightness.light
                          ? const Color(0xFFE53935)
                          : const Color(0xFFEF9A9A))
                      : null,
                ),
              ),
              ButtonSegment(
                value: false,
                label: const Text('Income'),
                icon: Icon(
                  Icons.arrow_upward,
                  color: !_isExpense
                      ? (colors.brightness == Brightness.light
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF81C784))
                      : null,
                ),
              ),
            ],
            selected: {_isExpense},
            onSelectionChanged: (v) => setState(() {
              _isExpense = v.first;
              _selectedCategory = null;
            }),
          ),
          const SizedBox(height: 18),
          AmountInputField(
            controller: _amountController,
            isExpense: _isExpense,
            currencyCode: _currencyCode,
            isPremium: isPremium,
            onChanged: (_) => setState(() {}),
            onCurrencyChanged: (code) => setState(() {
              _currencyManuallyChanged = true;
              _currencyCode = code;
            }),
          ),
          const SizedBox(height: 18),
          if (!_isEditing && familySpace != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scope',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose whether this record stays personal or appears in ${familySpace.name}.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScopeSelector(
                    value: _scope,
                    familyEnabled: true,
                    onChanged: (value) => setState(() => _scope = value),
                  ),
                ],
              ),
            ),
          ],
          Consumer(
            builder: (context, ref, _) {
              final userCurrency = ref.watch(userPreferencesProvider).currency;
              if (_currencyCode == userCurrency) {
                return const SizedBox.shrink();
              }

              final rateAsync = ref.watch(
                exchangeRateProvider((_currencyCode, userCurrency)),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: rateAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (liveRate) => TextField(
                    controller: _exchangeRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Exchange rate (optional)',
                      hintText: liveRate != null
                          ? liveRate.toStringAsFixed(4)
                          : 'Enter rate manually',
                      helperText: liveRate != null
                          ? 'Leave blank to use live rate (1 $_currencyCode = ${liveRate.toStringAsFixed(4)} $userCurrency)'
                          : 'Live rate unavailable — enter manually or leave blank',
                    ),
                  ),
                ),
              );
            },
          ),
          _AccordionSection(
            title: 'Category',
            subtitle: _isExpense
                ? 'Choose a category first, then refine the rest.'
                : 'Pick the income source type you want to track.',
            expanded: _categoryExpanded,
            onToggle: () => setState(() {
              _categoryExpanded = !_categoryExpanded;
            }),
            child: TransactionStyleCategorySelector(
              selectedCategory: _selectedCategory,
              isExpense: _isExpense,
              isPremium: isPremium,
              showHeader: false,
              labelStyle: textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              moreCategoriesIcon: AppIcons.add,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                if (category != null) {
                  ref.read(recentCategoryProvider.notifier).record(category);
                }
              },
            ),
          ),
          if (!_isEditing &&
              locationAssistance.isEnabled &&
              hasSuggestions) ...[
            SmartSuggestionsCard(
              suggestions: suggestions,
              subtitle:
                  'Suggestions only help you fill things faster. You can still edit everything manually.',
              onMerchantSelected: (counterpartySuggestion) {
                setState(() {
                  _counterpartyController.text = counterpartySuggestion;
                });
              },
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
                ref.read(recentCategoryProvider.notifier).record(category);
              },
              categoryAvatarBuilder: (category) => CategoryIcons.badge(
                category,
                size: 14,
              ),
            ),
            const SizedBox(height: 18),
          ],
          _AccordionSection(
            title: 'Details',
            subtitle:
                'Add the who, when, and any context you want to remember later.',
            expanded: _detailsExpanded,
            onToggle: () => setState(() {
              _detailsExpanded = !_detailsExpanded;
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _counterpartyController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _isExpense
                        ? 'Merchant (optional)'
                        : 'Source (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.calendar,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeDateLabel(_selectedDate),
                          style: textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Icon(
                          AppIcons.chevronRight,
                          size: 16,
                          color: colors.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 18),
            _AccordionSection(
              title: 'Recurring',
              subtitle:
                  'Create future transactions automatically on a schedule.',
              expanded: _recurringExpanded,
              onToggle: () => setState(() {
                _recurringExpanded = !_recurringExpanded;
              }),
              child: RecurringScheduleSection(
                enabled: _recurringEnabled,
                cadence: _recurringCadence,
                endDate: _recurringEndDate,
                onEnabledChanged: (value) =>
                    setState(() => _recurringEnabled = value),
                onCadenceChanged: (value) =>
                    setState(() => _recurringCadence = value),
                onEndDateChanged: (value) =>
                    setState(() => _recurringEndDate = value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _relativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return _formatDate(date);
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.title,
    this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
