import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conscienceJourneyProvider loads and records events', () async {
    final service = _FakeConscienceJourneyService();
    final container = ProviderContainer(
      overrides: [
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
      leveledUp: false,
      completedQuestKeys: const [],
      unlockedBadgeKeys: const ['first_reflection'],
    );
  }
}

ConscienceJourneySummary _summary(int xp) => ConscienceJourneySummary(
      xpTotal: xp,
      currentLevel: const ConscienceLevel(
        key: 'awakening',
        title: 'Awakening',
        requiredXp: 0,
      ),
      nextLevel: const ConscienceLevel(
        key: 'impulse_spotter',
        title: 'Impulse Spotter',
        requiredXp: 100,
      ),
      xpIntoLevel: xp,
      xpToNextLevel: 100 - xp,
      momentumDays: 1,
      bestMomentumDays: 1,
      weeklyQuests: const [],
      badges: const [],
    );
