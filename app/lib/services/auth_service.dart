import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/constants/api_constants.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String userId;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
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

enum AppleSignInFailureKind {
  cancelled,
  unavailable,
}

enum GoogleSignInFailureKind {
  cancelled,
  missingIdToken,
  platform,
}

class AppleSignInFailure implements Exception {
  const AppleSignInFailure._(this.kind);

  const AppleSignInFailure.cancelled()
      : this._(AppleSignInFailureKind.cancelled);

  const AppleSignInFailure.unavailable()
      : this._(AppleSignInFailureKind.unavailable);

  final AppleSignInFailureKind kind;
}

class GoogleSignInFailure implements Exception {
  const GoogleSignInFailure._({
    required this.kind,
    required this.message,
    this.code,
  });

  const GoogleSignInFailure.cancelled()
      : this._(
          kind: GoogleSignInFailureKind.cancelled,
          message: 'Google sign-in was cancelled.',
        );

  const GoogleSignInFailure.missingIdToken()
      : this._(
          kind: GoogleSignInFailureKind.missingIdToken,
          message:
              'Google sign-in did not return an ID token for this app build. Please try again.',
        );

  factory GoogleSignInFailure.fromPlatformException(PlatformException error) {
    final normalizedCode = error.code.trim().toLowerCase();
    if (normalizedCode == 'sign_in_canceled' ||
        normalizedCode == 'sign_in_cancelled' ||
        normalizedCode == 'canceled' ||
        normalizedCode == 'cancelled') {
      return const GoogleSignInFailure.cancelled();
    }

    return GoogleSignInFailure._(
      kind: GoogleSignInFailureKind.platform,
      message:
          'Google sign-in could not finish on this device. Please try again.',
      code: error.code,
    );
  }

  final GoogleSignInFailureKind kind;
  final String message;
  final String? code;

  bool get isCancellation => kind == GoogleSignInFailureKind.cancelled;

  @override
  String toString() => code == null ? message : '$message ($code)';
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

  Future<AuthTokens> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        serverClientId: ApiConstants.googleServerClientId.isEmpty
            ? null
            : ApiConstants.googleServerClientId,
      ).signIn();
      if (googleUser == null) {
        throw const GoogleSignInFailure.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInFailure.missingIdToken();
      }

      final response = await _dio.post(
        ApiConstants.googleSignIn,
        data: {'idToken': idToken},
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
    } on PlatformException catch (error) {
      throw GoogleSignInFailure.fromPlatformException(error);
    }
  }

  Future<AuthTokens> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final response = await _dio.post(
        ApiConstants.appleSignIn,
        data: {
          'identityToken': credential.identityToken,
          'authorizationCode': credential.authorizationCode,
        },
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInFailure.cancelled();
      }
      throw const AppleSignInFailure.unavailable();
    } on SignInWithAppleException {
      throw const AppleSignInFailure.unavailable();
    } on PlatformException {
      throw const AppleSignInFailure.unavailable();
    }
  }
}
