import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.correlationId,
  });

  factory ApiException.fromDioException(DioException error) {
    ApiException fromResponse() {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] as String?) ??
              (data['error'] as String?) ??
              'Request failed'
          : 'Request failed';
      final errorCode = data is Map ? data['error'] as String? : null;
      final correlationId =
          (data is Map ? data['correlationId'] as String? : null) ??
          (data is Map ? data['referenceId'] as String? : null);

      return ApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        correlationId: correlationId,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: 'Connection timed out');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'No internet connection');
      case DioExceptionType.badResponse:
        return fromResponse();
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled');
      case DioExceptionType.badCertificate:
        return const ApiException(message: 'Invalid certificate');
      case DioExceptionType.unknown:
        if (error.response != null) {
          return fromResponse();
        }
        return ApiException(
          message: error.message ?? 'An unexpected error occurred',
        );
    }
  }

  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? correlationId;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
