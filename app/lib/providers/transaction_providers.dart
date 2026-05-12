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

  TransactionListNotifier(
    this._service,
    this._categoryFilter, [
    this._scopeFilter,
  ]) : super(const TransactionListState()) {
    loadMore();
  }

  TransactionListNotifier.fromList(List<Transaction> txs)
      : _service = null,
        _categoryFilter = null,
        _scopeFilter = null,
        super(TransactionListState(
          transactions: txs,
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        ));

  Future<void> loadMore() async {
    final service = _service;
    if (service == null || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final result = await service.list(
        page: nextPage,
        category: _categoryFilter,
        scope: _scopeFilter,
      );
      state = state.copyWith(
        transactions: [...state.transactions, ...result.items],
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e, s) {
      state = state.copyWith(
        isLoading: false,
        error: AppError.from(e, stackTrace: s).userMessage,
      );
    }
  }

  Future<void> refresh() async {
    state = const TransactionListState();
    await loadMore();
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionListNotifier(service, null);
});

final filteredTransactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  final category = ref.watch(categoryFilterProvider);
  return TransactionListNotifier(service, category);
});

final transactionDetailProvider =
    FutureProvider.family<Transaction, String>((ref, id) async {
  final service = ref.watch(transactionServiceProvider);
  try {
    return await service.getById(id);
  } catch (e, s) {
    throw AppError.from(e, stackTrace: s);
  }
});
