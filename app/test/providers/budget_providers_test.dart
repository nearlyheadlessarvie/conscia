import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;
  int listCalls = 0;

  @override
  Future<List<Budget>> list() async {
    listCalls += 1;
    return budgets;
  }
}

void main() {
  ProviderContainer buildContainer(_StaticBudgetService service) {
    return ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(service),
      ],
    );
  }

  test('optimistic expense apply updates matching budget spend immediately',
      () async {
    final service = _StaticBudgetService(const [
      Budget(
        id: 'budget-1',
        category: 'Dining',
        monthlyLimit: 500,
        spent: 100,
        currencyCode: 'USD',
        percentage: 0.2,
        isOverBudget: false,
      ),
    ]);

    final container = buildContainer(service);
    addTearDown(container.dispose);

    await container.read(budgetListProvider.notifier).load();

    container.read(budgetListProvider.notifier).applyOptimisticTransaction(
          Transaction(
            id: 'tx-1',
            amount: 75,
            currencyCode: 'USD',
            category: 'Dining',
            description: 'Watami',
            type: 'expense',
            date: DateTime(2026, 5, 7),
          ),
        );

    final updated = container.read(budgetListProvider).budgets.single;
    expect(updated.spent, 175);
    expect(updated.percentage, 0.35);
    expect(updated.isOverBudget, isFalse);
  });

  test('optimistic expense apply ignores categories without budgets', () async {
    final service = _StaticBudgetService(const [
      Budget(
        id: 'budget-1',
        category: 'Groceries',
        monthlyLimit: 300,
        spent: 25,
        currencyCode: 'USD',
        percentage: 0.08,
        isOverBudget: false,
      ),
    ]);

    final container = buildContainer(service);
    addTearDown(container.dispose);

    await container.read(budgetListProvider.notifier).load();

    container.read(budgetListProvider.notifier).applyOptimisticTransaction(
          Transaction(
            id: 'tx-1',
            amount: 40,
            currencyCode: 'USD',
            category: 'Dining',
            description: 'Watami',
            type: 'expense',
            date: DateTime(2026, 5, 7),
          ),
        );

    final updated = container.read(budgetListProvider).budgets.single;
    expect(updated.spent, 25);
  });
}
