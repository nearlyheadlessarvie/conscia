import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../models/behavioral_insights.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

final behavioralInsightsServiceProvider =
    Provider<BehavioralInsightsService>((ref) {
  return BehavioralInsightsService(ref.watch(dioProvider));
});

class BehavioralInsightsService {
  final Dio _dio;

  BehavioralInsightsService(this._dio);

  Future<BehavioralInsights?> getBehavioralInsights() async {
    try {
      final response = await _dio.get(ApiConstants.behavioralInsights);
      if (response.statusCode == 204) return null;
      return BehavioralInsights.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

final behavioralInsightsProvider =
    FutureProvider<BehavioralInsights?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  final service = ref.watch(behavioralInsightsServiceProvider);
  return service.getBehavioralInsights();
});
