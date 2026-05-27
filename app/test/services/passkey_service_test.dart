import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppError.resetForTests);

  test('friendlyPasskeyErrorMessage preserves API/server failures', () {
    AppError.configure(
      referenceIdFactory: () => 'PASS1234',
      logger: (_) {},
    );

    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/passkeys/login/complete'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/auth/passkeys/login/complete'),
        statusCode: 500,
        data: {'error': 'Unexpected failure'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      friendlyPasskeyErrorMessage(error),
      'Conscia is having trouble right now. Please try again. Reference: PASS1234',
    );
  });

  test('friendlyPasskeyErrorMessage maps domain association platform errors', () {
    expect(
      friendlyPasskeyErrorMessage(
        PlatformException(
          code: 'domain-not-associated',
          message: 'webcredentials association missing',
        ),
      ),
      'Passkeys are not fully configured for this app yet.',
    );
  });
}
