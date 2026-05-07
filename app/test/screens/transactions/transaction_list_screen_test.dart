import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/screens/transactions/transaction_list_screen.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('transaction filters stay visible while filtered list refreshes', (
    tester,
  ) async {
    final transactions = [
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
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionListProvider.overrideWith(
            (ref) => _LoadingTransactionListNotifier('Gift'),
          ),
          categoryFilterProvider.overrideWith((ref) => 'Gift'),
        ],
        child: const MaterialApp(home: TransactionListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Gift'), findsOneWidget);
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

    final allY = tester.getCenter(find.widgetWithText(ChoiceChip, 'All')).dy;
    final giftY = tester.getCenter(find.widgetWithText(ChoiceChip, 'Gift')).dy;
    final groceriesY =
        tester.getCenter(find.widgetWithText(ChoiceChip, 'Groceries')).dy;
    final subscriptionsY =
        tester.getCenter(find.widgetWithText(ChoiceChip, 'Subscriptions')).dy;

    expect((allY - giftY).abs(), lessThan(8));
    expect((allY - groceriesY).abs(), lessThan(8));
    expect((allY - subscriptionsY).abs(), lessThan(8));
  });
}
