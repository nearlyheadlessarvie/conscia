import 'package:conscia_app/core/insights/insight_feed_builder.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/models/insights_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prefs = (currency: 'PHP', locale: 'en_PH');

  test('buildInsightFeedItems creates stable IDs and prioritizes urgent cards',
      () {
    final items = buildInsightFeedItems(
      behavioralInsights: const BehavioralInsights(
        mood: FinancialMood.balanced,
        worthItPercentage: 71,
        worthItCount: 5,
        previousMonthWorthItCount: 2,
        impulseeTrends: [
          CategoryTrend(
            category: 'Shopping',
            regretRate: 0.62,
            transactionCount: 4,
            trend: TrendDirection.worsening,
          ),
        ],
        budgetTrends: [
          BudgetTrendInsight(
            category: 'Subscriptions',
            hasBudget: false,
            currencyCode: 'PHP',
            months: [1200, 1500, 1800],
            currentMonthSpend: 1800,
            insightLabel: 'Spending trending up',
            nudge: 'Add a budget for sharper insights',
          ),
          BudgetTrendInsight(
            category: 'Dining',
            hasBudget: true,
            currencyCode: 'PHP',
            months: [52, 68, 91],
            currentMonthSpend: 910,
            currentMonthPercentUsed: 91,
            insightLabel: 'Budget usage trending up',
          ),
        ],
      ),
      summary: InsightsSummary(
        regrettedAmount: 1890,
        regrettedCategory: 'Shopping',
        avgRegretRate: 0.44,
        patternCount: 3,
        updatedAt: DateTime.utc(2026, 5, 10),
      ),
      categories: const [],
      merchants: const [],
      preferences: prefs,
    );

    expect(
      items.map((item) => item.id),
      contains('budget-unbudgeted-subscriptions'),
    );
    expect(items.map((item) => item.id), contains('regret-summary-shopping'));
    expect(
        items.map((item) => item.id), contains('impulse-shopping-worsening'));
    expect(items.first.id, 'budget-unbudgeted-subscriptions');
    expect(items.first.kind, InsightFeedKind.budgetTrend);
    expect(items.first.mascot, InsightFeedMascot.both);
    expect(items.first.section, InsightFeedSection.budgetTrends);
    expect(items.first.dismissible, isTrue);
  });

  test('buildDashboardInsightItems returns at most three feed items', () {
    final items = buildInsightFeedItems(
      behavioralInsights: const BehavioralInsights(
        mood: FinancialMood.confident,
        worthItPercentage: 83,
        worthItCount: 8,
        previousMonthWorthItCount: 4,
        impulseeTrends: [
          CategoryTrend(
            category: 'Shopping',
            regretRate: 0.4,
            transactionCount: 4,
            trend: TrendDirection.worsening,
          ),
          CategoryTrend(
            category: 'Dining',
            regretRate: 0.2,
            transactionCount: 3,
            trend: TrendDirection.steady,
          ),
        ],
        budgetTrends: [
          BudgetTrendInsight(
            category: 'Bills',
            hasBudget: true,
            currencyCode: 'PHP',
            months: [40, 62, 86],
            currentMonthSpend: 860,
            currentMonthPercentUsed: 86,
            insightLabel: 'Budget usage trending up',
          ),
        ],
      ),
      summary: InsightsSummary(
        regrettedAmount: 500,
        regrettedCategory: 'Shopping',
        avgRegretRate: 0.3,
        patternCount: 2,
        updatedAt: DateTime.utc(2026, 5, 10),
      ),
      categories: const [
        CategoryStat(
          category: 'Shopping',
          totalSpend: 2400,
          regrettedSpend: 800,
          regretRate: 0.33,
          transactionCount: 5,
          projectedAnnual: 28800,
        ),
      ],
      merchants: const [
        MerchantStat(
          merchant: 'OpenAI',
          visitCount: 3,
          regretCount: 2,
          regretRate: 0.67,
          lastVisitDate: '2026-05-10',
        ),
      ],
      preferences: prefs,
    );

    final dashboardItems = buildDashboardInsightItems(items);

    expect(dashboardItems, hasLength(3));
    expect(dashboardItems.every((item) => item.showOnDashboard), isTrue);
  });

  test('positive mood and worth-it cards use angel mascot treatment', () {
    final items = buildInsightFeedItems(
      behavioralInsights: const BehavioralInsights(
        mood: FinancialMood.confident,
        worthItPercentage: 90,
        worthItCount: 9,
        previousMonthWorthItCount: 3,
        impulseeTrends: [],
        budgetTrends: [],
      ),
      summary: null,
      categories: const [],
      merchants: const [],
      preferences: prefs,
    );

    expect(items.map((item) => item.id), contains('weekly-mood-confident'));
    expect(items.map((item) => item.id), contains('worth-it-monthly'));
    expect(
      items.where((item) => item.mascot == InsightFeedMascot.angel),
      isNotEmpty,
    );
  });

  test('budget trend detail explains the same 3-month pace as summary', () {
    final items = buildInsightFeedItems(
      behavioralInsights: const BehavioralInsights(
        mood: FinancialMood.balanced,
        worthItPercentage: 71,
        worthItCount: 5,
        previousMonthWorthItCount: 5,
        impulseeTrends: [],
        budgetTrends: [
          BudgetTrendInsight(
            category: 'Dining',
            hasBudget: true,
            currencyCode: 'PHP',
            months: [52, 68, 85],
            currentMonthSpend: 3400,
            currentMonthPercentUsed: 85,
            insightLabel: 'Budget usage trending up',
          ),
        ],
      ),
      summary: null,
      categories: const [],
      merchants: const [],
      preferences: prefs,
    );

    final diningTrend =
        items.singleWhere((item) => item.id == 'budget-usage-dining');

    expect(diningTrend.title, contains('recent 3-month pace'));
    expect(diningTrend.body, contains('3-month average'));
    expect(diningTrend.body, contains('42% above'));
    expect(diningTrend.body, isNot(contains('5626%')));
  });
}
