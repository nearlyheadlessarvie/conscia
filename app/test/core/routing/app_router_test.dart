import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
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
  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions() =>
      const (nearbyMerchants: <String>[], likelyCategories: <String>[]);
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

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(InputChip),
          matching: find.text('Dining'),
        ),
        findsOneWidget,
      );

      final amountField = tester.widget<TextField>(find.byType(TextField).first);
      expect(amountField.controller?.text, '600');

      final merchantField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Merchant (optional)',
        ),
      );
      expect(merchantField.controller?.text, 'Starbucks');
    },
  );
}
