import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../constants/api_constants.dart';

const _tokenKey = 'access_token';
const _idTokenKey = 'id_token';
const _apiVersion = '1';
const useAccessTokenRequestExtraKey = 'useAccessToken';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

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

  final storage = ref.watch(secureStorageProvider);
  Future<bool>? refreshInFlight;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_isHealthRequest(options)) {
          options.queryParameters = <String, dynamic>{
            ...options.queryParameters,
            'v': options.queryParameters['v'] ?? _apiVersion,
          };
          options.headers['X-Conscia-App-Version'] =
              await ref.read(appVersionProvider.future);
        }

        if (_isPublicRequest(options)) {
          return handler.next(options);
        }

        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          final useAccessToken = requestUsesAccessToken(options);
          final token = useAccessToken
              ? authState.accessToken ?? await storage.read(key: _tokenKey)
              : authState.idToken ??
                  await storage.read(key: _idTokenKey) ??
                  authState.accessToken ??
                  await storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          }
        }

        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: const {'message': 'Session ended'},
            ),
            type: DioExceptionType.badResponse,
            error:
                'Cannot send authenticated request without an active session.',
          ),
        );
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

        if (isUnauthorized && alreadyRetried && !isRefreshRequest) {
          await ref.read(authProvider.notifier).markSessionExpired();
          return handler.next(error);
        }

        if (isUnauthorized && !alreadyRetried && !isRefreshRequest) {
          refreshInFlight ??= ref.read(authProvider.notifier).refreshSession();
          final refreshed = await refreshInFlight!;
          refreshInFlight = null;

          if (refreshed) {
            final nextToken = requestUsesAccessToken(request)
                ? await storage.read(key: _tokenKey)
                : await storage.read(key: _idTokenKey) ??
                    await storage.read(key: _tokenKey);
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

bool _isPublicRequest(RequestOptions options) {
  final path = options.uri.path;
  return path == '/health' || path.startsWith('/health/');
}

bool _isHealthRequest(RequestOptions options) => _isPublicRequest(options);

bool requestUsesAccessToken(RequestOptions options) =>
    options.extra[useAccessTokenRequestExtraKey] == true;
