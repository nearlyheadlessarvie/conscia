import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/localized_date_format.dart';
import '../../core/utils/localized_number_input.dart';
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
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/recurring_schedule_section.dart';
import '../../widgets/scope_pill_switch.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/smart_suggestions_card.dart';
import '../../widgets/amount_hero_field.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/screen_section.dart';
import 'widgets/transaction_style_category_selector.dart';
import '../../widgets/segmented_switch.dart';
import '../../widgets/form_label.dart';

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

  bool _isExpense = true;
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String _currencyCode = 'USD';
  bool _currencyManuallyChanged = false;
  String? _selectedCategory;
  final _counterpartyController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
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
        _amountController.text = LocalizedNumberInput.formatForInput(
          tx.amount,
          locale: ref.read(userPreferencesProvider).locale,
        );
        _currencyCode = tx.currencyCode;
        _currencyManuallyChanged = true;
        _selectedCategory = tx.category;
        _counterpartyController.text = tx.description;
        _selectedDate = tx.date;
        _scope = tx.scope;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final prefs = ref.read(userPreferencesProvider);
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: prefs.locale,
    );
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final prefs = ref.read(userPreferencesProvider);
    final userCurrency = prefs.currency;
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: prefs.locale,
    )!;
    final rateOverride = LocalizedNumberInput.parseAmount(
      _exchangeRateController.text,
      locale: prefs.locale,
    );
    final familySpace = ref.read(familySpaceProvider).valueOrNull;
    final familySpaceId =
        familySpace?.id ?? _originalTransaction?.familySpaceId;
    final isFamilyScope = _scope == 'family' && familySpaceId != null;

    final dto = CreateTransactionDto(
      amount: amount,
      currencyCode: _currencyCode,
      category: _selectedCategory!,
      counterparty: _counterpartyController.text,
      type: _isExpense ? 'expense' : 'income',
      date: _selectedDate,
      baseCurrencyCode: userCurrency,
      exchangeRateOverride: rateOverride,
      scope: isFamilyScope ? 'family' : 'personal',
      familySpaceId: isFamilyScope ? familySpaceId : null,
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
      return const HeroScreenScaffold(
        appBar: ConsciaAppBar(title: Text('Edit Transaction')),
        child: Column(
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
    final categorySubtitle = _isExpense
        ? 'Choose where this transaction belongs so budgets and insights stay accurate.'
        : 'Choose where this money came from so Conscia can understand your income rhythm separately from spending.';
    final userPrefs = ref.watch(userPreferencesProvider);
    final dateLabel = _relativeDateLabel(
      _selectedDate,
      locale: userPrefs.locale,
    );

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      appBar: ConsciaAppBar(
        centerTitle: true,
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
        leading: IconButton(
          icon: Icon(AppIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenSection(
            title: 'Transaction',
            subtitle: 'Was this money in or out?',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedSwitch(
                  items: const ['Expense', 'Income'],
                  selectedItem: _isExpense ? 'expense' : 'income',
                  selectedColor: _isExpense
                      ? Theme.of(context).appColors.expense
                      : Theme.of(context).appColors.income,
                  onChanged: (label) => setState(() {
                    final v = {label};
                    _isExpense = v.first == 'expense';
                    _selectedCategory = null;
                  }),
                ),
                const SizedBox(height: 18),
                const FormLabel(label: 'AMOUNT'),
                const SizedBox(height: 8),
                AmountHeroField(
                  controller: _amountController,
                  currencyCode: _currencyCode,
                  locale: userPrefs.locale,
                  isExpense: _isExpense,
                  isPremium: isPremium,
                  onChanged: (_) => setState(() {}),
                  onCurrencyChanged: (code) => setState(() {
                    _currencyManuallyChanged = true;
                    _currencyCode = code;
                  }),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final userCurrency =
                        ref.watch(userPreferencesProvider).currency;
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
                        data: (liveRate) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            FloatingLabelTextField(
                              controller: _exchangeRateController,
                              label: 'Exchange rate (optional)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                LocalizedNumberInput.formatter(
                                  userPrefs.locale,
                                  decimalDigits: 4,
                                  useGrouping: false,
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              liveRate != null
                                  ? 'Leave blank to use live rate (1 $_currencyCode = ${LocalizedNumberInput.formatForInput(
                                      liveRate,
                                      locale: userPrefs.locale,
                                      decimalDigits: 4,
                                    )} $userCurrency)'
                                  : 'Live rate unavailable - enter manually or leave blank',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).appColors.mutedInk,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (familySpace != null)
            ScreenSection(
              title: 'Classify',
              subtitle: 'Where should this live in your money story?',
              compact: true,
              child: ScopePillSwitch(
                value: _scope,
                familyEnabled: true,
                onChanged: (value) =>
                    setState(() => _scope = value.toLowerCase()),
              ),
            ),
          ScreenSection(
            title: 'Category',
            subtitle: categorySubtitle,
            compact: true,
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
          ScreenSection(
            title: 'Details',
            subtitle:
                'Add the merchant or source and date when it helps your history make sense.',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FloatingLabelTextField(
                  controller: _counterpartyController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  label:
                      _isExpense ? 'Merchant (optional)' : 'Source (optional)',
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                          dateLabel,
                          style: textTheme.bodyMedium,
                        )),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditing) ...[
            const Divider(height: 24),
            RecurringScheduleSection(
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
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date, {required String locale}) {
    return LocalizedDateFormat.numeric(date, locale: locale);
  }

  String _relativeDateLabel(DateTime date, {required String locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return _formatDate(date, locale: locale);
  }
}
