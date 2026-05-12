import 'package:conscia_app/models/family_import_preview.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family import screen explains explicit sharing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FamilyImportScreen()),
    );

    expect(find.text('Import personal records'), findsWidgets);
    expect(find.text('Choose what to share'), findsOneWidget);
    expect(find.text('Nothing is shared until you import selected records.'),
        findsOneWidget);
    expect(find.text('Record types'), findsOneWidget);
    expect(find.text('Categories to include'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.repeat_outlined), findsOneWidget);
    expect(
        find.widgetWithText(FilledButton, 'Preview records'), findsOneWidget);
  });

  testWidgets('family import preview shows selection summary and item rows', (
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
                  recordType: 'transaction',
                  recordId: 'tx-1',
                  label: 'Starbucks',
                  category: 'Dining',
                  amount: 280,
                  currencyCode: 'PHP',
                ),
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

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Starbucks'), findsOneWidget);
    expect(find.text('Dining budget'), findsOneWidget);
    expect(find.text('PHP 4,000.00'), findsOneWidget);
    expect(find.text('0 of 2 selected'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets('family import cancel resets preview state', (
    tester,
  ) async {
    final actions = _PreviewOnlyFamilySpaceActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceActionsProvider.overrideWithValue(actions),
        ],
        child: const MaterialApp(home: FamilyImportScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Preview records'));
    await tester.pumpAndSettle();

    expect(find.text('Review before sharing'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Review before sharing'), findsNothing);
    expect(
        find.widgetWithText(FilledButton, 'Preview records'), findsOneWidget);
  });
}

class _PreviewOnlyFamilySpaceActions implements FamilySpaceActions {
  @override
  Future<void> acceptInvite(String inviteId) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelInvite(String inviteId) {
    throw UnimplementedError();
  }

  @override
  Future<FamilySpace> create({
    required String name,
    required String currencyCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> declineInvite(String inviteId) {
    throw UnimplementedError();
  }

  @override
  Future<int> importRecords(List<FamilyImportSelection> selections) {
    throw UnimplementedError();
  }

  @override
  Future<void> invite({
    required String email,
    required String role,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FamilyImportPreview> previewImport({
    required bool includeTransactions,
    required bool includeBudgets,
    required bool includeRecurringSchedules,
    List<String> categories = const [],
  }) async =>
      const FamilyImportPreview(
        familySpaceId: 'family-1',
        warning: 'Visible to family.',
        items: [
          FamilyImportItem(
            recordType: 'transaction',
            recordId: 'tx-1',
            label: 'Starbucks',
            category: 'Dining',
            amount: 280,
            currencyCode: 'PHP',
          ),
        ],
      );

  @override
  Future<FamilySpace> updateName(String name) {
    throw UnimplementedError();
  }
}
