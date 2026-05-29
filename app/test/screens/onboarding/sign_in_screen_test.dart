import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/sign_in_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => true,
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

  @override
  Future<void> login(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
  }

  @override
  Future<void> signInWithGoogle() async {
    final error = googleError;
    if (error != null) {
      throw error;
    }
    googleCount += 1;
  }

  @override
  Future<void> signInWithApple() async {
    final error = appleError;
    if (error != null) {
      throw error;
    }
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign in screen shows email and password fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _RecordingAuthNotifier()),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
  });

  testWidgets('sign in submits typed email and password', (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets('google button still routes through auth notifier',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    expect(authNotifier.googleCount, 1);
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final googleButton =
        find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Conscia sign-in was cancelled.'), findsNothing);
    expect(find.text('Dismiss'), findsNothing);
  });
}
