import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/providers/ai_provider.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/screens/assistant/pre_purchase_screen.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/voice_input_button.dart';
import 'package:conscia_app/services/ai_service.dart';
import 'package:conscia_app/widgets/conscience_mark.dart';
import 'package:dio/dio.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _assetImageFinder(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetName,
    );

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.suggestions = const (
      nearbyMerchants: ['Corner Bakery'],
      likelyCategories: ['Groceries'],
    ),
  });

  final bool permissionGranted;
  final ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) suggestions;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() => suggestions;
}

class _FakeAIService extends AIService {
  _FakeAIService({
    required this.response,
    this.delay = Duration.zero,
  }) : super(Dio());

  final AIResponse response;
  final Duration delay;
  String? receivedInsightContext;
  String? receivedCurrencyCode;
  String? receivedContextScope;

  @override
  Future<AIResponse> prePurchase({
    required String description,
    required double amount,
    required String currencyCode,
    required String category,
    String? insightContext,
    String contextScope = 'personal',
  }) async {
    receivedInsightContext = insightContext;
    receivedCurrencyCode = currencyCode;
    receivedContextScope = contextScope;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return response;
  }
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(Dio());

  @override
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
    return UserProfile(
      id: 'user-1',
      email: 'prepurchase@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: hasCompletedOnboarding ?? true,
      locationSuggestionsEnabled: locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
    );
  }
}

Future<void> _pumpPrePurchaseScreen(
  WidgetTester tester, {
  SharedPreferences? prefs,
  LocationAssistanceService? locationService,
  bool locationSuggestionsEnabled = false,
}) async {
  final resolvedPrefs = prefs ??
      await () async {
        SharedPreferences.setMockInitialValues({
          'location_suggestions_enabled': false,
          'location_suggestions_prompted': true,
        });
        return SharedPreferences.getInstance();
      }();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'prepurchase@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
            locationSuggestionsEnabled: locationSuggestionsEnabled,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(resolvedPrefs),
        userServiceProvider.overrideWithValue(_FakeUserService()),
        familySpaceProvider.overrideWith((ref) async => null),
        locationAssistanceServiceProvider.overrideWithValue(
          locationService ??
              _FakeLocationAssistanceService(permissionGranted: true),
        ),
      ],
      child: const MaterialApp(
        home: PrePurchaseScreen(),
      ),
    ),
  );
}

Future<Widget> buildPrePurchaseApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  },
}) async {
  return buildPrePurchaseAppForTier(
    tester,
    isPremium: false,
    initialPrefs: initialPrefs,
  );
}

Future<Widget> buildPrePurchaseAppForTier(
  WidgetTester tester, {
  required bool isPremium,
  String currencyCode = 'USD',
  String locale = 'en_US',
  bool locationSuggestionsEnabled = false,
  Map<String, Object> initialPrefs = const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  },
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      categoryFrequencyProvider.overrideWithValue(
        ['Health', 'Dining', 'Shopping', 'Travel', 'Education'],
      ),
      subscriptionProvider.overrideWith(
        (ref) async => SubscriptionStatus(
          tier: isPremium ? 'premium' : 'free',
          isPremium: isPremium,
        ),
      ),
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'prepurchase@example.com',
          currencyCode: currencyCode,
          locale: locale,
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      userServiceProvider.overrideWithValue(_FakeUserService()),
      familySpaceProvider.overrideWith((ref) async => null),
      locationAssistanceServiceProvider.overrideWithValue(
        _FakeLocationAssistanceService(permissionGranted: true),
      ),
    ],
    child: const MaterialApp(
      home: PrePurchaseScreen(),
    ),
  );
}

