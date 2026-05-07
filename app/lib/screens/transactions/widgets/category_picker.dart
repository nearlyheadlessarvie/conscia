import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_visibility.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../providers/category_recents_provider.dart';

class CategoryData {
  final String name;

  const CategoryData(this.name);
}

class CategoryPicker extends ConsumerStatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool isExpense;
  final bool isPremium;
  final int maxVisible;

  const CategoryPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.isExpense = true,
    this.isPremium = true,
    this.maxVisible = 9,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  bool _expanded = false;

  List<CategoryData> get _categories {
    final names = widget.isExpense
        ? visibleBudgetCategories(
            isPremium: widget.isPremium,
            categories: expenseCategories,
          )
        : incomeCategories;
    final orderedNames = orderCategoriesByRecency(
      categories: names,
      recents: ref.watch(recentCategoryProvider),
    );
    return orderedNames.map(CategoryData.new).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = _categories;
    final visible =
        _expanded ? categories : categories.take(widget.maxVisible).toList();
    final hasMore = categories.length > widget.maxVisible && !_expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in visible)
              ChoiceChip(
                avatar: CategoryIcons.badge(
                  cat.name,
                  size: 16,
                  selected: widget.selected == cat.name,
                ),
                label: Text(cat.name),
                selected: widget.selected == cat.name,
                onSelected: (_) => widget.onSelected(cat.name),
                selectedColor: colors.primaryContainer,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.selected == cat.name
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
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
}
