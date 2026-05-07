import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

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
    return null;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }

  void setAuthState(AuthState nextState) {
    state = nextState;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
    });
  });

  test('app router is stable across unauthenticated auth state changes', () {
    final fakeAuthNotifier = _TestAuthNotifier(const AuthState());
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => fakeAuthNotifier),
      ],
    );
    addTearDown(container.dispose);

    final routerBefore = container.read(appRouterProvider);

    fakeAuthNotifier.setAuthState(
      const AuthState(
        isLoading: true,
      ),
    );

    final routerAfter = container.read(appRouterProvider);

    expect(identical(routerBefore, routerAfter), isTrue);
  });
}
