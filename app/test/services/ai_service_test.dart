import 'package:conscia_app/core/constants/api_constants.dart';
import 'package:conscia_app/services/ai_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prePurchase uses the longer AI receive timeout', () async {
    final captured = <RequestOptions>[];
    final service = AIService(_capturingDio(captured));

    await service.prePurchase(
      description: 'Coffee',
      amount: 120,
      currencyCode: 'PHP',
      category: 'Dining',
    );

    expect(captured.single.path, ApiConstants.aiAdvice);
    expect(captured.single.receiveTimeout, ApiConstants.aiReceiveTimeout);
  });

  test('reflection uses the longer AI receive timeout', () async {
    final captured = <RequestOptions>[];
    final service = AIService(_capturingDio(captured));

    await service.reflection(transactionId: 'tx-1');

    expect(captured.single.path, ApiConstants.aiReflection);
    expect(captured.single.receiveTimeout, ApiConstants.aiReceiveTimeout);
  });
}

Dio _capturingDio(List<RequestOptions> captured) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'devilMessage': 'Impulse',
                'angelMessage': 'Reason',
                'neutralMessage': 'Neutral',
              },
            ),
          );
        },
      ),
    );
}
