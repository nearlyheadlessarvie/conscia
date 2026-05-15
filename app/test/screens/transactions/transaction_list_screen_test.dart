import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_list_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/widgets/grouped_list_card.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

class _StaticTransactionService extends TransactionService {
  _StaticTransactionService(this.transactions) : super(Dio());

  final List<Transaction> transactions;
  String? lastScope;
  String? lastCategory;

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
  }) async {
    lastScope = scope;
    lastCategory = category;
    final filtered = transactions.where((t) {
      final matchesScope = scope == null || t.scope == scope;
      final normalizedCategory = t.category.startsWith('Family ')
          ? t.category.substring('Family '.length)
          : t.category;
      final matchesCategory =
          category == null || normalizedCategory == category;
      return matchesScope && matchesCategory;
    }).toList();

    return PaginatedTransactions(
      items: filtered,
      totalCount: filtered.length,
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
  String scope = 'personal',
  ({
    String currency,
    String locale
  }) preferences = (currency: 'PHP', locale: 'en_US'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _authenticatedOverride,
        userPreferencesProvider.overrideWithValue(preferences),
        transactionScopeFilterProvider.overrideWith((ref) => scope),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
      ],
      child: const MaterialApp(home: TransactionListScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

List<Transaction> _manyTransactions() {
  final categories = ['Bills', 'Dining', 'Gift', 'Shopping'];
  return List.generate(16, (index) {
    final category = categories[index % categories.length];
    return Transaction(
      id: 'tx-$index',
      amount: 100.0 + index,
      currencyCode: 'PHP',
      category: category,
      description: '$category $index',
      type: 'expense',
      date: DateTime(2026, 5, 8 - (index ~/ 3)),
    );
  });
}

Color _transactionsHeaderColor(WidgetTester tester) {
  final header = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
  );
  return (header.decoration! as BoxDecoration).color!;
}

void main() {
  test('category filter only affects the transaction screen list provider',
      () async {
    final container = ProviderContainer(
      overrides: [
        _authenticatedOverride,
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
          _authenticatedOverride,
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

  testWidgets('transaction list leads with editorial hero and open date groups',
      (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      transactions: [
        Transaction(
          id: 'tx-shopee',
          amount: 1250,
          currencyCode: 'PHP',
          category: 'Shopping',
          description: 'Shopee',
          type: 'expense',
          date: DateTime(2026, 5, 8),
          regretLevel: 2,
        ),
        Transaction(
          id: 'tx-spotify',
          amount: 149,
          currencyCode: 'PHP',
          category: 'Subscriptions',
          description: 'Spotify',
          type: 'expense',
          date: DateTime(2026, 5, 8),
          recurringScheduleId: 'schedule-1',
        ),
        Transaction(
          id: 'tx-book',
          amount: 640,
          currencyCode: 'PHP',
          category: 'Gift',
          description: 'National Book Store',
          type: 'expense',
          date: DateTime(2026, 5, 7),
        ),
      ],
    );

    expect(find.text('MONEY TRAIL'), findsOneWidget);
    expect(find.textContaining('Shopping is carrying'), findsOneWidget);
    expect(find.text('FRI, MAY 8'), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-chip-button-All')),
        findsOneWidget);
    expect(find.byType(GroupedListCard), findsNothing);
  });

  testWidgets('money trail aggregates transactions in the user currency', (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      preferences: (currency: 'PHP', locale: 'de_DE'),
      transactions: [
        Transaction.fromJson({
          'id': 'tx-usd',
          'amount': 100,
          'currencyCode': 'USD',
          'category': 'Dining',
          'counterparty': 'Cafe',
          'type': 'Expense',
          'date': DateTime(2026, 5, 8).toIso8601String(),
          'exchangeRateToBase': 56,
        }),
      ],
    );

    expect(find.text('₱5.600,00'), findsOneWidget);
    expect(find.text('-\$100,00'), findsOneWidget);
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

    expect(find.byKey(const ValueKey('selection-chip-button-Gift')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('transaction-filter-skeleton-pill-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-filter-skeleton-pill-1')),
      findsOneWidget,
    );
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

  testWidgets(
      'transaction filters pin below the compact header while scrolling', (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      transactions: _manyTransactions(),
    );

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -460),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final headerBottom = tester
        .getBottomLeft(
          find.byKey(const ValueKey('editorial-sticky-header-Transactions')),
        )
        .dy;
    final filterTop = tester
        .getTopLeft(find.byKey(const ValueKey('selection-chip-button-All')))
        .dy;
    final filterBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('selection-chip-button-All')))
        .dy;
    final railTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('transaction-filter-rail-overlay')),
        )
        .dy;
    final railBottom = tester
        .getBottomLeft(
          find.byKey(const ValueKey('transaction-filter-rail-overlay')),
        )
        .dy;

    expect(railTop, greaterThanOrEqualTo(headerBottom - 2));
    expect(railTop, lessThanOrEqualTo(headerBottom + 1));
    expect(filterTop, greaterThanOrEqualTo(headerBottom + 6));
    expect(filterTop, lessThanOrEqualTo(headerBottom + 10));
    expect(railBottom, lessThanOrEqualTo(filterBottom + 6));
  });

  testWidgets('docked transaction filters remain tappable', (
    tester,
  ) async {
    final service = _StaticTransactionService(_manyTransactions());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _authenticatedOverride,
          transactionServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: TransactionListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -460),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('selection-chip-button-Dining')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(service.lastCategory, 'Dining');
  });

  testWidgets(
      'transaction header restores opaque state from saved scroll offset', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    final service = _StaticTransactionService(_manyTransactions());

    Future<void> pumpSavedList() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _authenticatedOverride,
            transactionServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: const TransactionListScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpSavedList();
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -460),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(_transactionsHeaderColor(tester), isNot(Colors.transparent));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpSavedList();
    await tester.pump(const Duration(milliseconds: 220));

    expect(_transactionsHeaderColor(tester), isNot(Colors.transparent));
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

    expect(
      find.byKey(const ValueKey('recurring-transaction-badge')),
      findsOneWidget,
    );
  });

  testWidgets('family transaction displays real category with family badge', (
    tester,
  ) async {
    await _pumpTransactionList(
      tester,
      scope: 'family',
      transactions: [
        Transaction(
          id: 'tx-family',
          amount: 2460,
          currencyCode: 'PHP',
          category: 'Family Dining',
          description: 'Manam',
          type: 'expense',
          date: DateTime(2026, 5, 3),
          scope: 'family',
          familySpaceId: 'family-1',
        ),
      ],
    );

    expect(find.text('Manam'), findsOneWidget);
    expect(find.text('Dining'), findsWidgets);
    expect(find.text('Family Dining'), findsNothing);
    expect(
        find.byKey(const ValueKey('family-transaction-badge')), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-chip-button-Dining')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('selection-chip-button-Family Dining')),
      findsNothing,
    );
  });

  testWidgets(
      'transaction list uses scope pill switch instead of a family-only toggle',
      (
    tester,
  ) async {
    final service = _StaticTransactionService([
      Transaction(
        id: 'tx-personal',
        amount: 420,
        currencyCode: 'PHP',
        category: 'Transport',
        description: 'Grab',
        type: 'expense',
        date: DateTime(2026, 4, 30),
        scope: 'personal',
      ),
      Transaction(
        id: 'tx-family',
        amount: 2460,
        currencyCode: 'PHP',
        category: 'Dining',
        description: 'Manam',
        type: 'expense',
        date: DateTime(2026, 5, 3),
        scope: 'family',
        familySpaceId: 'family-1',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _authenticatedOverride,
          transactionServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: TransactionListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Personal scope is default — personal transaction is visible
    expect(find.text('Grab'), findsOneWidget);
    // No old-style icon-button family toggles
    expect(find.byTooltip('Show family transactions'), findsNothing);
    expect(find.byTooltip('Show all transactions'), findsNothing);
  });
}