Future<void> _pumpPrePurchaseRouterApp(
  WidgetTester tester, {
  required AIService aiService,
  required LocationAssistanceService locationService,
  String currencyCode = 'USD',
  String locale = 'en_US',
  bool locationSuggestionsEnabled = false,
  DashboardInsightSummary? insightSummary,
  FamilySpace? familySpace,
}) async {
  SharedPreferences.setMockInitialValues({
    'location_suggestions_enabled': true,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/assistant',
    routes: [
      GoRoute(
        path: '/assistant',
        builder: (_, __) => const PrePurchaseScreen(),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (_, state) {
          final extra = state.extra as Map<String, String?>?;
          return TransactionFormScreen(
            initialAmount: extra?['amount'],
            initialCurrencyCode: extra?['currencyCode'],
            initialCategory: extra?['category'],
            initialCounterparty: extra?['counterparty'],
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
          ['Health', 'Dining', 'Shopping', 'Travel', 'Education'],
        ),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'prepurchase@example.com',
            currencyCode: currencyCode,
            locale: locale,
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
            locationSuggestionsEnabled: locationSuggestionsEnabled,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        userServiceProvider.overrideWithValue(_FakeUserService()),
        locationAssistanceServiceProvider.overrideWithValue(locationService),
        aiServiceProvider.overrideWithValue(aiService),
        familySpaceProvider.overrideWith((ref) async => familySpace),
        dashboardInsightSummaryProvider.overrideWith(
          (ref) async => insightSummary,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets(
      'pre-purchase assistant shows all categories entrypoint and orders sheet by recent categories',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(
      tester,
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': ['Transport', 'Dining'],
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsNothing);
    expect(find.text('More categories'), findsNothing);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Dining'), findsWidgets);

    await tester.ensureVisible(find.text('All categories'));
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);

    final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    final labels = choiceChips
        .map((chip) => (chip.label as Text).data)
        .whereType<String>()
        .toList();

    expect(labels.take(2).toList(), ['Transport', 'Dining']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Groceries').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.text('Groceries'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dining'), findsNothing);
  });

  testWidgets('pre-purchase assistant shows only one category heading',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
  });

  testWidgets(
      'pre-purchase assistant keeps a voice input control in the hero prompt area',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(tester));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceInputButton), findsOneWidget);
  });

  testWidgets(
      'pre-purchase assistant uses the layered alter ego hero on the input screen',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(tester));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-alter-ego-idle')),
        findsOneWidget);
    expect(
      _assetImageFinder('assets/images/sprites/devil/1_neutral.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/1_neutral.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/1_neutral.PNG'),
      findsNothing,
    );
    expect(
      _assetImageFinder('assets/images/sprites/devil/sprite_sheet.png'),
      findsAtLeastNWidgets(1),
    );
    expect(
      _assetImageFinder('assets/images/sprites/angel/sprite_sheet.png'),
      findsAtLeastNWidgets(1),
    );
    expect(
      _assetImageFinder('assets/images/sprites/money/sprite_sheet.png'),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('conscience-devil-neutral')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('conscience-angel-neutral')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('conscience-money-neutral')), findsOneWidget);
  });

  testWidgets('pre-purchase assistant shows the editorial prompt note',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(tester));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('assistant-editorial-note')),
      findsOneWidget,
    );
    expect(
      find.text('Both sides are standing by. What are you thinking of buying?'),
      findsOneWidget,
    );
  });

  testWidgets('shows shared loader while AI response is pending',
      (tester) async {
    await _pumpPrePurchaseRouterApp(
      tester,
      aiService: _FakeAIService(
        response: const AIResponse(
          impulse: 'Treat yourself.',
          reason: 'Check your budget.',
          neutral: 'You can decide.',
        ),
        delay: const Duration(seconds: 5),
      ),
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
      'Coffee',
    );
    await tester.enterText(find.byType(TextField).at(1), '180');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Dining'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dining'));
    await tester.pump();

    await tester.tap(find.text('Ask Conscia'));
    await tester.pump();

    expect(
        find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(find.byType(ConscienceLoader), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-assistant')),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'pre-purchase assistant shows category chips above all categories action',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseApp(tester));
    await tester.pumpAndSettle();

    final chipsTopLeft = tester.getTopLeft(find.text('Dining').first);
    final actionTopLeft = tester.getTopLeft(find.text('All categories'));

    expect(chipsTopLeft.dy, lessThan(actionTopLeft.dy));
  });

  testWidgets('pre-purchase hides upgrade-only categories for free users',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseAppForTier(
      tester,
      isPremium: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsNothing);
    expect(find.text('Health'), findsNothing);
    expect(find.text('Shopping'), findsNothing);
    expect(find.text('Dining'), findsOneWidget);

    await tester.ensureVisible(find.text('All categories'));
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);
    expect(find.text('Travel'), findsNothing);
  });

  testWidgets('pre-purchase shows all categories for premium users',
      (tester) async {
    await tester.pumpWidget(await buildPrePurchaseAppForTier(
      tester,
      isPremium: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsNothing);

    await tester.ensureVisible(find.text('All categories'));
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsWidgets);
    expect(find.text('Education'), findsWidgets);
  });

  testWidgets('pre-purchase shows first-use location prompt only when needed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsOneWidget);
    expect(find.text('You can change this later in Settings.'), findsOneWidget);
    expect(
      find.text(
        'Get nearby merchant and category suggestions wherever you need a little guidance. Suggestions only help fill things faster. You can still edit everything yourself.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);
  });

  testWidgets(
      'pre-purchase does not re-prompt after turning location assistance on',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);
  });

  testWidgets('pre-purchase can suggest merchant and category when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpPrePurchaseScreen(
      tester,
      prefs: prefs,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsOneWidget);
    expect(find.text('Corner Bakery'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);

    await tester
        .ensureVisible(find.widgetWithText(ActionChip, 'Corner Bakery'));
    await tester.tap(find.text('Corner Bakery'));
    await tester.pumpAndSettle();

    final descriptionField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
    );
    expect(descriptionField.controller?.text, 'Corner Bakery');

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.tap(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.text('Groceries'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('pre-purchase sends dashboard insight summary as AI context',
      (tester) async {
    final aiService = _FakeAIService(
      response: const AIResponse(
        impulse: 'Treat yourself.',
        reason: 'Check your recent trend.',
        neutral: 'You can decide.',
      ),
    );

    await _pumpPrePurchaseRouterApp(
      tester,
      aiService: aiService,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
      insightSummary: const DashboardInsightSummary(
        text: 'Dining is above your recent 3-month pace.',
        tone: InsightFeedTone.caution,
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
      'Starbucks coffee',
    );
    await tester.enterText(find.byType(TextField).at(1), '600');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Dining'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dining'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ask Conscia'));
    await tester.tap(find.text('Ask Conscia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(
      aiService.receivedInsightContext,
      'Dining is above your recent 3-month pace.',
    );
  });

  testWidgets('pre-purchase can send family context when family space exists',
      (tester) async {
    final aiService = _FakeAIService(
      response: const AIResponse(
        impulse: 'Family treat?',
        reason: 'Check the household plan.',
        neutral: 'This is family advice.',
      ),
    );

    await _pumpPrePurchaseRouterApp(
      tester,
      aiService: aiService,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Contributor',
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Family'));
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
      'Dinner delivery',
    );
    await tester.enterText(find.byType(TextField).at(1), '1200');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Dining'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dining'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ask Conscia'));
    await tester.tap(find.text('Ask Conscia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(aiService.receivedContextScope, 'family');
    expect(find.text('Family advice'), findsOneWidget);
  });

  testWidgets(
      'pre-purchase response summary formats the selected currency consistently',
      (tester) async {
    final aiService = _FakeAIService(
      response: const AIResponse(
        impulse: 'Treat yourself.',
        reason: 'Check your budget.',
        neutral: 'You can decide.',
        budget: AIBudgetContext(
          monthlyLimit: 16706.49,
          currentSpend: 0,
          percentUsed: 0,
          isOverBudget: false,
        ),
      ),
    );

    await _pumpPrePurchaseRouterApp(
      tester,
      aiService: aiService,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Starbucks'],
          likelyCategories: ['Dining'],
        ),
      ),
      currencyCode: 'PHP',
      locale: 'en_PH',
      locationSuggestionsEnabled: true,
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
      'Starbucks coffee',
    );
    await tester.enterText(find.byType(TextField).at(1), '600');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Dining'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dining'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ask Conscia'));
    await tester.tap(find.text('Ask Conscia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final spentFormatted = CurrencyFormatter.format(
      0,
      currencyCode: 'PHP',
      locale: 'en_PH',
    );
    final limitFormatted = CurrencyFormatter.format(
      16706.49,
      currencyCode: 'PHP',
      locale: 'en_PH',
    );

    expect(find.textContaining('\$600 PHP'), findsNothing);
    expect(aiService.receivedCurrencyCode, 'PHP');
    expect(find.textContaining('\$0.00 / \$16706.49'), findsNothing);
    expect(find.text(spentFormatted), findsOneWidget);
    expect(find.text(' / $limitFormatted'), findsOneWidget);
  });

  testWidgets(
      'bought it anyway opens add expense form with prefilled confirmation values',
      (tester) async {
    await _pumpPrePurchaseRouterApp(
      tester,
      aiService: _FakeAIService(
        response: const AIResponse(
          impulse: 'Treat yourself.',
          reason: 'Check your budget.',
          neutral: 'You can decide.',
        ),
      ),
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Starbucks'],
          likelyCategories: ['Dining'],
        ),
      ),
      currencyCode: 'PHP',
      locale: 'en_PH',
      locationSuggestionsEnabled: true,
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'What are you thinking of buying?',
      ),
      'Starbucks coffee',
    );
    await tester.enterText(find.byType(TextField).at(1), '600');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Dining'));
    await tester.tap(find.widgetWithText(FilterChip, 'Dining'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ask Conscia'));
    await tester.tap(find.text('Ask Conscia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final buyButton = find.textContaining('Buy it');
    expect(buyButton, findsOneWidget);

    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);

    final amountField = tester.widget<TextField>(find.byType(TextField).first);
    expect(amountField.controller?.text, '600');

    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.text('Dining'),
      ),
      findsOneWidget,
    );

    final merchantField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Merchant (optional)',
      ),
    );
    expect(merchantField.controller?.text, 'Starbucks');
  });
}
