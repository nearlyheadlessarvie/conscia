import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ConsciaSheetHandle extends StatelessWidget {
  const ConsciaSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).appColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class ConsciaSheetHeader extends StatelessWidget {
  const ConsciaSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.mutedInk,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class ConsciaBottomSheetScaffold extends StatelessWidget {
  const ConsciaBottomSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.scrollController,
    this.expand = false,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final ScrollController? scrollController;
  final bool expand;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const ConsciaSheetHandle(),
        const SizedBox(height: 18),
        ConsciaSheetHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 18),
        if (expand)
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: child,
            ),
          )
        else
          child,
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );

    return SafeArea(
      child: Padding(
        padding: padding.copyWith(bottom: padding.bottom + bottomInset),
        child: expand ? content : SingleChildScrollView(child: content),
      ),
    );
  }
}
