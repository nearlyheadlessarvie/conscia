import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class HeroShortcutCard extends StatelessWidget {
  const HeroShortcutCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.minHeight = 64,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
            padding: EdgeInsets.symmetric(
              horizontal: subtitle == null ? 12 : 10,
              vertical: subtitle == null ? 12 : 9,
            ),
            child: subtitle == null
                ? _HeroShortcutCompactContent(icon: icon, label: label)
                : _HeroShortcutActionContent(
                    icon: icon,
                    label: label,
                    subtitle: subtitle!,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroShortcutCompactContent extends StatelessWidget {
  const _HeroShortcutCompactContent({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
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
    );
  }
}

class _HeroShortcutActionContent extends StatelessWidget {
  const _HeroShortcutActionContent({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.deepNavy),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.mutedInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: colors.deepNavy.withValues(alpha: 0.55),
        ),
      ],
    );
  }
}
