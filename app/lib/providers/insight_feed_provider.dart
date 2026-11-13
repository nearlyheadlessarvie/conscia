import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/insights/insight_feed_builder.dart';
import '../models/behavioral_insights.dart';
import '../models/insight_feed_item.dart';
import '../models/insights_models.dart';
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

Future<void> clearInsightDismissals(SharedPreferences prefs) async {
  await prefs.remove(dismissedInsightFeedIdsKey);
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

class DashboardInsightSummary {
  const DashboardInsightSummary({
    required this.text,
    required this.tone,
  });

  final String text;
  final InsightFeedTone tone;
}

final dashboardInsightSummaryProvider =
    FutureProvider<DashboardInsightSummary?>((ref) async {
  final behavioralInsights = await ref.watch(behavioralInsightsProvider.future);
  final summary = await ref.watch(insightsSummaryProvider.future);
  final categories = await ref.watch(insightsCategoriesProvider.future);
  final merchants = await ref.watch(insightsMerchantsProvider.future);

  return buildDashboardInsightSummary(
    behavioralInsights: behavioralInsights,
    summary: summary,
    categories: categories,
    merchants: merchants,
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

DashboardInsightSummary? buildDashboardInsightSummary({
  required BehavioralInsights? behavioralInsights,
  required InsightsSummary? summary,
  required List<CategoryStat> categories,
  required List<MerchantStat> merchants,
}) {
  final budgetTrend = _strongestBudgetTrend(behavioralInsights?.budgetTrends);
  if (budgetTrend != null) return budgetTrend;

  if (behavioralInsights != null &&
      behavioralInsights.worthItCount >
          behavioralInsights.previousMonthWorthItCount) {
    return const DashboardInsightSummary(
      text: 'More of your decisions are feeling worth it than last month.',
      tone: InsightFeedTone.positive,
    );
  }

  if (summary != null && summary.regrettedAmount > 0) {
    return DashboardInsightSummary(
      text:
          '${summary.regrettedCategory} is carrying your strongest regret signal right now.',
      tone: InsightFeedTone.urgent,
    );
  }

  if (merchants.isNotEmpty) {
    final ranked = [...merchants]
      ..sort((a, b) => b.regretRate.compareTo(a.regretRate));
    final top = ranked.first;
    if (top.regretCount > 0) {
      return DashboardInsightSummary(
        text: '${top.merchant} keeps showing up in regret patterns.',
        tone: InsightFeedTone.caution,
      );
    }
  }

  if (categories.isNotEmpty) {
    final ranked = [...categories]
      ..sort((a, b) => b.regretRate.compareTo(a.regretRate));
    final top = ranked.first;
    if (top.regretRate > 0) {
      return DashboardInsightSummary(
        text: '${top.category} deserves a closer look before your next spend.',
        tone: InsightFeedTone.caution,
      );
    }
  }

  if (behavioralInsights != null) {
    return DashboardInsightSummary(
      text: _moodSummary(behavioralInsights.mood),
      tone: behavioralInsights.mood == FinancialMood.confident ||
              behavioralInsights.mood == FinancialMood.balanced
          ? InsightFeedTone.positive
          : InsightFeedTone.caution,
    );
  }

  return null;
}

DashboardInsightSummary? _strongestBudgetTrend(
  List<BudgetTrendInsight>? trends,
) {
  if (trends == null || trends.isEmpty) return null;

  final scored = trends
      .map((trend) {
        final paceCopy = budgetTrendPaceCopy(trend);
        if (paceCopy == null) return null;
        return (trend: trend, paceCopy: paceCopy);
      })
      .whereType<
          ({
            BudgetTrendInsight trend,
            ({
              String body,
              double delta,
              String summaryText,
              String title
            }) paceCopy
          })>()
      .toList();

  if (scored.isEmpty) return null;

  scored.sort(
    (a, b) => b.paceCopy.delta.abs().compareTo(a.paceCopy.delta.abs()),
  );
  final top = scored.first;

  return DashboardInsightSummary(
    text: top.paceCopy.summaryText,
    tone: top.paceCopy.delta > 0
        ? InsightFeedTone.caution
        : InsightFeedTone.positive,
  );
}

String _moodSummary(FinancialMood mood) {
  switch (mood) {
    case FinancialMood.confident:
      return 'Your money decisions are looking confident this week.';
    case FinancialMood.balanced:
      return 'Your money decisions are looking balanced this week.';
    case FinancialMood.cautious:
      return 'Your recent decisions suggest a little extra caution is helping.';
    case FinancialMood.impulsive:
      return 'Your recent decisions may need a stronger pause before spending.';
  }
}
