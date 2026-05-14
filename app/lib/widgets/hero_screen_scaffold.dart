import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'conscia_app_bar.dart';

class HeroScreenScaffold extends StatefulWidget {
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
  State<HeroScreenScaffold> createState() => _HeroScreenScaffoldState();
}

class _HeroScreenScaffoldState extends State<HeroScreenScaffold> {
  final _appBarScrollProgress = ValueNotifier<double>(0);

  @override
  void dispose() {
    _appBarScrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final nextProgress = (notification.metrics.pixels / 10).clamp(0.0, 1.0);
      if (_appBarScrollProgress.value != nextProgress) {
        _appBarScrollProgress.value = nextProgress;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final mediaQueryPaddingBottom = MediaQuery.paddingOf(context).bottom;
    final resolvedPadding = widget.padding.resolve(Directionality.of(context));

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        appBar: widget.appBar,
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
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
                    child: widget.scrollable
                        ? SingleChildScrollView(
                            key: widget.scrollViewKey,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: resolvedPadding.left,
                              top: resolvedPadding.top,
                              right: resolvedPadding.right,
                              bottom: resolvedPadding.bottom +
                                  (widget.bottom != null ? 0 : keyboardInset),
                            ),
                            child: widget.child,
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              left: resolvedPadding.left,
                              top: resolvedPadding.top,
                              right: resolvedPadding.right,
                              bottom: resolvedPadding.bottom +
                                  (widget.bottom != null ? 0 : keyboardInset),
                            ),
                            child: widget.child,
                          ),
                  ),
                  if (widget.bottom != null)
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        20 +
                            widget.extraBottomPadding +
                            keyboardInset +
                            mediaQueryPaddingBottom,
                      ),
                      child: widget.bottom!,
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
