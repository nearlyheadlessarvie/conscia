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

  testWidgets('FloatingLabelTextField gives raised labels more breathing room',
      (tester) async {
    final controller = TextEditingController(text: 'very cramped?');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingLabelTextField(
            controller: controller,
            label: 'What are you thinking of buying?',
          ),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(FloatingLabelTextField),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(container.constraints?.minHeight, 64);

    final textFieldPaddings = tester
        .widgetList<Padding>(
          find.ancestor(
            of: find.byType(TextField),
            matching: find.byType(Padding),
          ),
        )
        .map((padding) => padding.padding);
    expect(
      textFieldPaddings,
      contains(const EdgeInsets.fromLTRB(14, 28, 14, 10)),
    );
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

  testWidgets('FloatingLabelTextField focuses from label and icon chrome',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: FloatingLabelTextField(
              controller: controller,
              focusNode: focusNode,
              label: 'Email',
              prefix: const Icon(Icons.email_outlined),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.email_outlined));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();

    await tester.tap(find.text('Email'), warnIfMissed: false);
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });
}
