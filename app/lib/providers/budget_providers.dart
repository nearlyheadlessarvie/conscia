import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_error.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(ref.watch(dioProvider));
});

final budgetReconciliationEnabledProvider = Provider<bool>((_) => true);

class BudgetListState {
  final List<Budget> budgets;
  final bool isLoading;
  final String? error;

  const BudgetListState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetListState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetListState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BudgetListNotifier extends StateNotifier<BudgetListState> {
  final BudgetService _service;
  Timer? _pendingRefresh;

  BudgetListNotifier(this._service) : super(const BudgetListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final budgets = await _service.list();
      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e, s) {
      state = state.copyWith(
        isLoading: false,
        error: AppError.from(e, stackTrace: s).userMessage,
      );
    }
  }

  Future<void> create(CreateBudgetDto dto) async {
    try {
      final budget = await _service.create(dto);
      state = state.copyWith(budgets: [...state.budgets, budget]);
    } catch (e, s) {
      state =
          state.copyWith(error: AppError.from(e, stackTrace: s).userMessage);
    }
  }

  Future<void> update(String id, CreateBudgetDto dto) async {
    try {
      final updated = await _service.update(id, dto);
      state = state.copyWith(
        budgets: state.budgets.map((b) => b.id == id ? updated : b).toList(),
      );
    } catch (e, s) {
      state =
          state.copyWith(error: AppError.from(e, stackTrace: s).userMessage);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        budgets: state.budgets.where((b) => b.id != id).toList(),
      );
    } catch (e, s) {
      state =
          state.copyWith(error: AppError.from(e, stackTrace: s).userMessage);
    }
  }

  bool applyOptimisticTransaction(Transaction transaction) {
    return _applyBudgetDeltas(_transactionBudgetDeltas([
      transaction.amount
    ], [
      transaction,
    ]));
  }

  bool applyOptimisticTransactionUpdate({
    required Transaction previousTransaction,
    required Transaction updatedTransaction,
  }) {
    return _applyBudgetDeltas(
      _transactionBudgetDeltas(
        [-previousTransaction.amount, updatedTransaction.amount],
        [previousTransaction, updatedTransaction],
      ),
    );
  }

  bool applyOptimisticTransactionDelete(Transaction transaction) {
    return _applyBudgetDeltas(
      _transactionBudgetDeltas([-transaction.amount], [transaction]),
    );
  }

  Map<String, double> _transactionBudgetDeltas(
    List<double> deltas,
    List<Transaction> transactions,
  ) {
    final budgetDeltas = <String, double>{};

    for (var index = 0; index < transactions.length; index++) {
      final transaction = transactions[index];
      if (transaction.type != 'expense') continue;

      final normalizedCategory = transaction.category.trim().toLowerCase();
      if (normalizedCategory.isEmpty) continue;

      budgetDeltas.update(
        normalizedCategory,
        (value) => value + deltas[index],
        ifAbsent: () => deltas[index],
      );
    }

    return budgetDeltas;
  }

  bool _applyBudgetDeltas(Map<String, double> budgetDeltas) {
    if (budgetDeltas.isEmpty) return false;

    var didUpdate = false;
    final updatedBudgets = state.budgets.map((budget) {
      final normalizedCategory = budget.category.trim().toLowerCase();
      final delta = budgetDeltas[normalizedCategory];
      if (delta == null || delta == 0) return budget;

      didUpdate = true;
      return budget.copyWith(
        spent: math.max(0.0, budget.spent + delta),
      );
    }).toList(growable: false);

    if (!didUpdate) return false;

    state = state.copyWith(budgets: updatedBudgets);
    return true;
  }

  Future<void> refreshInBackground() async {
    try {
      final budgets = await _service.list();
      state = state.copyWith(budgets: budgets, error: null);
    } catch (e, s) {
      state =
          state.copyWith(error: AppError.from(e, stackTrace: s).userMessage);
    }
  }

  void scheduleRefreshInBackground({
    Duration delay = const Duration(seconds: 6),
  }) {
    _pendingRefresh?.cancel();
    _pendingRefresh = Timer(delay, () {
      unawaited(refreshInBackground());
    });
  }

  @override
  void dispose() {
    _pendingRefresh?.cancel();
    super.dispose();
  }
}

final budgetListProvider =
    StateNotifierProvider<BudgetListNotifier, BudgetListState>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return BudgetListNotifier(service);
});

class BudgetFormState {
  final String? category;
  final double? monthlyLimit;
  final String currencyCode;
  final bool isSubmitting;

  const BudgetFormState({
    this.category,
    this.monthlyLimit,
    this.currencyCode = 'USD',
    this.isSubmitting = false,
  });

  BudgetFormState copyWith({
    String? category,
    double? monthlyLimit,
    String? currencyCode,
    bool? isSubmitting,
  }) {
    return BudgetFormState(
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currencyCode: currencyCode ?? this.currencyCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class BudgetFormNotifier extends StateNotifier<BudgetFormState> {
  BudgetFormNotifier() : super(const BudgetFormState());

  void setCategory(String category) =>
      state = state.copyWith(category: category);
  void setMonthlyLimit(double limit) =>
      state = state.copyWith(monthlyLimit: limit);
  void setCurrency(String code) => state = state.copyWith(currencyCode: code);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void reset() => state = const BudgetFormState();
}

final budgetFormProvider =
    StateNotifierProvider<BudgetFormNotifier, BudgetFormState>(
  (ref) {
    ref.watch(authCacheScopeProvider);
    return BudgetFormNotifier();
  },
);

final hasBudgetForCategoryProvider =
    Provider.family<bool, String>((ref, category) {
  final normalizedCategory = category.trim().toLowerCase();
  if (normalizedCategory.isEmpty) return false;

  final budgets = ref.watch(budgetListProvider).budgets;
  return budgets.any(
    (budget) => budget.category.trim().toLowerCase() == normalizedCategory,
  );
});
