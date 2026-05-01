import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class AIResponse {
  final String verdict;
  final String reasoning;
  final double confidenceScore;
  final List<String> alternatives;

  const AIResponse({
    required this.verdict,
    required this.reasoning,
    required this.confidenceScore,
    required this.alternatives,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      verdict: json['verdict'] as String,
      reasoning: json['reasoning'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      alternatives: (json['alternatives'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
}
