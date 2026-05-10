import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/budget_providers.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/budget_service.dart';
import '../../transactions/widgets/transaction_style_category_selector.dart';
import '../../../widgets/currency_badge.dart';
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
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existing?.monthlyLimit.toStringAsFixed(2) ?? '',
    );
    _selectedCategory = widget.existing?.category ?? widget.initialCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final amount = double.tryParse(_amountController.text);
    if (_selectedCategory == null || amount == null || amount <= 0) return;
    final user = ref.read(currentUserProvider);
    final currency =
        widget.existing?.currencyCode ?? user.value?.currencyCode ?? 'USD';
    final dto = CreateBudgetDto(
      category: _selectedCategory!,
      monthlyLimit: amount,
      currencyCode: currency,
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
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 460,
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
                      subtitle: 'Set the spending ceiling you want Conscia to track.',
                      compact: true,
                      child: TextField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Monthly Limit',
                          border: const OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: CurrencyBadge(
                              currencyCode: currency,
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isValid && !_submitting ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
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
