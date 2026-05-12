import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/screens/onboarding/sign_in_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
