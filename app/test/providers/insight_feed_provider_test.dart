import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/providers/insights_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dashboardInsightFeedProvider filters dismissed insight IDs', () async {
    SharedPreferences.setMockInitialValues({
      'dismissed_insight_feed_ids': ['regret-summary-shopping'],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userPreferencesProvider.overrideWithValue(
          (currency: 'PHP', locale: 'en_PH'),
        ),
        behavioralInsightsProvider.overrideWith(
          (ref) async => const BehavioralInsights(
            mood: FinancialMood.balanced,
            worthItPercentage: 71,
            worthItCount: 5,
            previousMonthWorthItCount: 2,
            impulseeTrends: [],
            budgetTrends: [],
          ),
        ),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    final items = await container.read(dashboardInsightFeedProvider.future);

    expect(
      items.map((item) => item.id),
      isNot(contains('regret-summary-shopping')),
    );
    expect(items, isNotEmpty);
    expect(items.length, lessThanOrEqualTo(3));
  });

  test('dismissInsight persists and hides a card after refresh', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userPreferencesProvider.overrideWithValue(
          (currency: 'PHP', locale: 'en_PH'),
        ),
        behavioralInsightsProvider.overrideWith(
          (ref) async => const BehavioralInsights(
            mood: FinancialMood.confident,
            worthItPercentage: 90,
            worthItCount: 9,
            previousMonthWorthItCount: 3,
            impulseeTrends: [],
            budgetTrends: [],
          ),
        ),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    final firstItems = await container.read(dashboardInsightFeedProvider.future);
    expect(firstItems.map((item) => item.id), contains('weekly-mood-confident'));

    await container
        .read(insightDismissalsProvider.notifier)
        .dismiss('weekly-mood-confident');
    container.invalidate(dashboardInsightFeedProvider);

    final refreshedItems =
        await container.read(dashboardInsightFeedProvider.future);
    expect(
      refreshedItems.map((item) => item.id),
      isNot(contains('weekly-mood-confident')),
    );
    expect(
      prefs.getStringList('dismissed_insight_feed_ids'),
      contains('weekly-mood-confident'),
    );
  });
}
