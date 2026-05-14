import 'package:conscia_app/screens/family/family_setup_screen.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family setup explains sharing and premium requirement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FamilySetupScreen()),
      ),
    );

    expect(find.text('Create Family Space'), findsWidgets);
    expect(
      find.text(
          'Family Space shares household planning, not private accounts.'),
      findsOneWidget,
    );
    expect(
      find.text(
          'Requires Premium to create. Invited members can participate free.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Create Family Space'),
        findsOneWidget);
  });

  testWidgets('family setup uses Conscia v2 floating inputs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FamilySetupScreen()),
      ),
    );

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
      floatingFields.any((field) => field.label == 'Family Space name'),
      isTrue,
    );
    expect(
      floatingFields.any((field) => field.label == 'Shared currency'),
      isTrue,
    );
    expect(find.byType(TextFormField), findsNothing);
  });
}
