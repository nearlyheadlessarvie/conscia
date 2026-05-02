import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class AIBudgetContext {
  final double monthlyLimit;
  final double currentSpend;
  final double percentUsed;
  final bool isOverBudget;

  const AIBudgetContext({
    required this.monthlyLimit,
    required this.currentSpend,
    required this.percentUsed,
    required this.isOverBudget,
  });

  factory AIBudgetContext.fromJson(Map<String, dynamic> json) {
    return AIBudgetContext(
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      currentSpend: (json['currentSpend'] as num).toDouble(),
      percentUsed: (json['percentUsed'] as num).toDouble(),
      isOverBudget: json['isOverBudget'] as bool,
    );
  }
}

class AIResponse {
  final String impulse;
  final String reason;
  final String neutral;
  final AIBudgetContext? budget;

  const AIResponse({
    required this.impulse,
    required this.reason,
    required this.neutral,
    this.budget,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    final budgetJson = json['budget'] as Map<String, dynamic>?;
    return AIResponse(
      impulse: json['devilMessage'] as String? ?? json['impulse'] as String? ?? '',
      reason: json['angelMessage'] as String? ?? json['reason'] as String? ?? '',
      neutral: json['neutralMessage'] as String? ?? json['neutral'] as String? ?? '',
      budget: budgetJson != null ? AIBudgetContext.fromJson(budgetJson) : null,
    );
  }
}

class AIService {
  final Dio _dio;

  AIService(this._dio);

  Future<AIResponse> prePurchase({
    required String description,
    required double amount,
    required String currencyCode,
    required String category,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiAdvice,
        data: {
          'description': description,
          'amount': amount,
          'currencyCode': currencyCode,
          'category': category,
        },
      );
      return AIResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<AIResponse> reflection({required String transactionId}) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiReflection,
        data: {'transactionId': transactionId},
      );
      return AIResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
