import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/onboarding/about_you_screen.dart';
import 'package:conscia_app/screens/onboarding/onboarding_screen.dart';
import 'package:conscia_app/screens/onboarding/setup_screen.dart';
import 'package:conscia_app/screens/onboarding/spending_profile_screen.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/single_select_list.dart';
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
    updates.add({
      'preferredCurrency': preferredCurrency,
      'locale': locale,
      'displayName': displayName,
      'spendingPersonality': spendingPersonality,
      'incomeRange': incomeRange,
      'occupationType': occupationType,
      'householdSize': householdSize,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'locationSuggestionsEnabled': locationSuggestionsEnabled,
      'aiPersonalityIntensity': aiPersonalityIntensity,
    });

    return UserProfile(
      id: 'user-1',
      email: 'user@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: hasCompletedOnboarding ?? false,
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('setup currency picker is not premium gated', (tester) async {
    final userService = _RecordingUserService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userServiceProvider.overrideWithValue(userService),
        ],
        child: const MaterialApp(
          home: SetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade'), findsNothing);
    expect(find.textContaining('Free tier:'), findsNothing);
  });

  testWidgets('setup screen describes locale as region format', (tester) async {
    final userService = _RecordingUserService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userServiceProvider.overrideWithValue(userService),
        ],
        child: const MaterialApp(
          home: SetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Region Format'), findsOneWidget);
    expect(
      find.textContaining('App language stays in English'),
      findsOneWidget,
    );
  });

  testWidgets(
    'setup screen defaults to the device currency and shows it first in the picker',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'en',
        'PH',
      );
      tester.binding.platformDispatcher.localesTestValue = const [
        Locale('en', 'PH'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      final userService = _RecordingUserService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userServiceProvider.overrideWithValue(userService),
          ],
          child: const MaterialApp(
            home: SetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PHP'), findsWidgets);

      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      final currencyTiles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where((tile) => tile.leading is Text)
          .toList();
      final firstCurrencyTile = currencyTiles.first;
      final firstCurrencyTitle = firstCurrencyTile.title! as Text;

      expect(firstCurrencyTitle.data, 'PHP');
    },
  );

  testWidgets('onboarding first slide uses a calm abstract scene', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Build a calmer money rhythm'), findsOneWidget);
    expect(find.text('A calmer start'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('/sprites/'),
      ),
      findsNothing,
    );
  });

  testWidgets('onboarding uses calm copy on slides two and three', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Notice patterns without shame'), findsOneWidget);
    expect(find.text('Patterns, softly'), findsOneWidget);
    expect(
      find.text(
        'Log what happened, see the signal, and keep the tone kind.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Let gentle guardrails help'), findsOneWidget);
    expect(find.text('Gentle guardrails'), findsOneWidget);
    expect(
      find.text(
        'Budgets, reflections, and insights work together without the pressure.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'spending profile requires income selection before routing to budgets',
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

      expect(
        find.text(
            'Choose a monthly income range, or select Prefer not to say.'),
        findsOneWidget,
      );
      expect(userService.updates, isEmpty);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -520),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prefer not to say'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('budgets:balanced:prefer_not_to_say'), findsOneWidget);
      expect(userService.updates.single['spendingPersonality'], 'balanced');
      expect(userService.updates.single['incomeRange'], 'prefer_not_to_say');
    },
  );

  testWidgets(
    'spending profile income labels prefer setup currency from route extras',
    (tester) async {
      final userService = _RecordingUserService();
      final router = GoRouter(
        initialLocation: '/onboarding/profile',
        routes: [
          GoRoute(
            path: '/onboarding/profile',
            builder: (_, state) {
              final extra = state.extra as Map<String, String?>?;
              return SpendingProfileScreen(
                initialCurrencyCode: extra?['currencyCode'],
                initialLocale: extra?['locale'],
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
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go(
        '/onboarding/profile',
        extra: {
          'currencyCode': 'EUR',
          'locale': 'en_IE',
        },
      );

      await tester.pumpAndSettle();

      expect(find.text('Under EUR 20,000'), findsOneWidget);
      expect(find.text('Under USD 20,000'), findsNothing);
    },
  );

  testWidgets('about you requires display name before completing onboarding', (
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

    expect(find.text('Skip'), findsNothing);
    expect(find.text('PERSONAL DETAILS'), findsOneWidget);
    expect(
      find.text('This is the name Conscia will use around the app.'),
      findsOneWidget,
    );
    expect(find.text('Go to dashboard'), findsOneWidget);

    var button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Go to dashboard'),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Story Demo');
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Go to dashboard'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Go to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
    expect(userService.updates.single['hasCompletedOnboarding'], true);
    expect(userService.updates.single['displayName'], 'Story Demo');
  });

  testWidgets('about you uses flat check lists for single-select facts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
          userServiceProvider.overrideWithValue(_RecordingUserService()),
        ],
        child: const MaterialApp(
          home: AboutYouScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final lists = tester
        .widgetList<SingleSelectList<String>>(
            find.byType(SingleSelectList<String>))
        .toList();

    expect(lists.length, 2);
    expect(find.byType(Radio<String>), findsNothing);
    expect(find.byType(Divider), findsWidgets);

    await tester.tap(find.text('Employed'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
