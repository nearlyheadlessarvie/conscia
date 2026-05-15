import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

class ConsciaAppBarScrollScope
    extends InheritedNotifier<ValueNotifier<double>> {
  const ConsciaAppBarScrollScope({
    super.key,
    required ValueNotifier<double> scrollProgress,
    required super.child,
  }) : super(notifier: scrollProgress);

  static ValueNotifier<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ConsciaAppBarScrollScope>()
        ?.notifier;
  }
}

class ConsciaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ConsciaAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.showBottomBorder = false,
    this.centerTitle,
    this.backgroundColor,
    this.elevation,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final bool showBottomBorder;
  final bool? centerTitle;
  final Color? backgroundColor;
  final double? elevation;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final scrollProgress = ConsciaAppBarScrollScope.maybeOf(context);
    if (scrollProgress == null) {
      return _buildAppBar(context, 0);
    }

    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (context, progress, _) => _buildAppBar(context, progress),
    );
  }

  Widget _buildAppBar(BuildContext context, double scrollProgress) {
    final colors = Theme.of(context).appColors;
    final canPop = Navigator.of(context).canPop();
    final progress = scrollProgress >= 1.0 ? 1.0 : 0.0;
    final radius = BorderRadius.circular(999 * progress);
    final capsuleInset = 8.0 * progress;
    final leadingWidget = leading ??
        (automaticallyImplyLeading && canPop
            ? IconButton(
                tooltip: 'Back',
                visualDensity: VisualDensity.compact,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icon(
                  AppIcons.chevronLeft,
                  size: 28,
                  color: colors.deepNavy,
                ),
              )
            : null);
    final sideSlotWidth = _sideSlotWidth(actions);

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      centerTitle: false,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: colors.ink,
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: capsuleInset),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 18 * progress,
              sigmaY: 18 * progress,
            ),
            child: Container(
              key: const ValueKey('conscia-app-bar-capsule'),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
                  backgroundColor ?? colors.paper.withValues(alpha: 0.64),
                  progress,
                ),
                borderRadius: radius,
                border: Border.all(
                  color: Color.lerp(
                    Colors.transparent,
                    colors.border.withValues(alpha: 0.84),
                    progress,
                  )!,
                ),
                boxShadow: progress > 0.02
                    ? [
                        BoxShadow(
                          color: colors.ink.withValues(alpha: 0.05 * progress),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: sideSlotWidth,
                    height: 40,
                    child: leadingWidget ?? const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: Align(
                      alignment: (centerTitle ?? true)
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: title == null
                          ? const SizedBox.shrink()
                          : _HeaderTitle(title: title!),
                    ),
                  ),
                  SizedBox(
                    width: sideSlotWidth,
                    height: 40,
                    child: actions == null || actions!.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: null,
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.border,
              ),
            )
          : null,
    );
  }

  double _sideSlotWidth(List<Widget>? actions) {
    final count = actions?.length ?? 0;
    if (count == 0) return 40;
    return (count * 48).clamp(48, 160).toDouble();
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w800,
        );

    if (title case Text(data: final data?) when data.isNotEmpty) {
      return Text(
        data,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return DefaultTextStyle.merge(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
      child: title,
    );
  }
}
