import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/screens/transactions/transaction_list_screen.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StaticTransactionService extends TransactionService {
  _StaticTransactionService(this.transactions) : super(Dio());

  final List<Transaction> transactions;

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    return PaginatedTransactions(
      items: category == null
          ? transactions
          : transactions.where((t) => t.category == category).toList(),
      totalCount: transactions.length,
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}

class _LoadingTransactionListNotifier extends TransactionListNotifier {
  _LoadingTransactionListNotifier(String? selectedCategory)
      : super(null, selectedCategory) {
    state = const TransactionListState(
      transactions: [],
      isLoading: true,
      hasMore: true,
      currentPage: 0,
    );
  }
}

Future<void> _pumpTransactionList(
  WidgetTester tester, {
  required List<Transaction> transactions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
      ],
      child: const MaterialApp(home: TransactionListScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  test('category filter only affects the transaction screen list provider',
      () async {
    final container = ProviderContainer(
      overrides: [
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService([
            Transaction(
              id: 'tx-dining',
              amount: 12,
              currencyCode: 'USD',
              category: 'Dining',
              description: 'Cafe',
              type: 'expense',
              date: DateTime(2026, 5, 8),
            ),
            Transaction(
              id: 'tx-bills',
              amount: 40,
              currencyCode: 'USD',
              category: 'Bills',
              description: 'Power',
              type: 'expense',
              date: DateTime(2026, 5, 7),
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionListProvider.notifier).refresh();
    expect(
      container.read(transactionListProvider).transactions.map((tx) => tx.id),
      containsAll(['tx-dining', 'tx-bills']),
    );

    container.read(categoryFilterProvider.notifier).state = 'Dining';
    await container.read(filteredTransactionListProvider.notifier).refresh();

    expect(
      container
          .read(filteredTransactionListProvider)
          .transactions
          .map((tx) => tx.id)
          .toSet(),
      {'tx-dining'},
    );
    expect(
      container.read(transactionListProvider).transactions.map((tx) => tx.id),
      containsAll(['tx-dining', 'tx-bills']),
    );
  });

  testWidgets('transaction list exposes add action in the header', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const TransactionListScreen(),
        ),
        GoRoute(
          path: '/transactions/add',
          builder: (_, __) => const Scaffold(
            body: Text('Add transaction screen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionServiceProvider.overrideWithValue(
            _StaticTransactionService(const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add transaction'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction screen'), findsOneWidget);
  });

  testWidgets('selected transaction filters stay compact without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpTransactionList(
      tester,
      transactions: [
        Transaction(
          id: 'tx-1',
          amount: 1,
          currencyCode: 'USD',
          category: 'Bills',
          description: 'Bills',
          type: 'expense',
          date: DateTime(2026, 5, 8),
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('selection-chip-button-All')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey('selection-chip-check-All')), findsNothing);
  });

  testWidgets('transaction filters stay visible while filtered list refreshes',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredTransactionListProvider.overrideWith(
            (ref) => _LoadingTransactionListNotifier('Gift'),
          ),
          categoryFilterProvider.overrideWith((ref) => 'Gift'),
        ],
        child: const MaterialApp(home: TransactionListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-chip-button-Gift')),
        findsOneWidget);
    expect(find.byType(SkeletonListTile), findsWidgets);
  });

  testWidgets('transaction filters render as a horizontal chip rail', (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      transactions: [
        Transaction(
          id: 'tx-1',
          amount: 1,
          currencyCode: 'USD',
          category: 'Gift',
          description: 'Gift',
          type: 'expense',
          date: DateTime(2026, 5, 8),
        ),
        Transaction(
          id: 'tx-2',
          amount: 1,
          currencyCode: 'USD',
          category: 'Groceries',
          description: 'Groceries',
          type: 'expense',
          date: DateTime(2026, 5, 8),
        ),
        Transaction(
          id: 'tx-3',
          amount: 1,
          currencyCode: 'USD',
          category: 'Subscriptions',
          description: 'Subscriptions',
          type: 'expense',
          date: DateTime(2026, 5, 8),
        ),
      ],
    );

    final allY = tester
        .getCenter(find.byKey(const ValueKey('selection-chip-button-All')))
        .dy;
    final giftY = tester
        .getCenter(find.byKey(const ValueKey('selection-chip-button-Gift')))
        .dy;
    final groceriesY = tester
        .getCenter(
            find.byKey(const ValueKey('selection-chip-button-Groceries')))
        .dy;
    final subscriptionsY = tester
        .getCenter(
            find.byKey(const ValueKey('selection-chip-button-Subscriptions')))
        .dy;

    expect((allY - giftY).abs(), lessThan(8));
    expect((allY - groceriesY).abs(), lessThan(8));
    expect((allY - subscriptionsY).abs(), lessThan(8));
  });

  testWidgets('renders recurring badge in transaction list item', (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      transactions: [
        Transaction(
          id: 'tx-1',
          amount: 9.99,
          currencyCode: 'PHP',
          category: 'Subscriptions',
          description: 'Spotify',
          type: 'expense',
          date: DateTime(2026, 5, 31),
          recurringScheduleId: 'schedule-1',
          recurringOccurrenceDate: DateTime(2026, 5, 31),
        ),
      ],
    );

    expect(find.text('Recurring'), findsOneWidget);
  });
}
