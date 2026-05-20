import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/managed_category.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/category_recents_provider.dart';
import '../../../widgets/budget_mix_visuals.dart';

class CategoryData {
  final String name;
  final String type;
  final String? iconKey;
  final String? colorKey;

  const CategoryData(
    this.name, {
    required this.type,
    this.iconKey,
    this.colorKey,
  });

  factory CategoryData.fromManaged(ManagedCategory category) => CategoryData(
        category.name,
        type: category.type,
        iconKey: category.visualIconKey,
        colorKey: category.visualColorKey,
      );
}

class CategoryPicker extends ConsumerStatefulWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool isExpense;
  final bool isPremium;
  final bool allowAllCategories;
  final int maxVisible;
  final bool showTitle;

  const CategoryPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.isExpense = true,
    this.isPremium = true,
    this.allowAllCategories = false,
    this.maxVisible = 9,
    this.showTitle = true,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  bool _expanded = false;

  List<CategoryData> get _categories {
    final managed =
        ref.watch(managedCategoriesProvider(const CategoryQuery())).maybeWhen(
              data: _managedCategoryData,
              orElse: () => const <CategoryData>[],
            );
    final categories = managed.isNotEmpty
        ? managed
        : widget.isExpense
            ? _visibleExpenseCategories()
                .map(
                  (name) => CategoryData(name, type: 'Expense'),
                )
                .toList()
            : incomeCategories
                .map(
                  (name) => CategoryData(name, type: 'Income'),
                )
                .toList();
    final orderedNames = orderCategoriesByRecency(
      categories: categories.map((category) => category.name).toList(),
      recents: ref.watch(recentCategoryProvider),
    );
    return [
      for (final name in orderedNames)
        categories.firstWhere(
          (category) => category.name == name,
          orElse: () => CategoryData(
            name,
            type: widget.isExpense ? 'Expense' : 'Income',
          ),
        ),
    ];
  }

  List<CategoryData> _managedCategoryData(List<ManagedCategory> categories) {
    return categories
        .where((category) => !category.isArchived)
        .where((category) =>
            widget.isExpense ? category.isExpense : category.isIncome)
        .where((category) =>
            widget.allowAllCategories ||
            widget.isPremium ||
            isFreeTransactionCategory(category.name))
        .map(CategoryData.fromManaged)
        .toList(growable: false);
  }

  List<String> _visibleExpenseCategories() {
    if (widget.allowAllCategories) {
      return visibleBudgetCategories(
        isPremium: widget.isPremium,
        categories: expenseCategories,
      );
    }

    return visibleTransactionCategories(
      isPremium: widget.isPremium,
      isExpense: true,
      categories: expenseCategories,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = _categories;
    final ordered = _selectedFirst(categories);
    final visible =
        _expanded ? ordered : ordered.take(widget.maxVisible).toList();
    final hasMore = categories.length > widget.maxVisible && !_expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in visible)
              CategoryChoicePill(
                category: cat.name,
                type: cat.type,
                iconKey: cat.iconKey,
                colorKey: cat.colorKey,
                selected: widget.selected == cat.name,
                onTap: () => widget.onSelected(
                  widget.selected == cat.name ? null : cat.name,
                ),
              ),
            if (hasMore)
              ActionChip(
                label: const Text('Show all'),
                onPressed: () => setState(() => _expanded = true),
              ),
          ],
        ),
      ],
    );
  }

  List<CategoryData> _selectedFirst(List<CategoryData> categories) {
    final selected = widget.selected;
    if (selected == null) return categories;

    final selectedData =
        categories.where((category) => category.name == selected).firstOrNull;
    if (selectedData == null) {
      return [
        CategoryData(
          selected,
          type: widget.isExpense ? 'Expense' : 'Income',
        ),
        ...categories,
      ];
    }

    return [
      selectedData,
      ...categories.where((category) => category.name != selected),
    ];
  }
}

class CategoryChoicePill extends StatelessWidget {
  const CategoryChoicePill({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.type,
    this.iconKey,
    this.colorKey,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;
  final String? type;
  final String? iconKey;
  final String? colorKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = BudgetMixPalette.colorForCategory(
      category,
      context,
      type: type,
      colorKey: colorKey,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? accent.withValues(alpha: 0.12) : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? accent.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcons.rawIcon(
              category,
              size: 13,
              type: type,
              iconKey: iconKey,
              colorKey: colorKey,
            ),
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
