import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class EditorialStickyHeader extends StatelessWidget {
  const EditorialStickyHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.topPadding,
    this.trailing,
    this.alwaysShowBack = false,
  });

  final String title;
  final double progress;
  final double topPadding;
  final Widget? trailing;
  final bool alwaysShowBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final opacity = progress >= 1.0 ? 1.0 : 0.0;
    final horizontalInset = 8.0 * opacity;
    final canPop = alwaysShowBack || Navigator.of(context).canPop();
    final radius = BorderRadius.circular(999);
    final background = Color.lerp(
      Colors.transparent,
      colors.paper.withValues(alpha: 0.64),
      opacity,
    )!;
    final borderColor = Color.lerp(
      Colors.transparent,
      colors.border.withValues(alpha: 0.84),
      opacity,
    )!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        topPadding + 8,
        horizontalInset,
        0,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 18 * opacity,
            sigmaY: 18 * opacity,
          ),
          child: AnimatedContainer(
            key: ValueKey('editorial-sticky-header-$title'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: Border.all(color: borderColor),
              boxShadow: opacity > 0.02
                  ? [
                      BoxShadow(
                        color: colors.ink.withValues(alpha: 0.05 * opacity),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: canPop
                      ? IconButton(
                          tooltip: 'Back',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: colors.deepNavy,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: trailing ?? const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
