import 'package:flutter/material.dart';

import 'conscia_bottom_sheet.dart';
import 'single_select_list.dart';

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
      builder: (_) => _LocalePickerBody(
        selectedLocale: selectedLocale,
        onSelected: onSelected,
      ),
    );
  }
}

class _LocalePickerBody extends StatelessWidget {
  final String selectedLocale;
  final ValueChanged<String> onSelected;

  const _LocalePickerBody({
    required this.selectedLocale,
    required this.onSelected,
  });

  static const _locales = [
    ('en_US', 'Default', '1,234,567.89'),
    ('de_DE', 'European', '1.234.567,89'),
    ('fr_FR', 'French / Swiss', '1 234 567,89'),
    ('en_IN', 'Indian', '12,34,567.89'),
  ];

  @override
  Widget build(BuildContext context) {
    (String, String, String)? selectedOption;
    for (final locale in _locales) {
      if (locale.$1 == selectedLocale) {
        selectedOption = locale;
        break;
      }
    }

    return ConsciaBottomSheetScaffold(
      title: 'Region Format',
      subtitle:
          'Changes how numbers and dates are shown. App language stays in English.',
      child: SingleSelectList<(String, String, String)>(
        options: _locales,
        value: selectedOption,
        titleBuilder: (locale) => locale.$2,
        subtitleBuilder: (locale) => locale.$3,
        rowPadding: const EdgeInsets.symmetric(vertical: 10),
        onChanged: (locale) {
          onSelected(locale.$1);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
