import 'package:conscia_app/core/theme/app_theme.dart';
import 'package:conscia_app/widgets/location_assistance_prompt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('location prompt uses the shared CTA row button language',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: LocationAssistancePromptSheet()),
      ),
    );

    final notNow = find.widgetWithText(OutlinedButton, 'Not now');
    final turnOn = find.widgetWithText(FilledButton, 'Turn on');

    expect(notNow, findsOneWidget);
    expect(turnOn, findsOneWidget);
    expect(tester.getSize(notNow).height, 48);
    expect(tester.getSize(turnOn).height, 48);
    expect(tester.getTopLeft(notNow).dy, tester.getTopLeft(turnOn).dy);
    expect(tester.getSize(notNow).width, tester.getSize(turnOn).width);

    final outlined = tester.widget<OutlinedButton>(notNow);
    final filled = tester.widget<FilledButton>(turnOn);

    expect(outlined.style, isNull);
    expect(filled.style, isNull);
  });
}
