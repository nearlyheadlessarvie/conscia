import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class HeroShortcutCard extends StatelessWidget {
  const HeroShortcutCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.minHeight = 64,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final radius = BorderRadius.circular(18);

    return Material(
      color: colors.surfaceRaised.withValues(alpha: 0.92),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border.withValues(alpha: 0.82)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: colors.deepNavy),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
