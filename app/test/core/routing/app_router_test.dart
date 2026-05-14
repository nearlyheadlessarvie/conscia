import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/providers/insights_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return null;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }

  void setAuthState(AuthState nextState) {
    state = nextState;
  }
}

class _FakeLocationAssistanceService extends LocationAssistanceService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) getTransactionSuggestions() =>
      const (nearbyMerchants: <String>[], likelyCategories: <String>[]);
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [];
}

class _StaticTransactionService extends TransactionService {
  _StaticTransactionService() : super(Dio());

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
  }) async {
    return const PaginatedTransactions(
      items: [],
      totalCount: 0,
      page: 1,
      pageSize: 20,
      hasMore: false,
    );
  }
}

class _StaticConscienceJourneyService extends ConscienceJourneyService {
  _StaticConscienceJourneyService() : super(Dio());

  @override
  Future<ConscienceJourneySummary> fetchJourney() async =>
      const ConscienceJourneySummary(
        xpTotal: 0,
        currentLevel: ConscienceLevel(
          key: 'awakening',
          title: 'Awakening',
          requiredXp: 0,
        ),
        nextLevel: ConscienceLevel(
          key: 'impulse_spotter',
          title: 'Impulse Spotter',
          requiredXp: 120,
        ),
        xpIntoLevel: 0,
        xpToNextLevel: 120,
        momentumDays: 0,
        bestMomentumDays: 0,
        weeklyQuests: [],
        badges: [],
      );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
    });
  });

  test('app router is stable across unauthenticated auth state changes', () {
    final fakeAuthNotifier = _TestAuthNotifier(const AuthState());
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => fakeAuthNotifier),
      ],
    );
    addTearDown(container.dispose);

    final routerBefore = container.read(appRouterProvider);

    fakeAuthNotifier.setAuthState(
      const AuthState(
        isLoading: true,
      ),
    );

    final routerAfter = container.read(appRouterProvider);

    expect(identical(routerBefore, routerAfter), isTrue);
  });

  testWidgets(
    'onboarding profile route accepts generic map extras',
    (tester) async {
      final fakeAuthNotifier = _TestAuthNotifier(
        const AuthState(
          status: AuthStatus.authenticated,
          userId: 'user-1',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => fakeAuthNotifier),
            subscriptionProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                tier: 'free',
                isPremium: false,
              ),
            ),
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
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      final router = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routerConfig! as dynamic;
      router.go(
        AppRoutes.spendingProfile,
        extra: <String, dynamic>{
          'currencyCode': 'EUR',
          'locale': 'en_IE',
        },
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('How do you spend?'), findsOneWidget);
      expect(find.text('Under EUR 20,000'), findsOneWidget);
    },
  );

  testWidgets(
    'add transaction route accepts generic map extras for expense prefill',
    (tester) async {
      final fakeAuthNotifier = _TestAuthNotifier(
        const AuthState(
          status: AuthStatus.authenticated,
          userId: 'user-1',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => fakeAuthNotifier),
            currentUserProvider.overrideWith(
              (ref) async => UserProfile(
                id: 'user-1',
                email: 'user@example.com',
                currencyCode: 'USD',
                locale: 'en_US',
                createdAt: DateTime(2026),
                hasCompletedOnboarding: true,
              ),
            ),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            categoryFrequencyProvider.overrideWithValue(
              ['Coffee', 'Dining', 'Shopping'],
            ),
            locationAssistanceServiceProvider.overrideWithValue(
              _FakeLocationAssistanceService(),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      final router = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routerConfig! as dynamic;
      router.go(
        AppRoutes.addTransaction,
        extra: <String, dynamic>{
          'amount': '600',
          'currencyCode': 'PHP',
          'category': 'Dining',
          'counterparty': 'Starbucks',
        },
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);

      final amountField =
          tester.widget<TextField>(find.byType(TextField).first);
      expect(amountField.controller?.text, '600');

      final merchantField = tester.widget<FloatingLabelTextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is FloatingLabelTextField &&
              widget.label == 'Merchant (optional)',
        ),
      );
      expect(merchantField.controller.text, 'Starbucks');
    },
  );

  testWidgets('session expired auth state routes to a session expired screen', (
    tester,
  ) async {
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.sessionExpired,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuthNotifier),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Session expired'), findsOneWidget);
    expect(find.text('Sign in again'), findsOneWidget);
  });

  testWidgets('pending confirmation auth state routes to verify email screen', (
    tester,
  ) async {
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.pendingConfirmation,
        pendingEmail: 'new@example.com',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuthNotifier),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('We sent a confirmation code to new@example.com.'),
        findsOneWidget);
  });

  testWidgets('authenticated shell routes keep visible content in the viewport',
      (tester) async {
    final fakeAuthNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuthNotifier),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'user@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'free',
              isPremium: false,
            ),
          ),
          budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
          transactionServiceProvider
              .overrideWithValue(_StaticTransactionService()),
          conscienceJourneyServiceProvider
              .overrideWithValue(_StaticConscienceJourneyService()),
          behavioralInsightsProvider.overrideWith((ref) async => null),
          insightsSummaryProvider.overrideWith((ref) async => null),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          alertsProvider.overrideWith((ref) async => const []),
          categoryFrequencyProvider.overrideWithValue(
            const ['Coffee', 'Dining', 'Shopping'],
          ),
          locationAssistanceServiceProvider.overrideWithValue(
            _FakeLocationAssistanceService(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('dashboard-editorial-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-sticky-identity-header')),
        findsOneWidget);
    expect(find.byTooltip('Notifications').hitTestable(), findsWidgets);

    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig! as dynamic;

    router.go(AppRoutes.transactions);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Transactions').hitTestable(), findsOneWidget);
    expect(find.text('All').hitTestable(), findsOneWidget);

    router.go(AppRoutes.settings);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Settings').hitTestable(), findsOneWidget);
  });
}
