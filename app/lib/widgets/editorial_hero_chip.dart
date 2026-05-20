import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class EditorialHeroChip extends StatelessWidget {
  const EditorialHeroChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.horizontalPadding = 12,
    this.verticalPadding = 8,
    this.letterSpacing = 0.2,
  });

  final String label;
  final Color? backgroundColor;
  final double horizontalPadding;
  final double verticalPadding;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceRaised.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: letterSpacing,
              ),
        ),
      ),
    );
  }
}
