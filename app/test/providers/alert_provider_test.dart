import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

void main() {
  test('active alerts keeps recurring generated reminders visible', () async {
    final container = ProviderContainer(
      overrides: [
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
