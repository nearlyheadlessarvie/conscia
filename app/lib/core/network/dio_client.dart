import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/auth_provider.dart';
import '../constants/api_constants.dart';

const _tokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _userIdKey = 'user_id';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      contentType: Headers.jsonContentType,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await storage.delete(key: _tokenKey);
          await storage.delete(key: _refreshTokenKey);
          await storage.delete(key: _userIdKey);
          ref.read(authProvider.notifier).logout();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
