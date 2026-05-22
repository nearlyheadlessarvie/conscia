import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';

enum SelectionCardSemantics { radio, check }

class SelectionCardGroup<T> extends StatelessWidget {
  const SelectionCardGroup({
    super.key,
    required this.options,
    required this.value,
    required this.titleBuilder,
    required this.onChanged,
    this.subtitleBuilder,
    this.leadingBuilder,
    this.semantics = SelectionCardSemantics.radio,
    this.spacing = 12,
  });

  final List<T> options;
  final T? value;
  final String Function(T option) titleBuilder;
  final String? Function(T option)? subtitleBuilder;
  final Widget? Function(T option, bool selected)? leadingBuilder;
  final ValueChanged<T> onChanged;
  final SelectionCardSemantics semantics;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _SelectionCard<T>(
            option: options[index],
            selected: options[index] == value,
            title: titleBuilder(options[index]),
            subtitle: subtitleBuilder?.call(options[index]),
            leading: leadingBuilder?.call(
              options[index],
              options[index] == value,
            ),
            semantics: semantics,
            onTap: () => onChanged(options[index]),
          ),
          if (index < options.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class _SelectionCard<T> extends StatelessWidget {
  const _SelectionCard({
    required this.option,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.semantics,
    required this.onTap,
  });

  final T option;
  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final SelectionCardSemantics semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final optionKey = option.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected && semantics == SelectionCardSemantics.radio
                ? const Color(0xFFF5F7FF)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? colors.deepNavy : colors.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedInk,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionIndicator(
                key: ValueKey('selection-indicator-$optionKey'),
                selected: selected,
                semantics: semantics,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    super.key,
    required this.selected,
    required this.semantics,
  });

  final bool selected;
  final SelectionCardSemantics semantics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    if (semantics == SelectionCardSemantics.check) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: selected ? colors.deepNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? colors.deepNavy : colors.border,
            width: 1.5,
          ),
        ),
        child: selected
            ? AppIcons.icon(
                AppIconKey.check,
                color: Colors.white,
                size: 14,
              )
            : null,
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.deepNavy : colors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: selected ? 10 : 0,
          height: selected ? 10 : 0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.deepNavy : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
