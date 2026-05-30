import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/request_options.dart';

final accountPasswordServiceProvider = Provider<AccountPasswordService>((ref) {
  return AccountPasswordService(ref.watch(dioProvider));
});

// Settings password changes require the signed-in user's Cognito access token.
class AccountPasswordService {
  AccountPasswordService(this._dio);

  final Dio _dio;

  Future<void> setPassword(String password, {String? currentPassword}) async {
    try {
      await _dio.post(
        ApiConstants.password,
        data: {
          'password': password,
          if (currentPassword != null) 'currentPassword': currentPassword,
        },
        options: Options(
          extra: const {useAccessTokenRequestExtraKey: true},
        ),
      );
    } on DioException {
      rethrow;
    }
  }
}
