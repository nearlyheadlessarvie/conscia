import 'dart:async';

import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async =>
      null;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }
}

final _authenticatedOverride = authProvider.overrideWith(
  (ref) => _TestAuthNotifier(
    const AuthState(status: AuthStatus.authenticated, userId: 'user-1'),
  ),
);

class _DeferredBudgetService extends BudgetService {
  _DeferredBudgetService() : super(Dio());

  final completer = Completer<List<Budget>>();

  @override
  Future<List<Budget>> list() {
    return completer.future;
  }
}

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
  test('ignores an in-flight budget load after provider disposal', () async {
    final service = _DeferredBudgetService();
    final container = ProviderContainer(
      overrides: [
        _authenticatedOverride,
        budgetServiceProvider.overrideWithValue(service),
      ],
    );

    container.read(budgetListProvider);
    container.dispose();

    service.completer.complete(const []);
    await service.completer.future;
    await Future<void>.delayed(Duration.zero);
  });

  test('budget json percentUsed is normalized from percent to ratio', () {
    final budget = Budget.fromJson({
      'id': 'budget-1',
      'category': 'Shopping',
      'monthlyLimit': 10654.65,
      'currentSpend': 1000.0,
      'currencyCode': 'PHP',
      'percentUsed': 9.38,
      'isOverBudget': false,
    });

    expect(budget.percentage, closeTo(0.0938, 0.00001));
    expect(budget.isOverBudget, isFalse);
  });

  ProviderContainer buildContainer(_StaticBudgetService service) {
    return ProviderContainer(
      overrides: [
        _authenticatedOverride,
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

  test('optimistic expense update reconciles previous and new budgets',
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
      Budget(
        id: 'budget-2',
        category: 'Coffee',
        monthlyLimit: 200,
        spent: 40,
        currencyCode: 'USD',
        percentage: 0.2,
        isOverBudget: false,
      ),
    ]);

    final container = buildContainer(service);
    addTearDown(container.dispose);

    await container.read(budgetListProvider.notifier).load();

    container
        .read(budgetListProvider.notifier)
        .applyOptimisticTransactionUpdate(
          previousTransaction: Transaction(
            id: 'tx-1',
            amount: 25,
            currencyCode: 'USD',
            category: 'Dining',
            description: 'Old merchant',
            type: 'expense',
            date: DateTime(2026, 5, 7),
          ),
          updatedTransaction: Transaction(
            id: 'tx-1',
            amount: 10,
            currencyCode: 'USD',
            category: 'Coffee',
            description: 'New merchant',
            type: 'expense',
            date: DateTime(2026, 5, 7),
          ),
        );

    final budgets = container.read(budgetListProvider).budgets;
    expect(
        budgets.firstWhere((budget) => budget.category == 'Dining').spent, 75);
    expect(
        budgets.firstWhere((budget) => budget.category == 'Coffee').spent, 50);
  });

  test('optimistic expense delete removes spend from matching budget',
      () async {
    final service = _StaticBudgetService(const [
      Budget(
        id: 'budget-1',
        category: 'Coffee',
        monthlyLimit: 100,
        spent: 32.5,
        currencyCode: 'USD',
        percentage: 0.325,
        isOverBudget: false,
      ),
    ]);

    final container = buildContainer(service);
    addTearDown(container.dispose);

    await container.read(budgetListProvider.notifier).load();

    container
        .read(budgetListProvider.notifier)
        .applyOptimisticTransactionDelete(
          Transaction(
            id: 'tx-1',
            amount: 12.5,
            currencyCode: 'USD',
            category: 'Coffee',
            description: 'Morning Brew',
            type: 'expense',
            date: DateTime(2026, 5, 7),
          ),
        );

    final updated = container.read(budgetListProvider).budgets.single;
    expect(updated.spent, 20);
    expect(updated.percentage, 0.2);
  });
}
