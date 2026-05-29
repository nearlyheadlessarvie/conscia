import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

class HeroShortcutCard extends StatelessWidget {
  const HeroShortcutCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.minHeight = 54,
  });

  final AppIconKey icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final radius = BorderRadius.circular(18);
    final enabled = onPressed != null;

    return Material(
      color: colors.surfaceRaised.withValues(alpha: enabled ? 0.92 : 0.52),
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
              horizontal: 12,
              vertical: subtitle == null ? 12 : 9,
            ),
            child: subtitle == null
                ? _HeroShortcutCompactContent(
                    icon: icon,
                    label: label,
                    enabled: enabled,
                  )
                : _HeroShortcutActionContent(
                    icon: icon,
                    label: label,
                    subtitle: subtitle!,
                    enabled: enabled,
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
    required this.enabled,
  });

  final AppIconKey icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcons.icon(
          icon,
          size: 18,
          color: enabled ? colors.deepNavy : colors.softInk,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: enabled ? colors.deepNavy : colors.mutedInk,
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
    required this.enabled,
  });

  final AppIconKey icon;
  final String label;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        AppIcons.icon(
          icon,
          size: 17,
          color: enabled ? colors.deepNavy : colors.softInk,
        ),
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
                style: textTheme.titleSmall?.copyWith(
                  color: enabled ? colors.deepNavy : colors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.mutedInk,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        AppIcons.icon(
          AppIconKey.chevronRight,
          size: 18,
          color: enabled ? colors.softInk : Colors.transparent,
        ),
      ],
    );
  }
}
