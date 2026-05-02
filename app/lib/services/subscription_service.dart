import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class SubscriptionStatus {
  final String tier;
  final bool isPremium;
  final DateTime? expiresAt;

  const SubscriptionStatus({
    required this.tier,
    required this.isPremium,
    this.expiresAt,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['tier'] as String? ?? 'free',
      isPremium: json['isActive'] as bool? ?? json['isPremium'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}

class SubscriptionService {
  final Dio _dio;

  SubscriptionService(this._dio);

  Future<SubscriptionStatus> getStatus() async {
    final response = await _dio.get(ApiConstants.subscriptionStatus);
    return SubscriptionStatus.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> verifyIos(String token) async {
    await _dio.post(
      '${ApiConstants.verifyReceipt}/ios',
      data: {'token': token},
    );
  }

  Future<void> verifyAndroid(String token) async {
    await _dio.post(
      '${ApiConstants.verifyReceipt}/android',
      data: {'token': token},
    );
  }
}
