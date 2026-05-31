import 'dart:async';

import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/services/auth_service.dart';
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
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
    state = initialState;
  }
}

class _DeferredTransactionService extends TransactionService {
  _DeferredTransactionService() : super(Dio());

  final completer = Completer<PaginatedTransactions>();

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
    DateTime? from,
    DateTime? to,
    String? nextToken,
  }) {
    return completer.future;
  }
}

class _DuplicatePageTransactionService extends TransactionService {
  _DuplicatePageTransactionService(this.transactions) : super(Dio());

  final List<Transaction> transactions;

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
    DateTime? from,
    DateTime? to,
    String? nextToken,
  }) async {
    return PaginatedTransactions(
      items: transactions,
      totalCount: transactions.length,
      page: page,
      pageSize: pageSize,
      hasMore: page == 1,
    );
  }
}

class _CursorTransactionService extends TransactionService {
  _CursorTransactionService() : super(Dio());

  final seenTokens = <String?>[];

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
    DateTime? from,
    DateTime? to,
    String? nextToken,
  }) async {
    seenTokens.add(nextToken);
    final transactionNumber = seenTokens.length;

    return PaginatedTransactions(
      items: [
        Transaction(
          id: 'tx-$transactionNumber',
          amount: 24,
          currencyCode: 'PHP',
          category: 'Dining',
          description: 'Lunch $transactionNumber',
          type: 'expense',
          date: DateTime(2026, 5, 22).subtract(
            Duration(days: transactionNumber),
          ),
        ),
      ],
      totalCount: transactionNumber,
      page: page,
      pageSize: pageSize,
      hasMore: transactionNumber == 1,
      nextToken: transactionNumber == 1 ? 'cursor-2' : null,
    );
  }
}

void main() {
  test('ignores an in-flight transaction load after provider disposal',
      () async {
    final service = _DeferredTransactionService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
        transactionServiceProvider.overrideWithValue(service),
      ],
    );

    container.read(transactionListProvider);
    container.dispose();

    service.completer.complete(
      const PaginatedTransactions(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        hasMore: false,
      ),
    );
    await service.completer.future;
    await Future<void>.delayed(Duration.zero);
  });

  test('deduplicates transactions when the same page data is appended', () async {
    final service = _DuplicatePageTransactionService([
      Transaction(
        id: 'tx-1',
        amount: 24,
        currencyCode: 'PHP',
        category: 'Dining',
        description: 'Lunch',
        type: 'expense',
        date: DateTime(2026, 5, 22),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
        transactionServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);
    await container.read(transactionListProvider.notifier).loadMore();

    expect(container.read(transactionListProvider).transactions, hasLength(1));
  });

  test('uses the returned cursor when loading the next transaction page',
      () async {
    final service = _CursorTransactionService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              userId: 'user-1',
            ),
          ),
        ),
        transactionServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(transactionListProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(transactionListProvider.notifier).loadMore();

    expect(service.seenTokens, [null, 'cursor-2']);
    expect(container.read(transactionListProvider).nextToken, isNull);
    expect(
      container.read(transactionListProvider).transactions.map((tx) => tx.id),
      ['tx-1', 'tx-2'],
    );
  });
}
