import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class AuthTokens {
  final String accessToken;
  final String? idToken;
  final String refreshToken;
  final String userId;

  const AuthTokens({
    required this.accessToken,
    this.idToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      idToken: json['idToken'] as String?,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
    );
  }
}

class AuthConfirmationRequiredException implements Exception {
  final String email;

  const AuthConfirmationRequiredException({required this.email});

  @override
  String toString() => 'Email confirmation required';
}

class AuthRegistrationResult {
  final bool success;
  final bool requiresConfirmation;
  final String? email;
  final String? userId;

  const AuthRegistrationResult({
    required this.success,
    required this.requiresConfirmation,
    this.email,
    this.userId,
  });

  factory AuthRegistrationResult.fromJson(Map<String, dynamic> json) {
    return AuthRegistrationResult(
      success: json['success'] as bool? ?? true,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      email: json['email'] as String?,
      userId: json['userId'] as String?,
    );
  }
}

class AuthConfirmationResult {
  final bool success;
  final bool requiresConfirmation;
  final String? email;
  final String? userId;

  const AuthConfirmationResult({
    required this.success,
    this.requiresConfirmation = false,
    this.email,
    this.userId,
  });

  factory AuthConfirmationResult.fromJson(Map<String, dynamic> json) {
    return AuthConfirmationResult(
      success: json['success'] as bool? ?? true,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      email: json['email'] as String?,
      userId: json['userId'] as String?,
    );
  }
}

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<AuthRegistrationResult> register(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'email': email, 'password': password},
      );
      return AuthRegistrationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthConfirmationResult> confirmRegistration(
    String email,
    String confirmationCode,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.confirmRegistration,
        data: {'email': email, 'confirmationCode': confirmationCode},
      );
      return AuthConfirmationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthConfirmationResult> resendConfirmation(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.resendConfirmation,
        data: {'email': email},
      );
      return AuthConfirmationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthConfirmationResult> startPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.passwordResetStart,
        data: {'email': email},
      );
      return AuthConfirmationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthConfirmationResult> confirmPasswordReset(
    String email,
    String confirmationCode,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.passwordResetConfirm,
        data: {
          'email': email,
          'confirmationCode': confirmationCode,
          'password': password,
        },
      );
      return AuthConfirmationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthTokens> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['requiresConfirmation'] == true) {
        throw AuthConfirmationRequiredException(
          email: (data['email'] as String?) ?? email,
        );
      }
      rethrow;
    }
  }

  Future<AuthTokens> refreshSession(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> setPassword(String password) async {
    try {
      await _dio.post(
        ApiConstants.password,
        data: {'password': password},
      );
    } on DioException {
      rethrow;
    }
  }
}
