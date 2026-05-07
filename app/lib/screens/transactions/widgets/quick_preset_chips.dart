import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/generated/app_constants.g.dart';
import '../../../providers/category_frequency_provider.dart';

class QuickPresetChips extends ConsumerWidget {
  final String? selectedCategory;
  final bool isExpense;
  final ValueChanged<String> onCategorySelected;

  const QuickPresetChips({
    super.key,
    required this.selectedCategory,
    required this.isExpense,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequentCategories = ref.watch(categoryFrequencyProvider);
    final categories = isExpense
        ? _expenseQuickCategories(frequentCategories)
        : incomeCategories.take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final icon = CategoryIcons.forCategory(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(icon, size: 16),
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => onCategorySelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _expenseQuickCategories(List<String> frequentCategories) {
    final visible = <String>[];

    for (final category in frequentCategories) {
      if (expenseCategories.contains(category) && !visible.contains(category)) {
        visible.add(category);
      }
      if (visible.length == 5) {
        return visible;
      }
    }

    for (final category in expenseCategories) {
      if (!visible.contains(category)) {
        visible.add(category);
      }
      if (visible.length == 5) {
        break;
      }
    }

    return visible;
  }
}
