import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/budget_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  throw UnimplementedError('Override with Dio instance');
});

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

  BudgetListNotifier(this._service) : super(const BudgetListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final budgets = await _service.list();
      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create(CreateBudgetDto dto) async {
    try {
      final budget = await _service.create(dto);
      state = state.copyWith(budgets: [...state.budgets, budget]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> update(String id, CreateBudgetDto dto) async {
    try {
      final updated = await _service.update(id, dto);
      state = state.copyWith(
        budgets: state.budgets.map((b) => b.id == id ? updated : b).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        budgets: state.budgets.where((b) => b.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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
  void setCurrency(String code) =>
      state = state.copyWith(currencyCode: code);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void reset() => state = const BudgetFormState();
}

final budgetFormProvider =
    StateNotifierProvider<BudgetFormNotifier, BudgetFormState>(
  (_) => BudgetFormNotifier(),
);
