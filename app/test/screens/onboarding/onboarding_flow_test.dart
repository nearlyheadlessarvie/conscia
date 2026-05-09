import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/onboarding/about_you_screen.dart';
import 'package:conscia_app/screens/onboarding/onboarding_screen.dart';
import 'package:conscia_app/screens/onboarding/setup_screen.dart';
import 'package:conscia_app/screens/onboarding/spending_profile_screen.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/selection_chip_group.dart';
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
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    updates.add({
      'preferredCurrency': preferredCurrency,
      'locale': locale,
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

      final currencyTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Currency'),
      );
      final currencySubtitle = currencyTile.subtitle! as Text;

      expect(currencySubtitle.data, 'PHP');

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

  testWidgets('onboarding first slide uses the mascot standoff scene', (
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

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/devil/1_neutral.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/angel/1_neutral.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/1_neutral.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/devil/sprite_sheet.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/angel/sprite_sheet.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/sprite_sheet.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('onboarding uses refreshed copy on slides two and three', (
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

    expect(find.text('Track Without Shame'), findsOneWidget);
    expect(find.text('Logged in seconds'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/devil/8_whisper.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/4_save.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/devil/sprite_sheet.png',
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/sprite_sheet.png',
      ),
      findsWidgets,
    );
    expect(
      find.text(
        'Log spending in seconds, spot patterns, and stay honest without guilt.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Turn Reflection Into Better Habits'), findsOneWidget);
    expect(find.text('Reflection + budgets'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/angel/8_shield.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/1_neutral.PNG',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/angel/sprite_sheet.png',
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/sprites/money/sprite_sheet.png',
      ),
      findsWidgets,
    );
    expect(
      find.text(
        'Set budgets, notice regrets, and build a money routine that actually sticks.',
      ),
      findsOneWidget,
    );
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

  testWidgets('about you uses branded chip avatars instead of raw icons', (
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

    final chips = tester
        .widgetList<SelectionChipButton>(find.byType(SelectionChipButton))
        .toList();

    expect(chips, isNotEmpty);
    expect(chips.first.avatar, isNotNull);
    expect(chips.first.avatar, isNot(isA<Icon>()));
  });
}
