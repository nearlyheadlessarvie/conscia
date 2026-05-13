import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch(
      {super.key,
      required this.items,
      required this.selectedItem,
      required this.selectedColor,
      required this.onChanged,
      this.enabled = true,
      this.normalized = true});

  final List<String> items;
  final String selectedItem;
  final Color selectedColor;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool normalized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _FormSegment(
              label: items[index],
              selected: selectedItem ==
                  (normalized ? items[index].toLowerCase() : items[index]),
              color: selectedColor,
              onTap: () => onChanged(
                  normalized ? items[index].toLowerCase() : items[index]),
              enabled: enabled,
            ),
          ],
        ],
      ),
    );
  }
}

class _FormSegment extends StatelessWidget {
  const _FormSegment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? color
                      : colors.mutedInk.withValues(alpha: enabled ? 1.0 : 0.55),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
