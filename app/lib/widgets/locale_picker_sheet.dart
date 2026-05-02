import 'package:flutter/material.dart';

class LocalePickerSheet {
  LocalePickerSheet._();

  static Future<void> show(
    BuildContext context, {
    required String selectedLocale,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
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
    ('en_US', 'English (US)', '1,234.56'),
    ('en_GB', 'English (UK)', '1,234.56'),
    ('es_MX', 'Español (México)', '1,234.56'),
    ('es_ES', 'Español (España)', '1.234,56'),
    ('fr_FR', 'Français', '1 234,56'),
    ('de_DE', 'Deutsch', '1.234,56'),
    ('pt_BR', 'Português (Brasil)', '1.234,56'),
    ('ja_JP', '日本語', '1,234'),
    ('zh_CN', '中文 (简体)', '1,234.56'),
    ('ko_KR', '한국어', '1,234'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Number Format',
            style: textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _locales.length,
            itemBuilder: (context, index) {
              final locale = _locales[index];
              final isSelected = locale.$1 == selectedLocale;

              return ListTile(
                title: Text(locale.$2),
                subtitle: Text('Preview: ${locale.$3}'),
                trailing: isSelected
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () {
                  onSelected(locale.$1);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
