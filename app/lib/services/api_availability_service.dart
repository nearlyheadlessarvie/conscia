import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class ApiUnavailableException implements Exception {
  const ApiUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ApiUnavailableException($message)';
}

class ApiUpgradeRequiredException implements Exception {
  const ApiUpgradeRequiredException(this.message);

  final String message;

  @override
  String toString() => 'ApiUpgradeRequiredException($message)';
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
      if (error.response?.statusCode == 426) {
        final responseData = error.response?.data;
        final message = responseData is Map<String, dynamic>
            ? responseData['message'] as String?
            : null;
        throw ApiUpgradeRequiredException(
          message ?? 'A newer version of Conscia is required.',
        );
      }

      throw ApiUnavailableException(
        error.message ?? 'Conscia is temporarily unavailable.',
      );
    }
  }
}
