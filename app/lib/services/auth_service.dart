import 'package:dio/dio.dart';
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

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<AuthTokens> register(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
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
    } on DioException {
      rethrow;
    }
  }

  Future<AuthTokens> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final response = await _dio.post(
      ApiConstants.googleSignIn,
      data: {'idToken': googleAuth.idToken},
    );
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthTokens> signInWithApple() async {
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
  }
}
