import 'package:conscia_app/widgets/single_select_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SingleSelectList uses flat rows, separators, and a checkmark',
      (tester) async {
    String selected = 'balanced';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SingleSelectList<String>(
              options: const ['mild', 'balanced', 'intense'],
              value: selected,
              titleBuilder: (option) => switch (option) {
                'mild' => 'Mild',
                'intense' => 'Intense',
                _ => 'Balanced',
              },
              subtitleBuilder: (option) => switch (option) {
                'mild' => 'Softer tone with gentler push-and-pull.',
                'intense' => 'Sharper contrast for reflection.',
                _ => 'Default mix of warmth and clarity.',
              },
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(Radio<String>), findsNothing);
    expect(find.byType(Divider), findsNWidgets(2));

    final selectedTitle = tester.widget<Text>(find.text('Balanced'));
    expect(selectedTitle.style?.fontWeight, FontWeight.w700);

    final subtitle = tester.widget<Text>(
      find.text('Default mix of warmth and clarity.'),
    );
    expect(subtitle.style?.fontWeight, isNot(FontWeight.w700));

    await tester.tap(find.text('Intense'));
    await tester.pumpAndSettle();

    expect(selected, 'intense');
  });
}
