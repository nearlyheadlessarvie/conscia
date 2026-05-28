import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/sign_in_screen.dart';
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
          incomingLinks: const Stream<Uri>.empty(),
          readInitialLink: () async => null,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => true,
          clientId: 'managed-client-id',
          loginDomain: Uri.parse('https://login.getconscia.com'),
          redirectUri: Uri.parse('https://auth.getconscia.com/open/auth/callback'),
          logoutUri: Uri.parse('https://auth.getconscia.com/open/auth/logout'),
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
  int googleCount = 0;
  Object? continueError;

  @override
  Future<void> continueWithManagedLogin({String? emailHint}) async {
    final error = continueError;
    if (error != null) {
      throw error;
    }

    lastEmailHint = emailHint;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCount += 1;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign in screen removes the local password field', (tester) async {
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

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Continue with Email or Passkey'), findsOneWidget);
  });

  testWidgets('continue button launches managed login with typed email hint',
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

    await tester.enterText(find.byType(TextField), 'story-demo@example.com');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Continue with Email or Passkey'),
    );
    await tester.pump();

    expect(authNotifier.lastEmailHint, 'story-demo@example.com');
  });

  testWidgets('google button still routes through auth notifier', (tester) async {
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign in with Google'));
    await tester.pump();

    expect(authNotifier.googleCount, 1);
  });

  testWidgets('managed login launch failures render as inline notices',
      (tester) async {
    final authNotifier = _RecordingAuthNotifier()
      ..continueError = const CognitoManagedLoginException(
        'Conscia sign-in could not finish right now.',
      );
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

    await tester.tap(
      find.widgetWithText(FilledButton, 'Continue with Email or Passkey'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Conscia sign-in could not finish right now.'), findsOneWidget);
    expect(find.text('Dismiss'), findsNothing);
  });
}
