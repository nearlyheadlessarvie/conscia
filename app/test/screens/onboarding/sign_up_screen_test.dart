import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/screens/onboarding/sign_up_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingAuthService extends AuthService {
  _FailingAuthService() : super(Dio());

  @override
  Future<AuthRegistrationResult> register(String email, String password) {
    throw DioException(
      requestOptions: RequestOptions(path: 'auth/register'),
      response: Response(
        requestOptions: RequestOptions(path: 'auth/register'),
        statusCode: 400,
        data: {'error': 'Account already exists. Please sign in.'},
      ),
    );
  }
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppError.resetForTests);

  testWidgets('sign up screen does not show social auth buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignUpScreen(),
        ),
      ),
    );

    expect(find.text('Sign up with Google'), findsNothing);
    expect(find.text('Sign up with Apple'), findsNothing);
    expect(find.text('Create Account'), findsNWidgets(2));
  });

  testWidgets('sign up shows friendly API errors instead of DioException text',
      (
    tester,
  ) async {
    final authNotifier = AuthNotifier(
      _FailingAuthService(),
      _FakeSecureStorage(),
    );
    AppError.configure(
      referenceIdFactory: () => 'SIGNUP01',
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'nearlyheadlessarvie@live.com.ph',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Secure123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'Secure123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Account already exists. Please sign in. Reference: SIGNUP01'),
      findsOneWidget,
    );
    expect(find.textContaining('DioException'), findsNothing);
  });
}
