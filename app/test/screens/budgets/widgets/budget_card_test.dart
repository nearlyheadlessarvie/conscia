import 'package:conscia_app/screens/budgets/widgets/budget_card.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('budget card renders normalized ratio percentages',
      (tester) async {
    const budget = Budget(
      id: 'budget-1',
      category: 'Shopping',
      monthlyLimit: 10654.65,
      spent: 1000,
      currencyCode: 'PHP',
      percentage: 0.0938,
      isOverBudget: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetCard(budget: budget),
        ),
      ),
    );

    expect(find.text('9%'), findsOneWidget);
    expect(find.text('938%'), findsNothing);
    expect(find.text('Monthly cap'), findsOneWidget);
    expect(find.text('Spent so far'), findsOneWidget);
  });

  testWidgets('budget card labels family-scoped budgets', (tester) async {
    const budget = Budget(
      id: 'budget-family-1',
      category: 'Dining',
      monthlyLimit: 6500,
      spent: 3720,
      currencyCode: 'PHP',
      percentage: 0.57,
      isOverBudget: false,
      scope: 'family',
      familySpaceId: 'family-1',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetCard(budget: budget),
        ),
      ),
    );

    expect(find.text('Family budget'), findsOneWidget);
  });
}
