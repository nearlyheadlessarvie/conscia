import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/category_recents_provider.dart';
import 'category_picker.dart';

class TransactionStyleCategorySelector extends ConsumerStatefulWidget {
  const TransactionStyleCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    required this.isPremium,
    required this.onCategorySelected,
    this.labelStyle,
    this.moreCategoriesIcon = Icons.add,
    this.showHeader = true,
  });

  final String? selectedCategory;
  final bool isExpense;
  final bool isPremium;
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: CategoryPicker(
              selected: widget.selectedCategory,
              isExpense: widget.isExpense,
              isPremium: widget.isPremium,
              maxVisible: 100,
              onSelected: (category) {
                widget.onCategorySelected(category);
                Navigator.of(context).pop();
                _scrollToStart();
              },
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
                  .map((c) => c.name)
                  .toList(growable: false),
              orElse: () => const <String>[],
            );

    final List<String> quickCategories = managedCategories.isNotEmpty
        ? orderCategoriesByRecency(
            categories: managedCategories,
            recents: recentCategories,
          ).take(5).toList()
        : widget.isExpense
            ? _expenseQuick(recentCategories)
            : orderCategoriesByRecency(
                categories: incomeCategories,
                recents: recentCategories,
              ).take(5).toList();

    final visibleQuick =
        quickCategories.where((c) => c != widget.selectedCategory).toList();

    return SizedBox(
      height: 36,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: [
          if (widget.selectedCategory != null) ...[
            _CategoryChip(
              category: widget.selectedCategory!,
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
              child: _CategoryChip(
                category: cat,
                selected: false,
                onTap: () {
                  widget.onCategorySelected(cat);
                  _scrollToStart();
                },
              ),
            ),
          ),
          _MoreChip(onTap: _showCategoryPickerSheet),
        ],
      ),
    );
  }

  List<String> _expenseQuick(List<String> recents) {
    final allowed = visibleBudgetCategories(
      isPremium: widget.isPremium,
      categories: expenseCategories,
    );
    return orderCategoriesByRecency(
      categories: allowed,
      recents: recents,
    ).take(5).toList();
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = CategoryIcons.accentFor(category);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcons.rawIcon(category, size: 13),
            const SizedBox(width: 6),
            Text(
              category,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    color: selected
                        ? accent
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 12, color: accent),
            ],
          ],
        ),
      ),
    );
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
