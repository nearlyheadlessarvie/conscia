import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class UserProfile {
  final String id;
  final String email;
  final String currencyCode;
  final String locale;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.currencyCode,
    required this.locale,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      locale: json['locale'] as String? ?? 'en_US',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<UserProfile> updateProfile({
    String? currencyCode,
    String? locale,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.profile,
        data: {
          if (currencyCode != null) 'currencyCode': currencyCode,
          if (locale != null) 'locale': locale,
        },
      );
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
