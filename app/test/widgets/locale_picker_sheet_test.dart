import 'package:conscia_app/widgets/locale_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('✓'), findsNothing);
  });
}
