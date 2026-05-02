import 'package:flutter/material.dart';

class CategoryData {
  final String name;
  final IconData icon;

  const CategoryData(this.name, this.icon);
}

const allCategories = [
  CategoryData('Groceries', Icons.shopping_cart),
  CategoryData('Dining', Icons.restaurant),
  CategoryData('Transport', Icons.directions_car),
  CategoryData('Entertainment', Icons.movie),
  CategoryData('Games & Recreations', Icons.videogame_asset),
  CategoryData('Shopping', Icons.shopping_bag),
  CategoryData('Health', Icons.favorite),
  CategoryData('Bills', Icons.receipt),
  CategoryData('Education', Icons.school),
  CategoryData('Travel', Icons.flight),
  CategoryData('Coffee', Icons.coffee),
  CategoryData('Subscriptions', Icons.autorenew),
  CategoryData('Salary', Icons.account_balance),
  CategoryData('Freelance', Icons.work),
  CategoryData('Gift', Icons.card_giftcard),
  CategoryData('Other', Icons.more_horiz),
];

class CategoryPicker extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final int maxVisible;

  const CategoryPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.maxVisible = 9,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = _expanded
        ? allCategories
        : allCategories.take(widget.maxVisible).toList();
    final hasMore = allCategories.length > widget.maxVisible && !_expanded;

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
                avatar: Icon(cat.icon, size: 18),
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
                label: const Text('More...'),
                onPressed: () => setState(() => _expanded = true),
              ),
          ],
        ),
      ],
    );
  }
}
