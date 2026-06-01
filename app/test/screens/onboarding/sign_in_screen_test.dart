import 'dart:async';

import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/sign_in_preference_provider.dart';
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
import 'package:passkeys/exceptions.dart';
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
  bool? lastPreferImmediatelyAvailableCredentials;
  Object? signInError;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<AuthTokens> signIn(
    String email, {
    bool preferImmediatelyAvailableCredentials = true,
  }) async {
    final error = signInError;
    if (error != null) {
      throw error;
    }
    lastSignInEmail = email;
    lastPreferImmediatelyAvailableCredentials =
        preferImmediatelyAvailableCredentials;
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

  testWidgets('initial passkey action signs in with typed email',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'story-demo@example.com',
    );
    expect(
      find.byKey(const ValueKey('email-passkey-sign-in-button')),
      findsNothing,
    );

    await tester.tap(find.text('Sign in with passkey'));
    await tester.pump();

    expect(passkeyService.lastSignInEmail, 'story-demo@example.com');
    expect(passkeyService.lastPreferImmediatelyAvailableCredentials, isFalse);
    expect(authNotifier.completedExternalEmail, 'story-demo@example.com');
  });

  testWidgets('initial passkey action validates email first', (tester) async {
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    expect(
      find.byKey(const ValueKey('email-passkey-sign-in-button')),
      findsNothing,
    );

    await tester.tap(find.text('Sign in with passkey'));
    await tester.pump();

    expect(passkeyService.lastSignInEmail, isNull);
    expect(
      find.textContaining('Enter your email to use a passkey'),
      findsOneWidget,
    );
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

  testWidgets('returning user with local passkey sees passkey priority',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
    });
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Story Demo'), findsOneWidget);
    expect(find.text('Not you?'), findsOneWidget);
    expect(find.text('story-demo@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-passkey-primary')), findsOneWidget);
    expect(find.text('Sign in with password'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Sign in with Apple'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-passkey-primary')));
    await tester.pump();

    expect(passkeyService.lastSignInEmail, 'story-demo@example.com');
    expect(passkeyService.lastPreferImmediatelyAvailableCredentials, isTrue);
    expect(authNotifier.completedExternalEmail, 'story-demo@example.com');
  });

  testWidgets('returning user password mode signs in with remembered email',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
    });
    final authNotifier = _RecordingAuthNotifier();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: _RecordingPasskeyService(),
    );

    await tester.tap(find.text('Sign in with password'));
    await tester.pumpAndSettle();

    expect(find.text('Story Demo'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    expect(find.text('Sign in with passkey'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'SecurePass123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();

    expect(authNotifier.lastLoginEmail, 'story-demo@example.com');
    expect(authNotifier.lastLoginPassword, 'SecurePass123');
  });

  testWidgets('passkey sign in keeps the loading overlay after auth succeeds',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
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

    await tester.tap(find.byKey(const ValueKey('saved-passkey-primary')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('conscia-loading-overlay')),
      findsOneWidget,
    );
  });

  testWidgets('not you returns to initial sign in without clearing passkeys',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpSignInScreen(
      tester,
      authNotifier: _RecordingAuthNotifier(),
      passkeysAvailable: true,
      passkeyService: _RecordingPasskeyService(),
    );

    await tester.tap(find.text('Not you?'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(prefs.getBool(showInitialSignInPreferenceKey), isTrue);
    expect(
      prefs.getString(rememberedSignInEmailPreferenceKey),
      'story-demo@example.com',
    );
    expect(
      prefs.getStringList(passkeyRegisteredEmailsPreferenceKey),
      ['story-demo@example.com'],
    );
  });

  testWidgets('initial sign in stays visible when not you flag is set',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      showInitialSignInPreferenceKey: true,
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
    });

    await _pumpSignInScreen(
      tester,
      authNotifier: _RecordingAuthNotifier(),
      passkeysAvailable: true,
      passkeyService: _RecordingPasskeyService(),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Not you?'), findsNothing);
    expect(find.byKey(const ValueKey('saved-passkey-primary')), findsNothing);
  });

  testWidgets('returning passkey sign in forgets stale local credentials',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final authNotifier = _RecordingAuthNotifier();
    final passkeyService = _RecordingPasskeyService()
      ..signInError = NoCredentialsAvailableException();

    await _pumpSignInScreen(
      tester,
      authNotifier: authNotifier,
      passkeysAvailable: true,
      passkeyService: passkeyService,
    );

    await tester.tap(find.byKey(const ValueKey('saved-passkey-primary')));
    await tester.pump();

    expect(prefs.getStringList(passkeyRegisteredEmailsPreferenceKey), isEmpty);
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isFalse);
    expect(
      find.text(
          "Couldn't sign in with that passkey. Try again or sign in with email."),
      findsOneWidget,
    );
  });
}
