import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._tokens) : super(Dio());

  final AuthTokens _tokens;
  String? lastRefreshToken;
  bool shouldFailRefresh = false;

  @override
  Future<AuthTokens> refreshSession(String refreshToken) async {
    lastRefreshToken = refreshToken;
    if (shouldFailRefresh) {
      throw DioException(
        requestOptions: RequestOptions(path: 'auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: 'auth/refresh'),
          statusCode: 401,
        ),
      );
    }
    return _tokens;
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage([Map<String, String>? initial])
      : _values = {...?initial};

  final Map<String, String> _values;

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
    return _values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    _values.remove(key);
  }
}

void main() {
  test('refreshSession updates tokens and keeps the session authenticated', () async {
    final service = _FakeAuthService(
      const AuthTokens(
        accessToken: 'new.access.token',
        refreshToken: 'new-refresh-token',
        userId: 'user-1',
      ),
    );
    final storage = _FakeSecureStorage({
      'access_token': 'old.access.token',
      'refresh_token': 'old-refresh-token',
      'user_id': 'user-1',
    });
    final notifier = AuthNotifier(service, storage);

    await notifier.loginWithStoredToken();
    final refreshed = await notifier.refreshSession();

    expect(refreshed, isTrue);
    expect(service.lastRefreshToken, 'old-refresh-token');
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.accessToken, 'new.access.token');
    expect(notifier.state.refreshToken, 'new-refresh-token');
    expect(await storage.read(key: 'access_token'), 'new.access.token');
    expect(await storage.read(key: 'refresh_token'), 'new-refresh-token');
  });

  test('markSessionExpired clears tokens and exposes sessionExpired state', () async {
    final notifier = AuthNotifier(
      _FakeAuthService(
        const AuthTokens(
          accessToken: 'new.access.token',
          refreshToken: 'new-refresh-token',
          userId: 'user-1',
        ),
      ),
      _FakeSecureStorage({
        'access_token': 'old.access.token',
        'refresh_token': 'old-refresh-token',
        'user_id': 'user-1',
      }),
    );

    await notifier.loginWithStoredToken();
    await notifier.markSessionExpired();

    expect(notifier.state.status, AuthStatus.sessionExpired);
    expect(notifier.state.accessToken, isNull);
    expect(notifier.state.refreshToken, isNull);
    expect(notifier.state.userId, isNull);
  });
}
