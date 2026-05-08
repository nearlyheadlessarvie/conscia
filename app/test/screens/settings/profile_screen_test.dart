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
  testWidgets('untouched optional spending style stays unset when saving', (
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
              incomeRange: null,
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
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(userService.lastUpdate?['spendingPersonality'], isNull);
  });

  testWidgets('profile uses branded avatars for profile choice chips', (
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
              spendingPersonality: 'balanced',
              incomeRange: 'high',
              occupationType: 'employed',
              householdSize: 'family',
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

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();

    expect(chips, isNotEmpty);
    expect(chips.first.avatar, isNotNull);
    expect(chips.first.avatar, isNot(isA<Icon>()));
  });

  testWidgets('profile shows explicit monthly income ranges', (tester) async {
    final userService = _RecordingUserService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'profile@example.com',
              currencyCode: 'PHP',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
              spendingPersonality: 'balanced',
              incomeRange: 'high',
              occupationType: 'employed',
              householdSize: 'family',
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

    expect(find.text('Under PHP 20,000'), findsOneWidget);
    expect(find.text('PHP 20,000 - PHP 50,000'), findsOneWidget);
    expect(find.text('PHP 50,000 - PHP 100,000'), findsOneWidget);
    expect(find.text('Over PHP 100,000'), findsOneWidget);
    expect(find.text('Prefer not to say'), findsOneWidget);
  });
}
