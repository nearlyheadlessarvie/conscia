import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/conscience_journey.dart';
import '../services/conscience_journey_service.dart';

final conscienceJourneyServiceProvider =
    Provider<ConscienceJourneyService>((ref) {
  return ConscienceJourneyService(ref.watch(dioProvider));
});

final conscienceJourneyProvider =
    AsyncNotifierProvider<ConscienceJourneyNotifier, ConscienceJourneySummary>(
  ConscienceJourneyNotifier.new,
);

class ConscienceJourneyNotifier
    extends AsyncNotifier<ConscienceJourneySummary> {
  @override
  Future<ConscienceJourneySummary> build() {
    return ref.watch(conscienceJourneyServiceProvider).fetchJourney();
  }

  Future<ConscienceJourneyUpdate> recordEvent({
    required String eventType,
    required String sourceId,
  }) async {
    final service = ref.read(conscienceJourneyServiceProvider);
    final update = await service.recordEvent(
      eventType: eventType,
      sourceId: sourceId,
    );
    state = AsyncData(update.summary);
    return update;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(conscienceJourneyServiceProvider).fetchJourney(),
    );
  }
}
