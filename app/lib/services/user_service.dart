import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String currencyCode;
  final String locale;
  final DateTime createdAt;
  final String? spendingPersonality;
  final String? incomeRange;
  final String? occupationType;
  final String? householdSize;
  final bool hasCompletedOnboarding;
  final bool locationSuggestionsEnabled;
  final String aiPersonalityIntensity;

  const UserProfile({
    required this.id,
    required this.email,
    required this.currencyCode,
    required this.locale,
    required this.createdAt,
    required this.hasCompletedOnboarding,
    this.locationSuggestionsEnabled = false,
    this.aiPersonalityIntensity = 'balanced',
    this.displayName,
    this.photoUrl,
    this.spendingPersonality,
    this.incomeRange,
    this.occupationType,
    this.householdSize,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      photoUrl: json['photoUrl'] as String? ?? json['avatarUrl'] as String?,
      currencyCode:
          (json['currencyCode'] ?? json['preferredCurrency']) as String? ??
              'USD',
      locale: json['locale'] as String? ?? 'en_US',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      locationSuggestionsEnabled:
          json['locationSuggestionsEnabled'] as bool? ?? false,
      aiPersonalityIntensity:
          json['aiPersonalityIntensity'] as String? ?? 'balanced',
      spendingPersonality: json['spendingPersonality'] as String?,
      incomeRange: json['incomeRange'] as String?,
      occupationType: json['occupationType'] as String?,
      householdSize: json['householdSize'] as String?,
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
    String? preferredCurrency,
    String? locale,
    String? displayName,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.profile,
        data: {
          if (preferredCurrency != null) 'preferredCurrency': preferredCurrency,
          if (locale != null) 'locale': locale,
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (spendingPersonality != null)
            'spendingPersonality': spendingPersonality,
          if (incomeRange != null) 'incomeRange': incomeRange,
          if (occupationType != null) 'occupationType': occupationType,
          if (householdSize != null) 'householdSize': householdSize,
          if (hasCompletedOnboarding != null)
            'hasCompletedOnboarding': hasCompletedOnboarding,
          if (locationSuggestionsEnabled != null)
            'locationSuggestionsEnabled': locationSuggestionsEnabled,
          if (aiPersonalityIntensity != null)
            'aiPersonalityIntensity': aiPersonalityIntensity,
        },
      );
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
