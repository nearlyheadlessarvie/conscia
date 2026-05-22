import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

class SingleSelectList<T> extends StatelessWidget {
  const SingleSelectList({
    super.key,
    required this.options,
    required this.value,
    required this.titleBuilder,
    required this.onChanged,
    this.subtitleBuilder,
    this.leadingBuilder,
    this.rowPadding = const EdgeInsets.symmetric(vertical: 14),
  });

  final List<T> options;
  final T? value;
  final String Function(T option) titleBuilder;
  final String? Function(T option)? subtitleBuilder;
  final Widget Function(BuildContext context, T option, bool selected)?
      leadingBuilder;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry rowPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            _SingleSelectRow<T>(
              option: options[index],
              selected: options[index] == value,
              title: titleBuilder(options[index]),
              subtitle: subtitleBuilder?.call(options[index]),
              leadingBuilder: leadingBuilder,
              rowPadding: rowPadding,
              onTap: () => onChanged(options[index]),
            ),
            if (index != options.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

class _SingleSelectRow<T> extends StatelessWidget {
  const _SingleSelectRow({
    required this.option,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leadingBuilder,
    required this.rowPadding,
    required this.onTap,
  });

  final T option;
  final bool selected;
  final String title;
  final String? subtitle;
  final Widget Function(BuildContext context, T option, bool selected)?
      leadingBuilder;
  final EdgeInsetsGeometry rowPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: rowPadding,
        child: Row(
          children: [
            if (leadingBuilder != null) ...[
              leadingBuilder!(context, option, selected),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: selected ? colors.deepNavy : colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 21,
              height: 21,
              child: selected
                  ? AppIcons.icon(
                      AppIconKey.check,
                      color: colors.deepNavy,
                      size: 21,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
