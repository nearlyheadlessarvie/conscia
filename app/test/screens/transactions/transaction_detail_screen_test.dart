import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/ai_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_detail_screen.dart';
import 'package:conscia_app/services/ai_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/conscience_mark.dart';
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

  @override
  Future<void> updateRegret(String id, int regretLevel) async {}
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

class _DelayedReflectionAIService extends AIService {
  _DelayedReflectionAIService() : super(Dio());

  @override
  Future<AIResponse> reflection({required String transactionId}) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    return const AIResponse(
      impulse: 'Impulse',
      reason: 'Reason',
      neutral: 'Reflection',
    );
  }
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

  testWidgets('detail screen shows contextual regret alert for matching transaction',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-9',
      amount: 1500,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Late Night Delivery',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
      regretLevel: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => [
                AppAlert(
                  id: 'reflection-follow-up-tx-9',
                  type: 'ReflectionFollowUp',
                  title: 'This purchase still deserves a second look',
                  message: 'A reflection can help you spot the pattern.',
                  priority: 40,
                  actionLabel: 'Reflect now',
                  transactionId: 'tx-9',
                  isDismissed: false,
                  createdAt: DateTime.utc(2026, 5, 8),
                ),
              ]),
          transactionDetailProvider.overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-9'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('This purchase still deserves a second look'), findsOneWidget);
    expect(find.text('Reflect now'), findsOneWidget);
  });

  testWidgets('shows shared loader while reflection is loading', (tester) async {
    final transaction = Transaction(
      id: 'tx-reflect',
      amount: 320,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Coffee',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
    );

    final transactionService = _RecordingTransactionService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith((ref, id) async => transaction),
          aiServiceProvider.overrideWithValue(_DelayedReflectionAIService()),
          transactionServiceProvider.overrideWithValue(transactionService),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-reflect'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Ask AI to Reflect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ConscienceLoader), findsAtLeastNWidgets(1));
    expect(find.text('Reflection is making sense of the moment...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
