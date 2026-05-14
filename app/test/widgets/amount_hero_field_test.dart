import 'package:conscia_app/widgets/amount_hero_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AmountHeroField matches the taller v2 form field rhythm',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: AmountHeroField(
              controller: controller,
              currencyCode: 'PHP',
              locale: 'en_US',
              isExpense: true,
              isPremium: true,
              onChanged: (_) {},
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AmountHeroField)).height, 65);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.textAlignVertical, TextAlignVertical.center);
    expect(textField.decoration?.constraints, isNull);
  });

  testWidgets('AmountHeroField blocks alphabetic input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountHeroField(
            controller: controller,
            currencyCode: 'PHP',
            locale: 'en_US',
            isExpense: true,
            isPremium: true,
            onChanged: (_) {},
            onCurrencyChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'dfdfd');

    expect(controller.text, isEmpty);
  });

  testWidgets('AmountHeroField masks currency input with grouping and cents',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountHeroField(
            controller: controller,
            currencyCode: 'PHP',
            locale: 'en_US',
            isExpense: true,
            isPremium: true,
            onChanged: (_) {},
            onCurrencyChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1212312.56465413');

    expect(controller.text, '1,212,312.56');
  });

  testWidgets('AmountHeroField masks locale decimal separators',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountHeroField(
            controller: controller,
            currencyCode: 'EUR',
            locale: 'de_DE',
            isExpense: true,
            isPremium: true,
            onChanged: (_) {},
            onCurrencyChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1.234,56');

    expect(controller.text, '1.234,56');
  });
}
