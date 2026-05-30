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
          _FakeSecureStorage(),
          autoRestoreSession: false,
          useManagedLogin: true,
          managedLoginService: _FakeManagedLoginService(),
        );

  String? lastEmailHint;
  String? lastRegisteredEmail;
  String? lastRegisteredPassword;
  Object? signUpError;

  @override
  Future<void> register(String email, String password) async {
    final error = signUpError;
    if (error != null) {
      throw error;
    }

    lastRegisteredEmail = email;
    lastRegisteredPassword = password;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign up screen shows email, password, and confirm fields', (
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
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('create account registers with email and password', (
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SecurePass123');
    await tester.enterText(fields.at(2), 'SecurePass123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();

    expect(authNotifier.lastRegisteredEmail, 'story-demo@example.com');
    expect(authNotifier.lastRegisteredPassword, 'SecurePass123');
  });

  testWidgets('create account rejects passwords outside Cognito policy', (
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SECUREPASS123');
    await tester.enterText(fields.at(2), 'SECUREPASS123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();

    expect(find.textContaining('Include 1 lowercase letter'), findsOneWidget);
    expect(authNotifier.lastRegisteredEmail, isNull);
  });

  testWidgets('sign up shows friendly registration errors', (
    tester,
  ) async {
    final authNotifier = _RecordingAuthNotifier()
      ..signUpError = Exception('Registration unavailable');
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'story-demo@example.com');
    await tester.enterText(fields.at(1), 'SecurePass123');
    await tester.enterText(fields.at(2), 'SecurePass123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Something went wrong. Please try again. Reference: SIGNUPML'),
      findsOneWidget,
    );
  });
}
