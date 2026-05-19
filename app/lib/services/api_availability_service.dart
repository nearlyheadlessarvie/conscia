import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class ApiUnavailableException implements Exception {
  const ApiUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ApiUnavailableException($message)';
}

abstract class ApiAvailabilityService {
  Future<void> checkLiveness();
}

class DioApiAvailabilityService implements ApiAvailabilityService {
  DioApiAvailabilityService(this._dio);

  final Dio _dio;

  @override
  Future<void> checkLiveness() async {
    try {
      await _dio.get<dynamic>(ApiConstants.healthLive);
    } on DioException catch (error) {
      throw ApiUnavailableException(
        error.message ?? 'Conscia is temporarily unavailable.',
      );
    }
  }
}
