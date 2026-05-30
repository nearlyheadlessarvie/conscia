import 'dart:async';

import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/onboarding/sign_in_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  const _FakeSecureStorage();

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

  @override
  Future<void> write({
    required String key,
    String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {}

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {}
}

class _FakeManagedLoginService extends CognitoManagedLoginService {
  _FakeManagedLoginService()
      : super(
          dio: Dio(),
          openAuthSession: (uri, {required appCallbackUri}) async => Uri.parse(
            'conscia://auth/callback'
            '?code=test-code'
            '&state=test-state',
          ),
          clientId: 'managed-client-id',
          loginDomain: Uri.parse('https://login.getconscia.com'),
          redirectUri: Uri.parse('conscia://auth/callback'),
          appRedirectUri: Uri.parse('conscia://auth/callback'),
          logoutUri: Uri.parse('conscia://auth/logout'),
        );
}

class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier()
      : super(
          _FakeAuthService(),
          const _FakeSecureStorage(),
          autoRestoreSession: false,
          useManagedLogin: true,
          managedLoginService: _FakeManagedLoginService(),
        );

  String? lastEmailHint;
  String? lastLoginEmail;
  String? lastLoginPassword;
  int googleCount = 0;
  Object? googleError;
  Object? appleError;
  Completer<void>? loginCompleter;
  Completer<void>? googleCompleter;
  AuthTokens? completedExternalTokens;
  String? completedExternalEmail;

  @override
  Future<void> login(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    await loginCompleter?.future;
    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      userId: 'user-id',
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    final error = googleError;
    if (error != null) {
      throw error;
    }
    googleCount += 1;
    await googleCompleter?.future;
    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      userId: 'user-id',
    );
  }

  @override
  Future<void> signInWithApple() async {
    final error = appleError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> completeExternalSignIn(
    AuthTokens tokens, {
    String? email,
  }) async {
    completedExternalTokens = tokens;
    completedExternalEmail = email;
    state = state.copyWith(
      status: AuthStatus.authenticated,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.userId,
    );
  }
}

class _RecordingPasskeyService extends PasskeyService {
  _RecordingPasskeyService()
      : super(
          publicDio: Dio(),
          authenticatedDio: Dio(),
        );

  String? lastSignInEmail;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<AuthTokens> signIn(String email) async {
    lastSignInEmail = email;
    return const AuthTokens(
      accessToken: 'passkey-access-token',
      refreshToken: 'passkey-refresh-token',
      userId: 'passkey-user-id',
    );
  }
}

Future<void> _pumpSignInScreen(
  WidgetTester tester, {
  required AuthNotifier authNotifier,
  Widget child = const MaterialApp(home: SignInScreen()),
  bool passkeysAvailable = false,
  PasskeyService? passkeyService,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authProvider.overrideWith((ref) => authNotifier),
        passkeyAvailabilityProvider.overrideWith(
          (ref) async => passkeysAvailable,
        ),
        if (passkeyService != null)
          passkeyServiceProvider.overrideWithValue(passkeyService),
      ],
      child: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign in screen shows email and password fields', (tester) async {
    await _pumpSignInScreen(
      tester,
      authNotifier: _RecordingAuthNotifier(),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
  });

  testWidgets('sign in submits typed email and password', (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SecurePass123');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign In'),
    );
    await tester.pump();

    expect(authNotifier.lastLoginEmail, 'story-demo@example.com');
    expect(authNotifier.lastLoginPassword, 'SecurePass123');
  });

  testWidgets('email sign in shows the page loading overlay', (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..loginCompleter = Completer<void>();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SecurePass123');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign In'),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    authNotifier.loginCompleter!.complete();
    await tester.pump();
  });

  testWidgets('email sign in keeps the loading overlay after auth succeeds',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..loginCompleter = Completer<void>();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SecurePass123');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign In'),
    );
    await tester.pump();

    authNotifier.loginCompleter!.complete();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );
  });

  testWidgets('google button still routes through auth notifier',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    expect(authNotifier.googleCount, 1);
  });

  testWidgets('google sign in shows the page loading overlay', (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..googleCompleter = Completer<void>();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    expect(authNotifier.googleCount, 1);
    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );

    authNotifier.googleCompleter!.complete();
    await tester.pump();
  });

  testWidgets('google sign in keeps the loading overlay after auth succeeds',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..googleCompleter = Completer<void>();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    authNotifier.googleCompleter!.complete();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );
  });

  testWidgets('google sign in dismisses the focused keyboard', (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    expect(authNotifier.googleCount, 1);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('forgot password opens password reset route', (tester) async {
    final authNotifier = _RecordingAuthNotifier();
    final router = GoRouter(
      initialLocation: AppRoutes.signIn,
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: AppRoutes.passwordReset,
          builder: (context, state) => const Scaffold(
            body: Text('Password reset screen'),
          ),
        ),
      ],
    );

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      child: MaterialApp.router(routerConfig: router),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Password reset screen'), findsOneWidget);
  });

  testWidgets('social cancellation does not render an inline notice',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..googleError = const CognitoManagedLoginCancelledException();
    AppError.configure(
      referenceIdFactory: () => 'LOGINML1',
      logger: (_) {},
    );

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
    );

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Conscia sign-in was cancelled.'), findsNothing);
    expect(find.text('Dismiss'), findsNothing);
  });

  testWidgets('passkey-first sign in uses the saved single account',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    expect(find.text('Sign in with passkey'), findsOneWidget);
    expect(find.text('story-demo@example.com'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Continue with Passkey'));
    await tester.pump();

    expect(passkeyService.lastSignInEmail, 'story-demo@example.com');
    expect(authNotifier.completedExternalEmail, 'story-demo@example.com');
  });

  testWidgets('passkey sign in keeps the loading overlay after auth succeeds',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    await tester.tap(find.text('Continue with Passkey'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );
  });

  testWidgets('passkey-first sign in prompts for multiple saved accounts',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      passkeyRegisteredEmailsPreferenceKey: [
        'one@example.com',
        'two@example.com',
      ],
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    expect(find.text('Choose an account'), findsOneWidget);
    expect(find.text('one@example.com'), findsOneWidget);
    expect(find.text('two@example.com'), findsOneWidget);

    await tester.tap(find.text('two@example.com'));
    await tester.pump();

    expect(passkeyService.lastSignInEmail, 'two@example.com');
    expect(authNotifier.completedExternalEmail, 'two@example.com');
  });
}
