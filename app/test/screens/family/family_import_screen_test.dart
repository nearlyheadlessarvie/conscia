import 'package:conscia_app/models/family_import_preview.dart';
import 'package:conscia_app/screens/family/family_import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family import screen explains explicit sharing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FamilyImportScreen()),
    );

    expect(find.text('Import personal records'), findsWidgets);
    expect(
      find.text('Nothing is shared until you preview and choose records.'),
      findsOneWidget,
    );
    expect(
        find.widgetWithText(FilledButton, 'Preview records'), findsOneWidget);
  });

  testWidgets('family import item can be selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyImportPreviewList(
            preview: const FamilyImportPreview(
              familySpaceId: 'family-1',
              warning: 'Visible to family.',
              items: [
                FamilyImportItem(
                  recordType: 'budget',
                  recordId: 'budget-1',
                  label: 'Dining budget',
                  category: 'Dining',
                  amount: 4000,
                  currencyCode: 'PHP',
                ),
              ],
            ),
            selectedIds: const {},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Dining budget'), findsOneWidget);
    expect(find.text('PHP 4,000.00'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });
}
