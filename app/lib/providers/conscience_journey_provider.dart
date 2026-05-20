import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/conscience_journey.dart';
import '../services/conscience_journey_service.dart';
import 'alert_provider.dart';
import 'auth_provider.dart';
import 'family_space_provider.dart';

final conscienceJourneyServiceProvider =
    Provider<ConscienceJourneyService>((ref) {
  return ConscienceJourneyService(ref.watch(dioProvider));
});

final conscienceJourneyProvider =
    AsyncNotifierProvider<ConscienceJourneyNotifier, ConscienceJourneySummary>(
  ConscienceJourneyNotifier.new,
  dependencies: [authProvider, conscienceJourneyServiceProvider],
);

class ConscienceJourneyNotifier
    extends AsyncNotifier<ConscienceJourneySummary> {
  @override
  Future<ConscienceJourneySummary> build() {
    return _loadJourney();
  }

  Future<ConscienceJourneySummary> _loadJourney() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      throw StateError(
        'Cannot load conscience journey without an authenticated session.',
      );
    }
    final familySpace = await ref.watch(familySpaceProvider.future).catchError(
          (_) => null,
        );
    final summary =
        await ref.watch(conscienceJourneyServiceProvider).fetchJourney();
    return _filterFamilyQuests(
      summary,
      hasFamilySpace: familySpace != null,
    );
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
    final familySpace = await ref.read(familySpaceProvider.future).catchError(
          (_) => null,
        );
    final filteredSummary = _filterFamilyQuests(
      update.summary,
      hasFamilySpace: familySpace != null,
    );
    final filteredUpdate = ConscienceJourneyUpdate(
      summary: filteredSummary,
      xpAwarded: update.xpAwarded,
      wasDuplicate: update.wasDuplicate,
      leveledUp: update.leveledUp,
      completedQuestKeys: update.completedQuestKeys,
      unlockedBadgeKeys: update.unlockedBadgeKeys,
      mascotMoment: update.mascotMoment,
    );
    state = AsyncData(filteredSummary);
    ref.read(localAlertsProvider.notifier).addJourneyUpdate(filteredUpdate);
    return filteredUpdate;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadJourney);
  }
}

const _familyQuestKeys = {
  'send_family_invite',
  'add_family_expense',
};

const _weeklyQuestDisplayLimit = 5;

ConscienceJourneySummary _filterFamilyQuests(
  ConscienceJourneySummary summary, {
  required bool hasFamilySpace,
}) {
  final eligibleQuests = hasFamilySpace
      ? summary.weeklyQuests
      : summary.weeklyQuests
          .where((quest) => !_familyQuestKeys.contains(quest.key))
          .toList(growable: false);
  final filteredQuests = _weeklyQuestSet(
    eligibleQuests,
    hasFamilySpace: hasFamilySpace,
  );
  if (filteredQuests.length == summary.weeklyQuests.length &&
      filteredQuests.indexed.every(
        (entry) => identical(entry.$2, summary.weeklyQuests[entry.$1]),
      )) {
    return summary;
  }
  return ConscienceJourneySummary(
    xpTotal: summary.xpTotal,
    currentLevel: summary.currentLevel,
    nextLevel: summary.nextLevel,
    xpIntoLevel: summary.xpIntoLevel,
    xpToNextLevel: summary.xpToNextLevel,
    momentumDays: summary.momentumDays,
    bestMomentumDays: summary.bestMomentumDays,
    weeklyQuests: filteredQuests,
    badges: summary.badges,
    recentMascotMoment: summary.recentMascotMoment,
  );
}

List<ConscienceQuest> _weeklyQuestSet(
  List<ConscienceQuest> quests, {
  required bool hasFamilySpace,
}) {
  if (quests.length <= _weeklyQuestDisplayLimit) return quests;
  if (!hasFamilySpace) {
    return quests.take(_weeklyQuestDisplayLimit).toList(growable: false);
  }

  final familyQuests = quests
      .where((quest) => _familyQuestKeys.contains(quest.key))
      .take(2)
      .toList(growable: false);
  final soloQuests = quests
      .where((quest) => !_familyQuestKeys.contains(quest.key))
      .take(_weeklyQuestDisplayLimit - familyQuests.length)
      .toList(growable: false);
  final selectedKeys = {
    ...soloQuests.map((quest) => quest.key),
    ...familyQuests.map((quest) => quest.key),
  };

  return quests
      .where((quest) => selectedKeys.contains(quest.key))
      .take(_weeklyQuestDisplayLimit)
      .toList(growable: false);
}
