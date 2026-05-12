import 'package:conscia_app/models/family_overview.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_space_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family space screen shows shared overview cards', (
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
          familyOverviewProvider.overrideWith(
            (ref) async => FamilyOverview(
              familySpaceId: 'family-1',
              budgets: const [
                FamilyBudgetOverview(
                  id: 'budget-1',
                  category: 'Dining',
                  monthlyLimit: 4000,
                  spentThisMonth: 280,
                  usagePercent: 7,
                  currencyCode: 'PHP',
                ),
              ],
              recentActivity: [
                FamilyActivity(
                  id: 'tx-1',
                  label: 'Starbucks',
                  category: 'Dining',
                  type: 'Expense',
                  amount: 280,
                  currencyCode: 'PHP',
                  date: DateTime(2026, 5, 11),
                ),
              ],
              recurringItems: [
                FamilyRecurringOverview(
                  id: 'schedule-1',
                  label: 'Home internet',
                  category: 'Bills',
                  type: 'Expense',
                  amount: 2499,
                  currencyCode: 'PHP',
                  cadence: 'Monthly',
                  nextRunAt: DateTime(2026, 5, 16),
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('Shared budgets'), findsOneWidget);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('PHP 280.00 / 4,000.00'), findsOneWidget);
    expect(find.text('Recent family activity'), findsOneWidget);
    expect(find.text('Starbucks'), findsOneWidget);
    expect(find.text('Recurring together'), findsNothing);
    expect(find.text('Home internet'), findsNothing);
    expect(find.text('Next steps'), findsNothing);
    expect(find.text('Invite family'), findsNothing);
    expect(find.text('Import personal records'), findsNothing);
    expect(find.text('Schedule contribution'), findsNothing);
  });

  testWidgets('family space screen keeps overview read-only for viewers', (
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
              role: 'Viewer',
            ),
          ),
          familyOverviewProvider.overrideWith(
            (ref) async => const FamilyOverview(
              familySpaceId: 'family-1',
              budgets: [],
              recentActivity: [],
              recurringItems: [],
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Next steps'), findsNothing);
    expect(find.text('View-only access'), findsNothing);
    expect(find.text('Invite family'), findsNothing);
    expect(find.text('Import personal records'), findsNothing);
    expect(find.text('Schedule contribution'), findsNothing);
  });
}
