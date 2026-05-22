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
  _TestAuthNotifier()
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
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

  @override
  Future<Duration> confirmationResendCooldownRemaining([String? email]) async {
    return const Duration(minutes: 1);
  }
}

void main() {
  testWidgets('mock auth verification explains any local code works', (
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

    expect(
      find.text('Local dev: no email was sent. Enter any code to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('resend code is disabled for one minute when screen opens', (
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

    await tester.pump();
    await tester.pump();

    final resendCooldownButton = find.textContaining('Resend in');
    expect(resendCooldownButton, findsOneWidget);

    await tester.tap(resendCooldownButton);
    await tester.pump();

    expect(authNotifier.resendCount, 0);

    await tester.pump(const Duration(seconds: 60));

    expect(find.text('Resend code'), findsOneWidget);

    await tester.tap(find.text('Resend code'));
    await tester.pump();

    expect(authNotifier.resendCount, 1);
    expect(find.textContaining('Resend in'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Back to sign in'));
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

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(authNotifier.state.status, AuthStatus.unauthenticated);
    expect(find.text('Sign in screen'), findsOneWidget);
  });
}
