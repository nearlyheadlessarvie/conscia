import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_response.freezed.dart';
part 'ai_response.g.dart';

@freezed
class AIResponse with _$AIResponse {
  const factory AIResponse({
    required String devilMessage,
    required String angelMessage,
    required String neutralMessage,
    BudgetContext? budgetContext,
  }) = _AIResponse;

  factory AIResponse.fromJson(Map<String, dynamic> json) =>
      _$AIResponseFromJson(json);
}

@freezed
class BudgetContext with _$BudgetContext {
  const factory BudgetContext({
    required String category,
    required double monthlyLimit,
    required double currentSpend,
    required double percentUsed,
    required String currencyCode,
  }) = _BudgetContext;

  factory BudgetContext.fromJson(Map<String, dynamic> json) =>
      _$BudgetContextFromJson(json);
}
