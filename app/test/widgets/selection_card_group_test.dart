import 'package:conscia_app/widgets/selection_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('SelectionCardGroup shows radio dots for radio semantics',
      (tester) async {
    String? value = 'saver';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionCardGroup<String>(
            value: value,
            options: const ['saver', 'balanced'],
            semantics: SelectionCardSemantics.radio,
            titleBuilder: (option) => option,
            subtitleBuilder: (_) => 'subtitle',
            onChanged: (next) => value = next,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('selection-indicator-saver')),
      findsOneWidget,
    );
  });

  testWidgets('SelectionCardGroup uses hugeicons for check semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionCardGroup<String>(
            value: 'saver',
            options: const ['saver', 'balanced'],
            semantics: SelectionCardSemantics.check,
            titleBuilder: (option) => option,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(HugeIcon), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
