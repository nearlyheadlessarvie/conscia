import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class SubscriptionStatus {
  final String tier;
  final bool isPremium;
  final DateTime? expiresAt;
  final int transactionLimit;
  final int transactionCount;
  final int budgetLimit;
  final int budgetCount;

  const SubscriptionStatus({
    required this.tier,
    required this.isPremium,
    this.expiresAt,
    required this.transactionLimit,
    required this.transactionCount,
    required this.budgetLimit,
    required this.budgetCount,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['tier'] as String? ?? 'free',
      isPremium: json['isPremium'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      transactionLimit: json['transactionLimit'] as int? ?? 50,
      transactionCount: json['transactionCount'] as int? ?? 0,
      budgetLimit: json['budgetLimit'] as int? ?? 3,
      budgetCount: json['budgetCount'] as int? ?? 0,
    );
  }
}

class SubscriptionService {
  final Dio _dio;

  SubscriptionService(this._dio);

  Future<SubscriptionStatus> getStatus() async {
    try {
      final response = await _dio.get(ApiConstants.subscriptionStatus);
      return SubscriptionStatus.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> verifyIos(String token) async {
    try {
      await _dio.post(
        '${ApiConstants.verifyReceipt}/ios',
        data: {'receipt': token},
      );
    } on DioException {
      rethrow;
    }
  }

  Future<void> verifyAndroid(String token) async {
    try {
      await _dio.post(
        '${ApiConstants.verifyReceipt}/android',
        data: {'purchaseToken': token},
      );
    } on DioException {
      rethrow;
    }
  }
}
