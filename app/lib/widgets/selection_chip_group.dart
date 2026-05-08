import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
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
    this.showTrailingCheck = false,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final String Function(String option)? labelBuilder;
  final Widget Function(String option, bool selected)? avatarBuilder;
  final bool scrollable;
  final bool showTrailingCheck;

  @override
  Widget build(BuildContext context) {
    final chips = options.map((option) {
      final selected = option == value;
      final label = labelBuilder?.call(option) ?? option;
      return Padding(
        key: ValueKey(
          'selection-chip-$option-${selected ? 'selected' : 'idle'}',
        ),
        padding: EdgeInsets.only(right: scrollable ? 10 : 0),
        child: SelectionChipButton(
          label: label,
          selected: selected,
          avatar: avatarBuilder?.call(option, selected),
          onTap: () => onSelected(option),
          trailing: showTrailingCheck && selected
              ? Icon(
                  AppIcons.check,
                  key: ValueKey('selection-chip-check-$option'),
                  size: 16,
                )
              : null,
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
      children: chips,
    );
  }
}

class SelectionChipButton extends StatelessWidget {
  const SelectionChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.avatar,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? avatar;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('selection-chip-button-$label'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.heroTint : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.sectionBorder : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
