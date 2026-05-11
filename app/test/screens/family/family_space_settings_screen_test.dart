import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_space_settings_screen.dart';
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

    expect(find.text('Household'), findsOneWidget);
    expect(find.text('Household name'), findsOneWidget);
    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Recent family activity'), findsNothing);
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
    expect(find.text('Invites'), findsNothing);
    expect(find.text('Import personal records'), findsOneWidget);
  });
}
