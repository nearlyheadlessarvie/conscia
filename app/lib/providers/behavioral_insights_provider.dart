import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../models/behavioral_insights.dart';
import '../core/constants/api_constants.dart';

final behavioralInsightsServiceProvider =
    Provider<BehavioralInsightsService>((ref) {
  return BehavioralInsightsService(ref.watch(dioProvider));
});

class BehavioralInsightsService {
  final Dio _dio;

  BehavioralInsightsService(this._dio);

  Future<BehavioralInsights> getBehavioralInsights() async {
    final response = await _dio.get(ApiConstants.behavioralInsights);
    return BehavioralInsights.fromJson(response.data);
  }
}

final behavioralInsightsProvider =
    FutureProvider<BehavioralInsights>((ref) async {
  final service = ref.watch(behavioralInsightsServiceProvider);
  return service.getBehavioralInsights();
});
