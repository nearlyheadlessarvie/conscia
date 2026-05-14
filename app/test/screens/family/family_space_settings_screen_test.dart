import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_space_settings_screen.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family settings focuses on household management', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HOUSEHOLD'), findsOneWidget);
    expect(find.text('Household name'), findsOneWidget);
    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('MANAGE'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Schedule contribution'), findsNothing);
    expect(find.text('Recent family activity'), findsNothing);
  });

  testWidgets('rename household sheet uses floating label input', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
      floatingFields.any((field) => field.label == 'Household name'),
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Household name',
      ),
      findsNothing,
    );
  });

  testWidgets('family settings hides household rename for non-owners', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Contributor',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Household name'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Invites'), findsNothing);
    expect(find.text('Import personal records'), findsNothing);
    expect(find.text('Schedule contribution'), findsNothing);
  });
}
