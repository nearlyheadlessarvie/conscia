import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
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

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

void main() {
  test('local alert state resets when the authenticated user changes', () {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(localAlertsProvider.notifier)
        .addBudgetNudge(category: 'Dining');
    container.read(dismissedAlertIdsProvider.notifier).dismiss('alert-1');

    expect(container.read(localAlertsProvider), hasLength(1));
    expect(container.read(dismissedAlertIdsProvider), contains('alert-1'));

    authNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );

    expect(container.read(localAlertsProvider), isEmpty);
    expect(container.read(dismissedAlertIdsProvider), isEmpty);
  });

  test('active alerts keeps recurring generated reminders visible', () async {
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'recurring-alert-1',
                type: 'recurring_transaction_created',
                title: 'Recurring transaction added',
                message: 'Netflix was added automatically.',
                priority: 30,
                actionRoute: '/transactions/tx-1',
                transactionId: 'tx-1',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 8),
              ),
            ]),
      ],
    );
    addTearDown(container.dispose);

    final alerts = await container.read(alertsProvider.future);
    expect(alerts, hasLength(1));
    expect(container.read(activeAlertsProvider).single.type,
        'recurring_transaction_created');
  });
}
