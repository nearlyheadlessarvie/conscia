import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/insights/insight_feed_builder.dart';
import '../models/insight_feed_item.dart';
import 'behavioral_insights_provider.dart';
import 'insights_provider.dart';
import 'usage_provider.dart';
import 'user_provider.dart';

const dismissedInsightFeedIdsKey = 'dismissed_insight_feed_ids';

class InsightDismissalsNotifier extends StateNotifier<Set<String>> {
  InsightDismissalsNotifier(this._ref)
      : super(
          (_ref
                      .watch(sharedPreferencesProvider)
                      .getStringList(dismissedInsightFeedIdsKey) ??
                  const <String>[])
              .toSet(),
        );

  final Ref _ref;

  Future<void> dismiss(String id) async {
    final next = {...state, id};
    state = next;
    await _ref
        .read(sharedPreferencesProvider)
        .setStringList(dismissedInsightFeedIdsKey, next.toList()..sort());
  }

  bool isDismissed(String id) => state.contains(id);
}

final insightDismissalsProvider =
    StateNotifierProvider<InsightDismissalsNotifier, Set<String>>(
  InsightDismissalsNotifier.new,
);

final insightFeedProvider = FutureProvider<List<InsightFeedItem>>((ref) async {
  final behavioralInsights = await ref.watch(behavioralInsightsProvider.future);
  final summary = await ref.watch(insightsSummaryProvider.future);
  final categories = await ref.watch(insightsCategoriesProvider.future);
  final merchants = await ref.watch(insightsMerchantsProvider.future);
  final preferences = ref.watch(userPreferencesProvider);

  return buildInsightFeedItems(
    behavioralInsights: behavioralInsights,
    summary: summary,
    categories: categories,
    merchants: merchants,
    preferences: preferences,
  );
});

final dashboardInsightFeedProvider =
    FutureProvider<List<InsightFeedItem>>((ref) async {
  final items = await ref.watch(insightFeedProvider.future);
  final dismissed = ref.watch(insightDismissalsProvider);
  return buildDashboardInsightItems(
    items.where((item) => !dismissed.contains(item.id)).toList(),
  );
});

final insightFeedBySectionProvider =
    FutureProvider<Map<InsightFeedSection, List<InsightFeedItem>>>((ref) async {
  final items = await ref.watch(insightFeedProvider.future);
  return {
    for (final section in InsightFeedSection.values)
      section: items.where((item) => item.section == section).toList(),
  };
});
