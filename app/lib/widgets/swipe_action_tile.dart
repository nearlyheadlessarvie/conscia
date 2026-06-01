import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

class SwipeActionTile extends StatelessWidget {
  const SwipeActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
    this.width = 78,
  });

  final AppIconKey icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Material(
          key: key ?? ValueKey('swipe-action-tile-$label'),
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcons.icon(
                    icon,
                    color: foregroundColor,
                    size: 19,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SwipeActionBackground extends StatelessWidget {
  const SwipeActionBackground({
    super.key,
    required this.alignment,
    required this.children,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final Alignment alignment;
  final List<Widget> children;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return ColoredBox(
      color: backgroundColor ?? colors.paper,
      child: Padding(
        padding: padding,
        child: Align(
          alignment: alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
