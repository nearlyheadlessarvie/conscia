import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';

class FamilyBadge extends StatelessWidget {
  const FamilyBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('family-transaction-badge'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        AppIcons.family,
        size: compact ? 13 : 16,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}
