import 'package:conscia_app/screens/family/family_setup_screen.dart';
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
      find.text('Family Space shares household planning, not private accounts.'),
      findsOneWidget,
    );
    expect(
      find.text('Requires Premium to create. Invited members can participate free.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Create Family Space'), findsOneWidget);
  });
}
