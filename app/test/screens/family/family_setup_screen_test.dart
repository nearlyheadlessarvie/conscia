import 'package:conscia_app/screens/family/family_setup_screen.dart';
import 'package:conscia_app/providers/user_provider.dart';
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
      find.text('Plan together without exposing private accounts'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Requires Premium to create. Invited members can participate free.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Create Family Space'),
        findsOneWidget);
  });

  testWidgets('family setup uses Conscia v2 floating inputs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider
              .overrideWithValue((currency: 'USD', locale: 'en_US')),
        ],
        child: const MaterialApp(home: FamilySetupScreen()),
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
      isFalse,
    );
    expect(find.textContaining('Shared currency follows USD'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
