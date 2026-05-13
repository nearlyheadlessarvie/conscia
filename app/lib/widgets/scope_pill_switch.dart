import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ScopePillSwitch extends StatelessWidget {
  const ScopePillSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.familyEnabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool familyEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Personal',
            selected: value == 'personal',
            onTap: () => onChanged('personal'),
          ),
          _Segment(
            label: 'Family',
            selected: value == 'family',
            enabled: familyEnabled,
            onTap: () => onChanged('family'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

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
                      ? colors.deepNavy
                      : colors.mutedInk
                          .withValues(alpha: enabled ? 1.0 : 0.55),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
