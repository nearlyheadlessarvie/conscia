import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/services/cognito_managed_login_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppError.resetForTests);

  test('maps Dio response to friendly message with reference id', () {
    final logged = <AppError>[];
    AppError.configure(
      referenceIdFactory: () => 'REF12345',
      logger: logged.add,
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/transactions'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/transactions'),
        statusCode: 500,
        data: {'error': 'Database stack trace'},
      ),
      type: DioExceptionType.badResponse,
    );

    final appError = AppError.from(error);

    expect(
      appError.userMessage,
      'Conscia is having trouble right now. Please try again. Reference: REF12345',
    );
    expect(logged.single.originalError, same(error));
    expect(logged.single.referenceId, 'REF12345');
  });

  test('prefers backend correlation id over local fallback reference id', () {
    final logged = <AppError>[];
    AppError.configure(
      referenceIdFactory: () => 'LOCAL123',
      logger: logged.add,
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/google'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/auth/google'),
        statusCode: 500,
        data: {
          'error': 'Google sign-in could not be verified',
          'correlationId': 'api-correlation-123',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final appError = AppError.from(error);

    expect(
      appError.userMessage,
      'Conscia is having trouble right now. Please try again. Reference: api-correlation-123',
    );
    expect(logged.single.referenceId, 'api-correlation-123');
  });

  test('uses local fallback reference id when backend correlation id is absent', () {
    AppError.configure(
      referenceIdFactory: () => 'LOCAL123',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/transactions'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/transactions'),
        statusCode: 500,
        data: {'error': 'An unexpected error occurred'},
      ),
      type: DioExceptionType.badResponse,
    );

    final appError = AppError.from(error);

    expect(
      appError.userMessage,
      'Conscia is having trouble right now. Please try again. Reference: LOCAL123',
    );
  });

  test('keeps safe API validation messages without reference id', () {
    AppError.configure(
      referenceIdFactory: () => 'VAL12345',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/register'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/auth/register'),
        statusCode: 400,
        data: {'error': 'Account already exists. Please sign in.'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      AppError.from(error).userMessage,
      'Account already exists. Please sign in.',
    );
  });

  test('reuses existing app errors without logging them again', () {
    final logged = <AppError>[];
    AppError.configure(
      referenceIdFactory: () => 'ONCE1234',
      logger: logged.add,
    );

    final original = AppError.from(Exception('network failed'));
    final reused = AppError.from(original);

    expect(reused, same(original));
    expect(logged, hasLength(1));
  });

  test('shows managed login cancellation without reference id', () {
    AppError.configure(
      referenceIdFactory: () => 'LOGIN123',
      logger: (_) {},
    );

    expect(
      AppError.from(const CognitoManagedLoginCancelledException()).userMessage,
      'Conscia sign-in was cancelled.',
    );
  });

  test('shows managed login errors without reference id', () {
    AppError.configure(
      referenceIdFactory: () => 'LOGIN456',
      logger: (_) {},
    );

    expect(
      AppError.from(
        const CognitoManagedLoginException('Browser login failed.'),
      ).userMessage,
      'Browser login failed.',
    );
  });
}
