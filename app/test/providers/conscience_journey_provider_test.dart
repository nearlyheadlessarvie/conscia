import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conscienceJourneyProvider loads and records events', () async {
    final service = _FakeConscienceJourneyService();
    final container = ProviderContainer(
      overrides: [
        _authenticatedAuthOverride(),
        conscienceJourneyServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(conscienceJourneyProvider.future);

    expect(initial.xpTotal, 100);

    final update = await container
        .read(conscienceJourneyProvider.notifier)
        .recordEvent(eventType: 'reflection_completed', sourceId: 'tx-1');

    expect(update.xpAwarded, 20);
    expect(container.read(conscienceJourneyProvider).value?.xpTotal, 120);
    expect(service.recordedSourceId, 'tx-1');
  });

  test('recordEvent adds gamification updates to the bell alerts', () async {
    final service = _FakeConscienceJourneyService();
    final container = ProviderContainer(
      overrides: [
        _authenticatedAuthOverride(),
        conscienceJourneyServiceProvider.overrideWithValue(service),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService()),
        alertsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(conscienceJourneyProvider.notifier)
        .recordEvent(eventType: 'reflection_completed', sourceId: 'tx-1');

    final alerts = container.read(activeAlertsProvider);

    expect(alerts.map((alert) => alert.type), contains('journey_level_up'));
    expect(alerts.map((alert) => alert.type), contains('journey_badge'));
    expect(alerts.map((alert) => alert.type), contains('journey_quest'));
    expect(alerts.first.actionRoute, '/journey');
  });

  test('conscienceJourneyProvider refreshes when authenticated user changes',
      () async {
    final service = _UserScopedConscienceJourneyService();
    final authNotifier = _TestAuthNotifier(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        conscienceJourneyServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final firstUserJourney =
        await container.read(conscienceJourneyProvider.future);

    authNotifier.setAuthState(
      const AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-2',
      ),
    );
    await container.pump();
    final secondUserJourney =
        await container.read(conscienceJourneyProvider.future);

    expect(firstUserJourney.xpTotal, 100);
    expect(secondUserJourney.xpTotal, 200);
    expect(service.fetchCount, 2);
  });

  test('conscienceJourneyProvider does not fetch while logged out', () async {
    final service = _UserScopedConscienceJourneyService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(const AuthState()),
        ),
        conscienceJourneyServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(conscienceJourneyProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(service.fetchCount, 0);
  });
}

Override _authenticatedAuthOverride([String userId = 'test-user']) {
  return authProvider.overrideWith(
    (ref) => _TestAuthNotifier(
      AuthState(
        status: AuthStatus.authenticated,
        userId: userId,
      ),
    ),
  );
}

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
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }

  void setAuthState(AuthState nextState) {
    state = nextState;
  }
}

class _FakeConscienceJourneyService extends ConscienceJourneyService {
  _FakeConscienceJourneyService() : super(Dio());

  String? recordedSourceId;

  @override
  Future<ConscienceJourneySummary> fetchJourney() async => _summary(100);

  @override
  Future<ConscienceJourneyUpdate> recordEvent({
    required String eventType,
    required String sourceId,
  }) async {
    recordedSourceId = sourceId;
    return ConscienceJourneyUpdate(
      summary: _summary(120),
      xpAwarded: 20,
      wasDuplicate: false,
      leveledUp: true,
      completedQuestKeys: const ['reflect_three_purchases'],
      unlockedBadgeKeys: const ['first_reflection'],
    );
  }
}

class _UserScopedConscienceJourneyService extends ConscienceJourneyService {
  _UserScopedConscienceJourneyService() : super(Dio());

  int fetchCount = 0;

  @override
  Future<ConscienceJourneySummary> fetchJourney() async {
    fetchCount += 1;
    return _summary(fetchCount * 100);
  }
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [];
}

ConscienceJourneySummary _summary(int xp) => ConscienceJourneySummary(
      xpTotal: xp,
      currentLevel: xp >= 120
          ? const ConscienceLevel(
              key: 'impulse_spotter',
              title: 'Impulse Spotter',
              requiredXp: 120,
            )
          : const ConscienceLevel(
              key: 'awakening',
              title: 'Awakening',
              requiredXp: 0,
            ),
      nextLevel: const ConscienceLevel(
        key: 'budget_guardian',
        title: 'Budget Guardian',
        requiredXp: 400,
      ),
      xpIntoLevel: xp,
      xpToNextLevel: 400 - xp,
      momentumDays: 1,
      bestMomentumDays: 1,
      weeklyQuests: [
        ConscienceQuest(
          key: 'reflect_three_purchases',
          title: 'Reflect on 3 purchases',
          description: 'Turn recent decisions into useful signal.',
          progress: 3,
          target: 3,
          xpReward: 15,
          isCompleted: true,
          completedAt: DateTime.utc(2026, 5, 11),
        ),
      ],
      badges: [
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'Reflected on your first purchase.',
          progress: 1,
          target: 1,
          isUnlocked: true,
          unlockedAt: DateTime.utc(2026, 5, 11),
        ),
      ],
    );
