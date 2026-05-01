import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/health_status.dart';

class HealthService {
  final Dio _dio;

  HealthService(this._dio);

  Future<HealthStatus> checkHealth() async {
    final response = await _dio.get(ApiConstants.health);
    return HealthStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HealthStatus> checkLiveness() async {
    final response = await _dio.get(ApiConstants.healthLive);
    return HealthStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HealthStatus> checkReadiness() async {
    final response = await _dio.get(ApiConstants.healthReady);
    return HealthStatus.fromJson(response.data as Map<String, dynamic>);
  }
}
