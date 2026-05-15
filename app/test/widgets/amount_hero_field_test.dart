import 'package:conscia_app/widgets/amount_hero_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AmountHeroField matches the taller v2 form field rhythm',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: AmountHeroField(
              controller: controller,
              focusNode: focusNode,
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
    expect(
        tester
            .getSize(find.byKey(const ValueKey('amount-hero-field-container')))
            .height,
        65);
    expect(tester.getSize(find.byType(TextField)).height, 32);
    final containerLeft = tester
        .getTopLeft(find.byKey(const ValueKey('amount-hero-field-container')))
        .dx;
    final currencyLeft = tester
        .getTopLeft(find.byKey(const ValueKey('amount-currency-label')))
        .dx;
    expect(currencyLeft - containerLeft, closeTo(16, 1));
    final textFieldLeft = tester.getTopLeft(find.byType(TextField)).dx;
    expect(textFieldLeft - containerLeft, closeTo(80, 1));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode, focusNode);
    expect(textField.textAlign, TextAlign.end);
    expect(textField.textAlignVertical, TextAlignVertical.center);
    expect(textField.decoration?.prefixIcon, isNull);
    expect(textField.decoration?.isCollapsed, isTrue);
    expect(textField.decoration?.border, InputBorder.none);
    expect(textField.decoration?.constraints, isNull);
    expect(textField.decoration?.hintText, '0.00');
  });

  testWidgets('AmountHeroField localizes its empty amount placeholder',
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

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.hintText, '0,00');
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
