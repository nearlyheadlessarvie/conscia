import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/category_frequency_provider.dart';

class QuickPresetChips extends ConsumerWidget {
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const QuickPresetChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const _categoryIcons = <String, String>{
    'Coffee': '☕',
    'Dining': '🍽️',
    'Shopping': '🛍️',
    'Gaming': '🎮',
    'Travel': '✈️',
    'Transport': '🚗',
    'Entertainment': '🎬',
    'Health': '💊',
    'Utilities': '💡',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryFrequencyProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final icon = _categoryIcons[cat] ?? '📦';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$icon $cat'),
              selected: selectedCategory == cat,
              onSelected: (_) => onCategorySelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}
