import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async =>
      null;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
    state = initialState;
  }

  void setAuthState(AuthState nextState) {
    state = nextState;
  }
}

class _UserScopedBehavioralInsightsService extends BehavioralInsightsService {
  _UserScopedBehavioralInsightsService() : super(Dio());

  final requestedUserIds = <String>[];
  String activeUserId = 'user-1';

  @override
  Future<BehavioralInsights?> getBehavioralInsights() async {
    requestedUserIds.add(activeUserId);
    return BehavioralInsights(
      mood: activeUserId == 'user-1'
          ? FinancialMood.confident
          : FinancialMood.cautious,
      worthItPercentage: activeUserId == 'user-1' ? 82 : 41,
      worthItCount: activeUserId == 'user-1' ? 8 : 4,
      previousMonthWorthItCount: 2,
      impulseeTrends: const [],
    );
  }
}

void main() {
  test('behavioralInsightsProvider refreshes when authenticated user changes',
      () async {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final service = _UserScopedBehavioralInsightsService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        behavioralInsightsServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final first = await container.read(behavioralInsightsProvider.future);
    expect(first?.worthItCount, 8);

    service.activeUserId = 'user-2';
    authNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );
    final second = await container.read(behavioralInsightsProvider.future);

    expect(second?.worthItCount, 4);
    expect(service.requestedUserIds, ['user-1', 'user-2']);
  });
}
