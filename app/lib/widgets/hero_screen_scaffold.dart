import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class HeroScreenScaffold extends StatelessWidget {
  const HeroScreenScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 28),
    this.bottom,
    this.scrollable = true,
    this.scrollViewKey,
    this.extraBottomPadding = 0.0,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? bottom;
  final bool scrollable;
  final Key? scrollViewKey;
  // Extra bottom padding to clear floating overlays (e.g. floating dock nav ~72px)
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final mediaQueryPaddingBottom = MediaQuery.paddingOf(context).bottom;
    final resolvedPadding = padding.resolve(Directionality.of(context));

    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.pageTop,
              colors.pageBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(
                        key: scrollViewKey,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: resolvedPadding.left,
                          top: resolvedPadding.top,
                          right: resolvedPadding.right,
                          bottom: resolvedPadding.bottom +
                              (bottom != null ? 0 : keyboardInset),
                        ),
                        child: child,
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          left: resolvedPadding.left,
                          top: resolvedPadding.top,
                          right: resolvedPadding.right,
                          bottom: resolvedPadding.bottom +
                              (bottom != null ? 0 : keyboardInset),
                        ),
                        child: child,
                      ),
              ),
              if (bottom != null)
                AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    20 + extraBottomPadding + keyboardInset + mediaQueryPaddingBottom,
                  ),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
