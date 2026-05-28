import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/sign_up_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _FakeManagedLoginService extends CognitoManagedLoginService {
  _FakeManagedLoginService()
      : super(
          dio: Dio(),
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => true,
          openAuthSession: (uri, {required appCallbackUri}) async =>
              Uri.parse(
                'conscia://auth/callback'
                '?code=test-code'
                '&state=test-state',
              ),
          clientId: 'managed-client-id',
          loginDomain: Uri.parse('https://login.getconscia.com'),
          redirectUri: Uri.parse('https://auth.getconscia.com/open/auth/callback'),
          appRedirectUri: Uri.parse('conscia://auth/callback'),
          logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
        );
}

class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier()
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
          useManagedLogin: true,
          managedLoginService: _FakeManagedLoginService(),
        );

  String? lastEmailHint;
  Object? signUpError;

  @override
  Future<void> signUpWithManagedLogin({String? emailHint}) async {
    final error = signUpError;
    if (error != null) {
      throw error;
    }

    lastEmailHint = emailHint;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign up screen keeps email-first managed login entry only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _RecordingAuthNotifier()),
        ],
        child: const MaterialApp(
          home: SignUpScreen(),
        ),
      ),
    );

    expect(find.text('Sign up with Google'), findsNothing);
    expect(find.text('Sign up with Apple'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Create Account'), findsOneWidget);
    expect(
      find.text(
        'We will create your account securely in your browser, where email, social sign-in, and passkeys stay on the same Cognito session.',
      ),
      findsNothing,
    );
  });

  testWidgets('create account launches managed signup with email hint', (
    tester,
  ) async {
    final authNotifier = _RecordingAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: SignUpScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'story-demo@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();

    expect(authNotifier.lastEmailHint, 'story-demo@example.com');
  });

  testWidgets('sign up shows friendly managed login errors', (
    tester,
  ) async {
    final authNotifier = _RecordingAuthNotifier()
      ..signUpError = const CognitoManagedLoginException(
        'Managed signup is temporarily unavailable.',
      );
    AppError.configure(
      referenceIdFactory: () => 'SIGNUPML',
      logger: (_) {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(
          home: SignUpScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'story-demo@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Managed signup is temporarily unavailable.'), findsOneWidget);
    expect(find.textContaining('Reference: SIGNUPML'), findsNothing);
  });
}
