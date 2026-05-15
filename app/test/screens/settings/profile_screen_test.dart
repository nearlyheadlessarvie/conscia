import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/profile_screen.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/hero_shortcut_card.dart';
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
    bool? locationSuggestionsEnabled,
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
      'locationSuggestionsEnabled': locationSuggestionsEnabled,
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
  testWidgets('profile saves display name and editable onboarding facts', (
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
    await tester.enterText(
      find.byType(TextField).first,
      'Arvie Updated',
    );
    await tester.drag(
      find.byKey(const PageStorageKey('profile-shell-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spending style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prefer not to say'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Occupation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Household'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('profile-shell-scroll')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(userService.lastUpdate?['displayName'], 'Arvie Updated');
    expect(userService.lastUpdate?['spendingPersonality'], 'saver');
    expect(userService.lastUpdate?['incomeRange'], 'prefer_not_to_say');
    expect(userService.lastUpdate?['occupationType'], 'student');
    expect(userService.lastUpdate?['householdSize'], 'shared');
  });

  testWidgets('profile uses bleeding hero and removes preferences-only fields',
      (
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

    expect(
      find.byKey(const ValueKey('profile-editorial-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('conscia-app-bar-capsule')),
      findsOneWidget,
    );
    expect(find.text('PROFILE HUB'), findsOneWidget);
    expect(find.text('Keep your money profile personal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-hero-display-name-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-hero-email-pill')),
      findsOneWidget,
    );
    expect(find.text('PERSONAL DETAILS'), findsOneWidget);
    expect(find.text('MONEY PROFILE'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-action')), findsOneWidget);
    expect(find.text('profile@example.com'), findsOneWidget);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.byType(HeroShortcutCard), findsNothing);
    expect(find.text('Currency'), findsNothing);
    expect(find.text('AI Personality Intensity'), findsNothing);
  });

  testWidgets('profile photo affordance is available in personal details', (
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
              currencyCode: 'PHP',
              locale: 'en_US',
              displayName: 'Arvie Aguirre',
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

    expect(find.byKey(const ValueKey('profile-photo-action')), findsOneWidget);
    expect(userService.lastUpdate, isNull);
  });
}
