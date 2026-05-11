import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/verify_email_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
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
  _TestAuthNotifier() : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = const AuthState(
      status: AuthStatus.pendingConfirmation,
      pendingEmail: 'nearlyheadlessarvie@live.com.ph',
    );
  }

  int resendCount = 0;

  @override
  Future<void> resendConfirmation() async {
    resendCount += 1;
  }
}

void main() {
  testWidgets('resend code is disabled for one minute after sending', (
    tester,
  ) async {
    final authNotifier = _TestAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: VerifyEmailScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Resend code'));
    await tester.pump();

    expect(authNotifier.resendCount, 1);
    expect(find.text('Resend in 60s'), findsOneWidget);

    await tester.tap(find.text('Resend in 60s'));
    await tester.pump();

    expect(authNotifier.resendCount, 1);

    await tester.pump(const Duration(seconds: 60));

    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('back to sign in clears pending confirmation before routing', (
    tester,
  ) async {
    final authNotifier = _TestAuthNotifier();
    final router = GoRouter(
      initialLocation: AppRoutes.verifyEmail,
      redirect: (context, state) {
        if (authNotifier.state.status == AuthStatus.pendingConfirmation &&
            state.uri.path != AppRoutes.verifyEmail) {
          return AppRoutes.verifyEmail;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (context, state) => const Scaffold(
            body: Text('Sign in screen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();

    expect(authNotifier.state.status, AuthStatus.unauthenticated);
    expect(find.text('Sign in screen'), findsOneWidget);
  });

  testWidgets('app bar back clears pending confirmation before routing', (
    tester,
  ) async {
    final authNotifier = _TestAuthNotifier();
    final router = GoRouter(
      initialLocation: AppRoutes.verifyEmail,
      redirect: (context, state) {
        if (authNotifier.state.status == AuthStatus.pendingConfirmation &&
            state.uri.path != AppRoutes.verifyEmail) {
          return AppRoutes.verifyEmail;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (context, state) => const Scaffold(
            body: Text('Sign in screen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(authNotifier.state.status, AuthStatus.unauthenticated);
    expect(find.text('Sign in screen'), findsOneWidget);
  });
}
