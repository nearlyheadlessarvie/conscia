import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/screens/budgets/budgets_screen.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

Future<void> _pumpBudgetsScreen(
  WidgetTester tester, {
  required List<Budget> budgets,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(budgets)),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'premium',
            isPremium: true,
          ),
        ),
      ],
      child: const MaterialApp(home: BudgetsScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('budgets screen empty state uses shared hero language',
      (tester) async {
    await _pumpBudgetsScreen(tester, budgets: const []);

    expect(find.text('Budgets that match how you actually spend'),
        findsOneWidget);
    expect(find.text('Create your first budget'), findsOneWidget);
  });

  testWidgets('budgets screen list shows redesigned progress cards',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Monthly cap'), findsOneWidget);
    expect(find.text('Spent so far'), findsOneWidget);
  });

  testWidgets('budgets screen uses pull to refresh instead of a refresh icon',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('budgets screen uses a single vertical scroll container',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
