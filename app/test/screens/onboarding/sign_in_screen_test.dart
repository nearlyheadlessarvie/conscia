import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/screens/onboarding/sign_in_screen.dart';
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
  Future<AuthTokens> login(String email, String password) {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        statusCode: 401,
        data: {'error': 'Invalid email or password'},
      ),
      type: DioExceptionType.badResponse,
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

  test('password sign-in maps 401 to invalid username or password', () {
    AppError.configure(
      referenceIdFactory: () => 'LOGIN401',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        statusCode: 401,
        data: {'error': 'Invalid email or password'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      friendlySignInErrorMessage(error, isPasswordSignIn: true),
      'Invalid username or password.',
    );
  });

  test('non-password sign-in keeps API message mapping', () {
    AppError.configure(
      referenceIdFactory: () => 'LOGIN500',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/google'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/google'),
        statusCode: 500,
        data: {'message': 'Provider unavailable'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      friendlySignInErrorMessage(error),
      'Conscia is having trouble right now. Please try again. Reference: LOGIN500',
    );
  });

  test('reuses auth provider reference ids when available', () {
    AppError.configure(
      referenceIdFactory: () => 'ORIGINAL',
      logger: (_) {},
    );

    final appError = AppError.from(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          statusCode: 401,
          data: {'error': 'Invalid email or password'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      friendlySignInErrorMessage(appError, isPasswordSignIn: true),
      'Invalid username or password.',
    );
  });

  testWidgets(
    'sign in screen shows inline auth error note instead of dismissible banner',
    (tester) async {
      final authNotifier = AuthNotifier(
        _FailingAuthService(),
        _FakeSecureStorage(),
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

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'nearlyheadlessarvie@live.com.ph');
      await tester.enterText(fields.at(1), 'Secure123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dismiss'), findsNothing);
      expect(find.text('Invalid username or password.'), findsOneWidget);
    },
  );
}
