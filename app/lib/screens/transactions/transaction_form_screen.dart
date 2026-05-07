import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../providers/alert_provider.dart';
import '../../providers/budget_providers.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../services/transaction_service.dart';
import '../../widgets/amount_input_field.dart';
import '../../widgets/location_assistance_prompt_sheet.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/category_picker.dart';
import 'widgets/quick_preset_chips.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({super.key, this.transactionId});

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
  final _merchantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _submitting = false;
  bool _prefilled = false;
  bool _moreOptionsExpanded = false;
  bool _hasCheckedLocationPrompt = false;

  @override
  void initState() {
    super.initState();
    _currencyCode = ref.read(userPreferencesProvider).currency;
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEditData();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePromptForLocationAssistance();
      });
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
        _prefilled = true;
        _isExpense = tx.type != 'income';
        _amountController.text = tx.amount.toStringAsFixed(2);
        _currencyCode = tx.currencyCode;
        _currencyManuallyChanged = true;
        _selectedCategory = tx.category;
        _merchantController.text = tx.description;
        _selectedDate = tx.date;
        _moreOptionsExpanded = _notesController.text.isNotEmpty;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _merchantController.dispose();
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

    final dto = CreateTransactionDto(
      amount: double.parse(_amountController.text),
      currencyCode: _currencyCode,
      category: _selectedCategory!,
      merchant: _merchantController.text,
      type: _isExpense ? 'expense' : 'income',
      date: _selectedDate,
      baseCurrencyCode: userCurrency,
      exchangeRateOverride: rateOverride,
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

      if (!mounted) return;
      ref.invalidate(transactionListProvider);
      if (_isEditing) {
        ref.invalidate(transactionDetailProvider(widget.transactionId!));
      }
      context.pop(savedTransaction);
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
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

  Future<void> _showCategoryPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: CategoryPicker(
              selected: _selectedCategory,
              isExpense: _isExpense,
              maxVisible: 100,
              onSelected: (cat) {
                setState(() => _selectedCategory = cat);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
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
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
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
    final locationAssistance = ref.watch(locationAssistanceProvider);
    final suggestions = ref.watch(locationAssistanceSuggestionsProvider);
    final hasSuggestions = suggestions.nearbyMerchants.isNotEmpty ||
        suggestions.likelyCategories.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
                  padding: const EdgeInsets.only(bottom: 16),
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
            Row(
              children: [
                Text(
                  'Category',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCategoryPickerSheet,
                  icon: Icon(AppIcons.add, size: 16),
                  label: const Text('More categories'),
                ),
              ],
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: Icon(
                    CategoryIcons.forCategory(_selectedCategory!),
                    size: 18,
                  ),
                  label: Text(_selectedCategory!),
                  onDeleted: () => setState(() => _selectedCategory = null),
                ),
              ),
            ] else ...[
              QuickPresetChips(
                selectedCategory: _selectedCategory,
                isExpense: _isExpense,
                onCategorySelected: (cat) {
                  setState(() => _selectedCategory = cat);
                },
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Merchant (optional)',
              ),
            ),
            if (!_isEditing && locationAssistance.isEnabled && hasSuggestions) ...[
              const SizedBox(height: 16),
              _buildLocationSuggestionCard(colors, textTheme, suggestions),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('More options'),
                initiallyExpanded: _moreOptionsExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _moreOptionsExpanded = expanded);
                },
                children: [
                  if (!_isEditing && locationAssistance.isEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Smart suggestions use your location only to help with nearby merchants and likely categories. You can still edit everything manually.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSuggestionCard(
    ColorScheme colors,
    TextTheme textTheme,
    LocationAssistanceSuggestions suggestions,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Smart suggestions nearby', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Suggestions are assistive only. Tap one to fill the form faster.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (suggestions.nearbyMerchants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Nearby merchants', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.nearbyMerchants
                  .map(
                    (merchant) => ActionChip(
                      label: Text(merchant),
                      onPressed: () {
                        setState(() {
                          _merchantController.text = merchant;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          if (suggestions.likelyCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Likely categories', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.likelyCategories
                  .map(
                    (category) => ActionChip(
                      avatar: Icon(
                        CategoryIcons.forCategory(category),
                        size: 18,
                      ),
                      label: Text(category),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  )
                  .toList(),
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
