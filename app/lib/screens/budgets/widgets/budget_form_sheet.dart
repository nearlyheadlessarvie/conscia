import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localized_number_input.dart';
import '../../../providers/budget_providers.dart';
import '../../../providers/family_space_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/budget_service.dart';
import '../../transactions/widgets/transaction_style_category_selector.dart';
import '../../../widgets/currency_badge.dart';
import '../../../widgets/floating_label_text_field.dart';
import '../../../widgets/scope_pill_switch.dart';
import '../../../widgets/screen_section.dart';
import '../../../providers/user_provider.dart';

class BudgetFormSheet extends ConsumerStatefulWidget {
  final Budget? existing;
  final String? initialCategory;

  const BudgetFormSheet({super.key, this.existing, this.initialCategory});

  static Future<void> show(
    BuildContext context, {
    Budget? existing,
    String? initialCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BudgetFormSheet(
        existing: existing,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amountController;
  String? _selectedCategory;
  bool _submitting = false;
  String _scope = 'personal';
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : LocalizedNumberInput.formatForInput(
              widget.existing!.monthlyLimit,
              locale: ref.read(userPreferencesProvider).locale,
            ),
    );
    _selectedCategory = widget.existing?.category ?? widget.initialCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: ref.read(userPreferencesProvider).locale,
    );
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final amount = LocalizedNumberInput.parseAmount(
      _amountController.text,
      locale: ref.read(userPreferencesProvider).locale,
    );
    if (_selectedCategory == null || amount == null || amount <= 0) return;
    final user = ref.read(currentUserProvider);
    final currency =
        widget.existing?.currencyCode ?? user.value?.currencyCode ?? 'USD';
    final familySpace = ref.read(familySpaceProvider).valueOrNull;
    final isFamilyScope =
        !_isEditing && _scope == 'family' && familySpace != null;
    final dto = CreateBudgetDto(
      category: _selectedCategory!,
      monthlyLimit: amount,
      currencyCode: currency,
      scope: isFamilyScope ? 'family' : 'personal',
      familySpaceId: isFamilyScope ? familySpace.id : null,
    );

    final notifier = ref.read(budgetListProvider.notifier);
    if (_isEditing) {
      await notifier.update(widget.existing!.id, dto);
    } else {
      await notifier.create(dto);
    }

    setState(() => _submitting = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(budgetListProvider.notifier).delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = ref.read(currentUserProvider);
    final currency =
        widget.existing?.currencyCode ?? user.value?.currencyCode ?? 'USD';
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final familySpace = ref.watch(familySpaceProvider).valueOrNull;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 540,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Budget' : 'New Budget',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ScreenSection(
                      title: 'Category',
                      subtitle: _isEditing
                          ? 'Category cannot be changed once the budget exists.'
                          : 'Choose which spending category this budget should watch.',
                      compact: true,
                      child: TransactionStyleCategorySelector(
                        selectedCategory: _selectedCategory,
                        isExpense: true,
                        isPremium: isPremium,
                        showHeader: false,
                        onCategorySelected: _isEditing
                            ? (_) {}
                            : (value) =>
                                setState(() => _selectedCategory = value),
                      ),
                    ),
                    ScreenSection(
                      title: 'Monthly cap',
                      subtitle:
                          'Set the spending ceiling you want Conscia to track.',
                      compact: true,
                      child: FloatingLabelTextField(
                        controller: _amountController,
                        label: 'Monthly limit',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          LocalizedNumberInput.formatter(
                            ref.watch(userPreferencesProvider).locale,
                          ),
                        ],
                        onChanged: (_) => setState(() {}),
                        prefixLabelInset: 78,
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: CurrencyBadge(
                            currencyCode: currency,
                          ),
                        ),
                      ),
                    ),
                    if (!_isEditing && familySpace != null)
                      ScreenSection(
                        title: 'Scope',
                        subtitle:
                            'Choose whether this budget stays personal or appears in ${familySpace.name}.',
                        compact: true,
                        child: ScopePillSwitch(
                          value: _scope,
                          familyEnabled: true,
                          onChanged: (value) => setState(() => _scope = value),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                        _isEditing ? 'Save Changes' : 'Create Budget',
                      ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'Delete Budget',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
