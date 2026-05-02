import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.watch(dioProvider));
});

class PrePurchaseFormState {
  final String description;
  final double? amount;
  final String currencyCode;
  final String? category;

  const PrePurchaseFormState({
    this.description = '',
    this.amount,
    this.currencyCode = 'USD',
    this.category,
  });

  bool get isValid =>
      description.isNotEmpty && amount != null && category != null;

  PrePurchaseFormState copyWith({
    String? description,
    double? amount,
    String? currencyCode,
    String? category,
  }) {
    return PrePurchaseFormState(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
    );
  }
}

class PrePurchaseFormNotifier extends StateNotifier<PrePurchaseFormState> {
  PrePurchaseFormNotifier() : super(const PrePurchaseFormState());

  void setDescription(String v) => state = state.copyWith(description: v);
  void setAmount(double v) => state = state.copyWith(amount: v);
  void setCurrency(String v) => state = state.copyWith(currencyCode: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void reset() => state = const PrePurchaseFormState();
}

final prePurchaseFormProvider =
    StateNotifierProvider<PrePurchaseFormNotifier, PrePurchaseFormState>(
  (_) => PrePurchaseFormNotifier(),
);

final prePurchaseResponseProvider =
    FutureProvider.autoDispose<AIResponse?>((ref) async {
  return null;
});
