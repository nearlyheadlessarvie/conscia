import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/screens/transactions/transaction_detail_screen.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _RecordingTransactionService extends TransactionService {
  _RecordingTransactionService() : super(Dio());

  String? deletedId;

  @override
  Future<void> delete(String id) async {
    deletedId = id;
  }
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

void main() {
  testWidgets('detail screen falls back to Unknown when description is empty', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-2',
      amount: 250,
      currencyCode: 'PHP',
      category: 'Dining',
      description: '',
      type: 'expense',
      date: DateTime(2026, 5, 7, 19, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('detail screen shows edited transaction returned from edit route',
      (
    tester,
  ) async {
    final originalTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Watami',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final updatedTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Ippudo',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final router = GoRouter(
      initialLocation: '/transactions/tx-1',
      routes: [
        GoRoute(
          path: '/transactions/:id',
          builder: (_, state) => TransactionDetailScreen(
            transactionId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(updatedTransaction),
                    child: const Text('Return updated'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith(
            (ref, id) async => originalTransaction,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Watami'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return updated'));
    await tester.pumpAndSettle();

    expect(find.text('Ippudo'), findsOneWidget);
    expect(find.text('Watami'), findsNothing);
  });

  testWidgets('detail screen delete updates local budget usage immediately', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-1',
      amount: 12.5,
      currencyCode: 'USD',
      category: 'Coffee',
      description: 'Morning Brew',
      type: 'expense',
      date: DateTime(2026, 5, 7, 9, 0),
    );
    final transactionService = _RecordingTransactionService();

    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Coffee',
              monthlyLimit: 100,
              spent: 32.5,
              currencyCode: 'USD',
              percentage: 0.325,
              isOverBudget: false,
            ),
          ]),
        ),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
        transactionServiceProvider.overrideWithValue(transactionService),
        transactionDetailProvider.overrideWith((ref, id) async => transaction),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 20);
    expect(updatedBudget.percentage, 0.2);
    expect(transactionService.deletedId, 'tx-1');
  });
}
