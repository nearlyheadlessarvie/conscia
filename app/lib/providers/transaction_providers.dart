import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_error.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';
import '../services/transaction_service.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(dioProvider));
});

final categoryFilterProvider = StateProvider<String?>((ref) {
  ref.watch(authCacheScopeProvider);
  return null;
});

final transactionScopeFilterProvider = StateProvider<String>((ref) {
  ref.watch(authCacheScopeProvider);
  return 'personal';
});

final transactionDateFilterProvider = StateProvider<TransactionDateFilter?>((
  ref,
) {
  ref.watch(authCacheScopeProvider);
  return null;
});

class TransactionListState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionService? _service;
  final String? _categoryFilter;
  final String? _scopeFilter;
  final TransactionDateFilter? _dateFilter;

  TransactionListNotifier(
    this._service,
    this._categoryFilter, [
    this._scopeFilter,
    this._dateFilter,
  ]) : super(const TransactionListState()) {
    loadMore();
  }

  TransactionListNotifier.fromList(List<Transaction> txs)
      : _service = null,
        _categoryFilter = null,
        _scopeFilter = null,
        _dateFilter = null,
        super(TransactionListState(
          transactions: txs,
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        ));

  TransactionListNotifier.empty()
      : _service = null,
        _categoryFilter = null,
        _scopeFilter = null,
        _dateFilter = null,
        super(const TransactionListState(
          transactions: [],
          isLoading: false,
          hasMore: false,
          currentPage: 0,
        ));

  Future<void> loadMore() async {
    final service = _service;
    if (service == null || !mounted || state.isLoading || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final result = await service.list(
        page: nextPage,
        category: _categoryFilter,
        scope: _scopeFilter,
        from: _dateFilter?.from,
        to: _dateFilter?.to,
      );
      if (!mounted) return;
      final current = state;
      state = current.copyWith(
        transactions: _mergeTransactions(current.transactions, result.items),
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e, s) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: AppError.from(e, stackTrace: s).userMessage,
      );
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    state = const TransactionListState();
    await loadMore();
  }

  List<Transaction> _mergeTransactions(
    List<Transaction> current,
    List<Transaction> incoming,
  ) {
    final merged = <Transaction>[];
    final seenIds = <String>{};

    for (final transaction in [...current, ...incoming]) {
      if (seenIds.add(transaction.id)) {
        merged.add(transaction);
      }
    }

    return merged;
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return TransactionListNotifier.empty();
  final service = ref.watch(transactionServiceProvider);
  return TransactionListNotifier(service, null);
});

final filteredTransactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return TransactionListNotifier.empty();
  final service = ref.watch(transactionServiceProvider);
  final category = ref.watch(categoryFilterProvider);
  final scope = ref.watch(transactionScopeFilterProvider);
  final dateFilter = ref.watch(transactionDateFilterProvider);
  return TransactionListNotifier(service, category, scope, dateFilter);
});

final transactionDetailProvider =
    FutureProvider.family<Transaction, String>((ref, id) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw StateError(
        'Cannot load transaction without an authenticated session.');
  }
  final service = ref.watch(transactionServiceProvider);
  try {
    return await service.getById(id);
  } catch (e, s) {
    throw AppError.from(e, stackTrace: s);
  }
});
