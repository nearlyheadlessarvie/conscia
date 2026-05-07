import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/screens/dashboard/dashboard_screen.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

class _StaticTransactionService extends TransactionService {
  _StaticTransactionService([this.transactions = const []]) : super(Dio());

  final List<Transaction> transactions;

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    return PaginatedTransactions(
      items: transactions,
      totalCount: transactions.length,
      page: 1,
      pageSize: 20,
      hasMore: false,
    );
  }
}

class _LocalAlertsTestNotifier extends LocalAlertsNotifier {
  _LocalAlertsTestNotifier(List<AppAlert> alerts) : super() {
    state = alerts;
  }
}

Widget _buildApp(ProviderContainer container) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: DashboardScreen()),
      ),
      GoRoute(
        path: '/settings/budgets',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Budgets placeholder')),
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('recent transaction tile displays counterparty text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionTile(
            id: 'tx-1',
            categoryBadge: const Icon(Icons.restaurant),
            counterparty: 'Corner Bakery',
            category: 'Dining',
            date: DateTime(2026, 5, 7),
            amount: 12.5,
            isIncome: false,
            currencyCode: 'USD',
          ),
        ),
      ),
    );

    expect(find.text('Corner Bakery'), findsOneWidget);
  });

  testWidgets('regret prompt card displays counterparty text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: const Icon(Icons.restaurant),
            counterparty: 'Corner Bakery',
            amount: 12.5,
            currencyCode: 'USD',
            date: DateTime(2026, 5, 7),
          ),
        ),
      ),
    );

    expect(find.text('Corner Bakery'), findsOneWidget);
  });

  testWidgets('dashboard header stays visible while scrolling', (tester) async {
    final transactions = List.generate(
      12,
      (index) => Transaction(
        id: 'tx-$index',
        amount: 25 + index.toDouble(),
        currencyCode: 'USD',
        category: 'Dining',
        description: 'Transaction $index',
        type: 'expense',
        date: DateTime(2026, 5, 7).subtract(Duration(days: index)),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    final headerFinder = find.text('Conscia');
    expect(headerFinder.hitTestable(), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(headerFinder.hitTestable(), findsOneWidget);
  });

  testWidgets('dashboard surfaces local budget nudges with a budget CTA',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message:
                    'You logged an expense in Dining without a matching budget.',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsOneWidget);
    expect(find.text('Add budget'), findsOneWidget);

    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();

    expect(find.text('Budgets placeholder'), findsOneWidget);
  });

  testWidgets('dashboard can dismiss a local budget nudge', (tester) async {
    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message:
                    'You logged an expense in Dining without a matching budget.',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsNothing);
    expect(container.read(activeAlertsProvider), isEmpty);
  });

  testWidgets('dashboard hides a budget nudge once a matching budget exists',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Gaming',
              monthlyLimit: 500,
              spent: 0,
              currencyCode: 'PHP',
              percentage: 0,
              isOverBudget: false,
            ),
          ]),
        ),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-gaming',
                type: 'budget_nudge',
                title: 'No budget for Gaming yet',
                message:
                    'You logged an expense in Gaming without a matching budget.',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Gaming yet'), findsNothing);
    expect(container.read(activeAlertsProvider), isEmpty);
  });

  testWidgets('dashboard prioritizes remote regret alerts above local nudges',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'repeated-regret-category-dining',
                type: 'RepeatedRegretCategory',
                title: 'Dining keeps turning into regret',
                message: 'You have marked recent Dining purchases as regret.',
                priority: 70,
                actionLabel: 'See category trend',
                actionRoute: '/insights/categories/Dining',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 8),
              ),
            ]),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message: 'You logged an expense in Dining without a budget.',
                priority: 20,
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Dining keeps turning into regret'), findsOneWidget);
    expect(find.text('No budget for Dining yet'), findsNothing);
  });
}
