import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'grouped_list_card.dart';

class LocalePickerSheet {
  LocalePickerSheet._();

  static Future<void> show(
    BuildContext context, {
    required String selectedLocale,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => _LocalePickerBody(
          selectedLocale: selectedLocale,
          onSelected: onSelected,
          scrollController: controller,
        ),
      ),
    );
  }
}

class _LocalePickerBody extends StatelessWidget {
  final String selectedLocale;
  final ValueChanged<String> onSelected;
  final ScrollController scrollController;

  const _LocalePickerBody({
    required this.selectedLocale,
    required this.onSelected,
    required this.scrollController,
  });

  static const _locales = [
    ('en_US', 'Philippines / US', '1,234,567.89'),
    ('de_DE', 'European', '1.234.567,89'),
    ('fr_FR', 'French / Swiss', '1 234 567,89'),
    ('en_IN', 'Indian', '12,34,567.89'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Region Format',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Changes how numbers and dates are shown. App language stays in English.',
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              GroupedListCard(
                children: _locales.map((locale) {
                  final isSelected = locale.$1 == selectedLocale;
                  return InkWell(
                    onTap: () {
                      onSelected(locale.$1);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(locale.$2, style: textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  locale.$3,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).appColors.mutedInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isSelected)
                            Text(
                              '✓',
                              style: textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).appColors.deepNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
