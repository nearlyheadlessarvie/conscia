import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../constants/api_constants.dart';

const _tokenKey = 'access_token';

final dioProvider = Provider<Dio>((ref) {
  ref.watch(authCacheScopeProvider);

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

  final storage = ref.watch(secureStorageProvider);
  Future<bool>? refreshInFlight;

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
        final request = error.requestOptions;
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = request.extra['authRetried'] == true;
        final isRefreshRequest =
            request.path.endsWith(ApiConstants.refreshToken);

        if (isUnauthorized && !ref.read(authProvider).isAuthenticated) {
          return handler.next(error);
        }

        if (isUnauthorized && !alreadyRetried && !isRefreshRequest) {
          refreshInFlight ??= ref.read(authProvider.notifier).refreshSession();
          final refreshed = await refreshInFlight!;
          refreshInFlight = null;

          if (refreshed) {
            final nextToken = await storage.read(key: _tokenKey);
            final retryHeaders = Map<String, dynamic>.from(request.headers);
            if (nextToken != null) {
              retryHeaders['Authorization'] = 'Bearer $nextToken';
            }

            final retryRequest = request.copyWith(
              headers: retryHeaders,
              extra: {
                ...request.extra,
                'authRetried': true,
              },
            );

            final response = await dio.fetch<dynamic>(retryRequest);
            return handler.resolve(response);
          }

          await ref.read(authProvider.notifier).markSessionExpired();
          return handler.next(error);
        }

        if (isUnauthorized && isRefreshRequest) {
          await ref.read(authProvider.notifier).markSessionExpired();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
