import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/profile_screen.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingUserService extends UserService {
  _RecordingUserService() : super(Dio());

  Map<String, dynamic>? lastUpdate;

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    lastUpdate = {
      'preferredCurrency': preferredCurrency,
      'locale': locale,
      'spendingPersonality': spendingPersonality,
      'incomeRange': incomeRange,
      'occupationType': occupationType,
      'householdSize': householdSize,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'locationSuggestionsEnabled': locationSuggestionsEnabled,
      'aiPersonalityIntensity': aiPersonalityIntensity,
    };

    return UserProfile(
      id: 'user-1',
      email: 'profile@example.com',
      currencyCode: 'USD',
      locale: 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: true,
      locationSuggestionsEnabled: locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
    );
  }
}

void main() {
  testWidgets('selected income range can be cleared before saving', (
    tester,
  ) async {
    final userService = _RecordingUserService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'profile@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
              spendingPersonality: null,
              incomeRange: 'mid',
              occupationType: null,
              householdSize: null,
            ),
          ),
          userServiceProvider.overrideWithValue(userService),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('USD 20,000 - USD 50,000'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(userService.lastUpdate?['incomeRange'], isNull);
  });
}
