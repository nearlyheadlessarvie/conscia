import 'package:conscia_app/core/errors/app_error.dart';
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
}
