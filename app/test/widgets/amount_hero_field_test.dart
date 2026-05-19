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
    expect(
      tester.getSize(find.byKey(const ValueKey('amount-editable-line'))).height,
      34,
    );
    final containerCenter = tester
        .getRect(find.byKey(const ValueKey('amount-hero-field-container')))
        .center
        .dy;
    final editableLineCenter = tester
        .getRect(find.byKey(const ValueKey('amount-editable-line')))
        .center
        .dy;
    expect(editableLineCenter, closeTo(containerCenter, 1));
    final containerLeft = tester
        .getTopLeft(find.byKey(const ValueKey('amount-hero-field-container')))
        .dx;
    final currencyLeft = tester
        .getTopLeft(find.byKey(const ValueKey('amount-currency-label')))
        .dx;
    expect(currencyLeft - containerLeft, closeTo(16, 1));
    final editableLineLeft = tester
        .getTopLeft(find.byKey(const ValueKey('amount-editable-line')))
        .dx;
    expect(editableLineLeft - containerLeft, closeTo(80, 1));

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.focusNode, focusNode);
    expect(editableText.maxLines, 1);
    expect(editableText.textAlign, TextAlign.end);
    expect(find.text('0.00'), findsOneWidget);
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

    expect(find.text('0,00'), findsOneWidget);
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

    await tester.enterText(find.byType(EditableText), 'dfdfd');

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

    await tester.enterText(find.byType(EditableText), '1212312.56465413');

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

    await tester.enterText(find.byType(EditableText), '1.234,56');

    expect(controller.text, '1.234,56');
  });
}
