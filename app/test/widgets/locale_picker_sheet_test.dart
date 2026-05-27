import 'package:conscia_app/widgets/locale_picker_sheet.dart';
import 'package:conscia_app/widgets/conscia_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeSupportedLocale maps unsupported variants to a supported format',
      () {
    expect(normalizeSupportedLocale('en_PH'), 'en_US');
    expect(normalizeSupportedLocale('en_IE'), 'en_US');
    expect(normalizeSupportedLocale('de_AT'), 'de_DE');
    expect(normalizeSupportedLocale('fr_CH'), 'fr_FR');
    expect(normalizeSupportedLocale('en_IN'), 'en_IN');
    expect(normalizeSupportedLocale(null), 'en_US');
  });

  testWidgets('LocalePickerSheet uses a check icon for grouped options',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => LocalePickerSheet.show(
                context,
                selectedLocale: 'en_US',
                onSelected: (_) {},
              ),
              child: const Text('Open locale picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open locale picker'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsciaGlyph), findsOneWidget);
    expect(find.text('✓'), findsNothing);
  });

  testWidgets('LocalePickerSheet hugs the option list without draggable filler',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => LocalePickerSheet.show(
                context,
                selectedLocale: 'en_US',
                onSelected: (_) {},
              ),
              child: const Text('Open locale picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open locale picker'));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });

  testWidgets('LocalePickerSheet highlights the normalized selected locale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => LocalePickerSheet.show(
                context,
                selectedLocale: 'en_PH',
                onSelected: (_) {},
              ),
              child: const Text('Open locale picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open locale picker'));
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
    expect(find.byType(ConsciaGlyph), findsOneWidget);
  });
}
