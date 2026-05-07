import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
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

      await tester.pumpAndSettle();

      expect(find.text('How do you spend?'), findsOneWidget);
      expect(find.text('Under EUR 20,000'), findsOneWidget);
    },
  );
}
