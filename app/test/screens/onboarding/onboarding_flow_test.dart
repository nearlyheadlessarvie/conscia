import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/onboarding/about_you_screen.dart';
import 'package:conscia_app/screens/onboarding/setup_screen.dart';
import 'package:conscia_app/screens/onboarding/spending_profile_screen.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingUserService extends UserService {
  _RecordingUserService() : super(Dio());

  final List<Map<String, dynamic>> updates = [];

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
  }) async {
    updates.add({
      'preferredCurrency': preferredCurrency,
      'locale': locale,
      'spendingPersonality': spendingPersonality,
      'incomeRange': incomeRange,
      'occupationType': occupationType,
      'householdSize': householdSize,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    });

    return UserProfile(
      id: 'user-1',
      email: 'user@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: hasCompletedOnboarding ?? false,
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('setup screen advances into onboarding wizard', (tester) async {
    final userService = _RecordingUserService();
    final router = GoRouter(
      initialLocation: '/onboarding/setup',
      routes: [
        GoRoute(
          path: '/onboarding/setup',
          builder: (_, __) => const SetupScreen(),
        ),
        GoRoute(
          path: '/onboarding/profile',
          builder: (_, __) => const Scaffold(body: Text('profile-step')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userServiceProvider.overrideWithValue(userService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text("Let's Go!"));
    await tester.pumpAndSettle();

    expect(find.text('profile-step'), findsOneWidget);
    expect(userService.updates.single['preferredCurrency'], isNotNull);
    expect(userService.updates.single['locale'], isNotNull);
  });

  testWidgets(
    'spending profile next persists prefer-not-to-say and routes to budgets',
    (tester) async {
      final userService = _RecordingUserService();
      final router = GoRouter(
        initialLocation: '/onboarding/profile',
        routes: [
          GoRoute(
            path: '/onboarding/profile',
            builder: (_, __) => const SpendingProfileScreen(),
          ),
          GoRoute(
            path: '/onboarding/budgets',
            builder: (_, state) {
              final extra = state.extra as Map<String, String?>?;
              return Scaffold(
                body: Text(
                  'budgets:${extra?['spendingPersonality']}:${extra?['incomeRange']}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userServiceProvider.overrideWithValue(userService),
            currentUserProvider.overrideWith(
              (ref) async => UserProfile(
                id: 'user-1',
                email: 'user@example.com',
                currencyCode: 'USD',
                locale: 'en_US',
                createdAt: DateTime(2026),
                hasCompletedOnboarding: false,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('budgets:balanced:prefer_not_to_say'), findsOneWidget);
      expect(userService.updates.single['spendingPersonality'], 'balanced');
      expect(userService.updates.single['incomeRange'], 'prefer_not_to_say');
    },
  );

  testWidgets('about you skip marks onboarding complete and returns home', (
    tester,
  ) async {
    final userService = _RecordingUserService();
    final router = GoRouter(
      initialLocation: '/onboarding/about',
      routes: [
        GoRoute(
          path: '/onboarding/about',
          builder: (_, __) => const AboutYouScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userServiceProvider.overrideWithValue(userService),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'user@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: false,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
    expect(userService.updates.single['hasCompletedOnboarding'], true);
  });
}
