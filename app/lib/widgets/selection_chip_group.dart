import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SelectionChipGroup extends StatelessWidget {
  const SelectionChipGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onSelected,
    this.labelBuilder,
    this.avatarBuilder,
    this.scrollable = false,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final String Function(String option)? labelBuilder;
  final Widget Function(String option, bool selected)? avatarBuilder;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final chips = options.map((option) {
      final selected = option == value;
      final label = labelBuilder?.call(option) ?? option;
      return AnimatedContainer(
        key: ValueKey(
          'selection-chip-$option-${selected ? 'selected' : 'idle'}',
        ),
        duration: const Duration(milliseconds: 160),
        margin: EdgeInsets.only(right: scrollable ? 10 : 0),
        child: ChoiceChip(
          avatar: avatarBuilder?.call(option, selected),
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(option),
          backgroundColor: colors.surfaceMuted,
          selectedColor: colors.heroTint,
          side: BorderSide(
            color: selected ? colors.sectionBorder : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips.map((chip) => Padding(
        padding: const EdgeInsets.only(right: 0),
        child: chip,
      )).toList(),
    );
  }
}
