import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingLabelTextField shows raised label when text is present',
      (tester) async {
    final controller = TextEditingController(text: 'PHP 350');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingLabelTextField(
            controller: controller,
            label: 'Amount',
          ),
        ),
      ),
    );

    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('PHP 350'), findsOneWidget);
  });

  testWidgets(
      'FloatingLabelTextField keeps the idle label clear of a leading icon',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingLabelTextField(
            controller: controller,
            label: 'Email',
            prefix: const Icon(Icons.email_outlined),
          ),
        ),
      ),
    );

    final iconRight = tester.getTopRight(find.byIcon(Icons.email_outlined)).dx;
    final labelLeft = tester.getTopLeft(find.text('Email')).dx;

    expect(labelLeft, greaterThan(iconRight));
  });
}
