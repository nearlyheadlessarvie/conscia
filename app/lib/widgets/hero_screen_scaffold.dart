import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class HeroScreenScaffold extends StatelessWidget {
  const HeroScreenScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 28),
    this.bottom,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

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
                child: SingleChildScrollView(
                  padding: padding,
                  child: child,
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
