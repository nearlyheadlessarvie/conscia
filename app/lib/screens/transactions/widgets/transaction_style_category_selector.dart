import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/category_recents_provider.dart';
import '../../../widgets/conscia_bottom_sheet.dart';
import '../../../widgets/premium_upgrade_dialog.dart';
import 'category_picker.dart';

class TransactionStyleCategorySelector extends ConsumerStatefulWidget {
  const TransactionStyleCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    required this.isPremium,
    required this.onCategorySelected,
    this.allowAllCategories = false,
    this.labelStyle,
    this.moreCategoriesIcon = Icons.add,
    this.showHeader = true,
  });

  final String? selectedCategory;
  final bool isExpense;
  final bool isPremium;
  final bool allowAllCategories;
  final ValueChanged<String?> onCategorySelected;
  final TextStyle? labelStyle;
  final IconData moreCategoriesIcon;
  final bool showHeader;

  @override
  ConsumerState<TransactionStyleCategorySelector> createState() =>
      _TransactionStyleCategorySelectorState();
}

class _TransactionStyleCategorySelectorState
    extends ConsumerState<TransactionStyleCategorySelector> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToStart() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showCategoryPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ConsciaSheetHandle(),
                const SizedBox(height: 18),
                ConsciaSheetHeader(
                  title: 'Category',
                  subtitle: widget.isExpense
                      ? 'Choose where this spending belongs.'
                      : 'Choose where this income belongs.',
                ),
                const SizedBox(height: 16),
                CategoryPicker(
                  selected: widget.selectedCategory,
                  isExpense: widget.isExpense,
                  isPremium: widget.isPremium,
                  allowAllCategories: widget.allowAllCategories,
                  maxVisible: 100,
                  showTitle: false,
                  onSelected: (category) {
                    widget.onCategorySelected(category);
                    Navigator.of(context).pop();
                    _scrollToStart();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentCategories = ref.watch(recentCategoryProvider);
    final managedCategories =
        ref.watch(managedCategoriesProvider(const CategoryQuery())).maybeWhen(
              data: (cats) => cats
                  .where((c) => !c.isArchived)
                  .where(
                    (c) => widget.isExpense ? c.isExpense : c.isIncome,
                  )
                  .where(
                    (c) =>
                        widget.allowAllCategories ||
                        widget.isPremium ||
                        isFreeTransactionCategory(c.name),
                  )
                  .map(CategoryData.fromManaged)
                  .toList(growable: false),
              orElse: () => const <CategoryData>[],
            );

    final List<CategoryData> quickCategories = managedCategories.isNotEmpty
        ? [
            for (final name in orderCategoriesByRecency(
              categories:
                  managedCategories.map((category) => category.name).toList(),
              recents: recentCategories,
            ).take(4))
              managedCategories.firstWhere((category) => category.name == name),
          ]
        : widget.isExpense
            ? _expenseQuick(recentCategories)
                .map((name) => CategoryData(name, type: 'Expense'))
                .toList()
            : orderCategoriesByRecency(
                categories: incomeCategories,
                recents: recentCategories,
              )
                .take(4)
                .map((name) => CategoryData(name, type: 'Income'))
                .toList();

    final visibleQuick = quickCategories
        .where((c) => c.name != widget.selectedCategory)
        .toList();

    return SizedBox(
      height: 36,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: [
          if (widget.selectedCategory != null) ...[
            CategoryChoicePill(
              category: widget.selectedCategory!,
              type: widget.isExpense ? 'Expense' : 'Income',
              selected: true,
              onTap: () {
                widget.onCategorySelected(null);
                _scrollToStart();
              },
            ),
            const SizedBox(width: 8),
          ],
          ...visibleQuick.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChoicePill(
                category: cat.name,
                type: cat.type,
                iconKey: cat.iconKey,
                colorKey: cat.colorKey,
                selected: false,
                onTap: () {
                  widget.onCategorySelected(cat.name);
                  _scrollToStart();
                },
              ),
            ),
          ),
          widget.allowAllCategories || widget.isPremium
              ? _MoreChip(onTap: _showCategoryPickerSheet)
              : widget.isExpense
                  ? _PremiumCategoriesChip(
                      onTap: () => PremiumUpgradeDialog.show(
                        context,
                        feature:
                            'Free users can only log transactions in Dining, Groceries, and Salary.',
                      ),
                    )
                  : const SizedBox.shrink(),
        ],
      ),
    );
  }

  List<String> _expenseQuick(List<String> recents) {
    final allowed = widget.allowAllCategories
        ? visibleBudgetCategories(
            isPremium: widget.isPremium,
            categories: expenseCategories,
          )
        : visibleTransactionCategories(
            isPremium: widget.isPremium,
            isExpense: true,
            categories: expenseCategories,
          );
    return orderCategoriesByRecency(
      categories: allowed,
      recents: recents,
    ).take(4).toList();
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'More',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCategoriesChip extends StatelessWidget {
  const _PremiumCategoriesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.deepNavy.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 13,
              color: colors.deepNavy,
            ),
            const SizedBox(width: 4),
            Text(
              'Premium categories',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
