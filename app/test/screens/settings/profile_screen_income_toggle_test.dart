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
    String? displayName,
    String? profilePictureKey,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    String? aiPersonalityIntensity,
  }) async {
    lastUpdate = {
      'preferredCurrency': preferredCurrency,
      'locale': locale,
      'displayName': displayName,
      'profilePictureKey': profilePictureKey,
      'photoUrl': photoUrl,
      'spendingPersonality': spendingPersonality,
      'incomeRange': incomeRange,
      'occupationType': occupationType,
      'householdSize': householdSize,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'aiPersonalityIntensity': aiPersonalityIntensity,
    };

    return UserProfile(
      id: 'user-1',
      email: 'profile@example.com',
      currencyCode: 'USD',
      locale: 'en_US',
      displayName: displayName,
      profilePictureKey: profilePictureKey,
      photoUrl: photoUrl,
      createdAt: DateTime(2026),
      hasCompletedOnboarding: true,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
    );
  }
}

void main() {
  testWidgets('profile can save editable monthly income range', (
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
              displayName: 'Arvie Aguirre',
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
    await tester.drag(
      find.byKey(const PageStorageKey('profile-shell-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prefer not to say'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('profile-shell-scroll')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(userService.lastUpdate?['incomeRange'], 'prefer_not_to_say');
  });
}
