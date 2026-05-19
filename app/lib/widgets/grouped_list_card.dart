import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class GroupedListCard extends StatelessWidget {
  const GroupedListCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.margin,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final separatedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      separatedChildren.add(children[index]);
      if (index < children.length - 1) {
        separatedChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border,
          ),
        );
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: separatedChildren,
        ),
      ),
    );
  }
}
