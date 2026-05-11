import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/models/insights_models.dart';

List<InsightFeedItem> buildInsightFeedItems({
  required BehavioralInsights? behavioralInsights,
  required InsightsSummary? summary,
  required List<CategoryStat> categories,
  required List<MerchantStat> merchants,
  required ({String currency, String locale}) preferences,
}) {
  final items = <InsightFeedItem>[];

  if (behavioralInsights != null) {
    items.addAll(
      _budgetTrendItems(behavioralInsights.budgetTrends, preferences),
    );
    items.addAll(_impulseTrendItems(behavioralInsights.impulseeTrends));
    items.add(_weeklyMoodItem(behavioralInsights));
    if (behavioralInsights.worthItCount >
        behavioralInsights.previousMonthWorthItCount) {
      items.add(_worthItItem(behavioralInsights));
    }
  }

  if (summary != null && summary.regrettedAmount > 0) {
    items.add(_regretSummaryItem(summary, preferences));
  }

  if (merchants.isNotEmpty) {
    final rankedMerchants = [...merchants]
      ..sort((a, b) => b.regretRate.compareTo(a.regretRate));
    final top = rankedMerchants.first;
    if (top.regretCount > 0) {
      items.add(_merchantPatternItem(top));
    }
  }

  if (categories.isNotEmpty && summary == null) {
    final rankedCategories = [...categories]
      ..sort((a, b) => b.regrettedSpend.compareTo(a.regrettedSpend));
    final top = rankedCategories.first;
    if (top.regrettedSpend > 0) {
      items.add(_categoryRegretItem(top, preferences));
    }
  }

  items.sort((a, b) {
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    return a.id.compareTo(b.id);
  });

  return items;
}

({double delta, String summaryText, String title, String body})?
    budgetTrendPaceCopy(BudgetTrendInsight trend) {
  final previousMonths = trend.months.take(trend.months.length - 1);
  final previousAverage = previousMonths.isEmpty
      ? 0.0
      : previousMonths.reduce((a, b) => a + b) / previousMonths.length;
  if (previousAverage <= 0) return null;

  final currentValue = trend.hasBudget
      ? trend.currentMonthPercentUsed ?? trend.months.lastOrNull
      : trend.currentMonthSpend;
  if (currentValue == null) return null;

  final delta = (currentValue - previousAverage) / previousAverage;
  if (delta.abs() < 0.1) return null;

  final direction = delta > 0 ? 'above' : 'below';
  final percent = (delta.abs() * 100).round();
  return (
    delta: delta,
    summaryText: '${trend.category} is $direction your recent 3-month pace.',
    title: '${trend.category} is $direction your recent 3-month pace',
    body: 'This month is $percent% $direction your 3-month average.',
  );
}

List<InsightFeedItem> buildDashboardInsightItems(List<InsightFeedItem> items) {
  return items.where((item) => item.showOnDashboard).take(3).toList();
}

List<InsightFeedItem> _budgetTrendItems(
  List<BudgetTrendInsight> trends,
  ({String currency, String locale}) preferences,
) {
  return trends
      .where(
    (trend) => !trend.hasBudget || (trend.currentMonthPercentUsed ?? 0) >= 80,
  )
      .map((trend) {
    if (!trend.hasBudget) {
      final amount = CurrencyFormatter.format(
        trend.currentMonthSpend,
        currencyCode: trend.currencyCode,
        locale: preferences.locale,
      );
      return InsightFeedItem(
        id: 'budget-unbudgeted-${_slug(trend.category)}',
        kind: InsightFeedKind.budgetTrend,
        priority: 100,
        title: '${trend.category} has enough activity for a budget',
        body: trend.nudge ??
            'Add a budget so Conscia can make this trend more useful.',
        metric: amount,
        caption: 'No budget yet',
        section: InsightFeedSection.budgetTrends,
        tone: InsightFeedTone.caution,
        mascot: InsightFeedMascot.both,
        mascotFrame: 'angel:8_shield.png|devil:9_coin.png',
        budgetCategory: trend.category,
        interaction: InsightFeedInteraction.action,
        interactionLabel: 'Add budget',
      );
    }

    final percent = trend.currentMonthPercentUsed?.round() ?? 0;
    final paceCopy = budgetTrendPaceCopy(trend);
    return InsightFeedItem(
      id: 'budget-usage-${_slug(trend.category)}',
      kind: InsightFeedKind.budgetTrend,
      priority: percent >= 95 ? 96 : 88,
      title: paceCopy?.title ?? '${trend.category} is pacing high',
      body: paceCopy?.body ?? trend.insightLabel,
      metric: '$percent%',
      caption: 'Current monthly usage',
      section: InsightFeedSection.budgetTrends,
      tone: percent >= 95 ? InsightFeedTone.urgent : InsightFeedTone.caution,
      mascot: InsightFeedMascot.devil,
      mascotFrame: 'devil:8_whisper.png',
      interaction: InsightFeedInteraction.drillDown,
      interactionLabel: 'View trend',
    );
  }).toList();
}

List<InsightFeedItem> _impulseTrendItems(List<CategoryTrend> trends) {
  return trends
      .where((trend) => trend.trend == TrendDirection.worsening)
      .map(
        (trend) => InsightFeedItem(
          id: 'impulse-${_slug(trend.category)}-${trend.trend.name}',
          kind: InsightFeedKind.impulseTrend,
          priority: 78,
          title: '${trend.category} is getting more impulsive',
          body:
              'Recent reflections suggest this category deserves a pause before spending.',
          metric: '${(trend.regretRate * 100).round()}%',
          caption: '${trend.transactionCount} recent decisions',
          section: InsightFeedSection.recentSignals,
          tone: InsightFeedTone.caution,
          mascot: InsightFeedMascot.devil,
          mascotFrame: 'devil:8_whisper.png',
          interaction: InsightFeedInteraction.drillDown,
          interactionLabel: 'View pattern',
        ),
      )
      .toList();
}

InsightFeedItem _weeklyMoodItem(BehavioralInsights insights) {
  final mood = _moodLabel(insights.mood);
  final isPositive = insights.mood == FinancialMood.confident ||
      insights.mood == FinancialMood.balanced;
  return InsightFeedItem(
    id: 'weekly-mood-${insights.mood.name}',
    kind: InsightFeedKind.weeklyMood,
    priority: isPositive ? 58 : 72,
    title: 'Your financial mood is $mood',
    body:
        '${insights.worthItPercentage.round()}% of your decisions this week were reasoned.',
    metric: '${insights.worthItPercentage.round()}%',
    caption: 'This week',
    section: InsightFeedSection.thisWeek,
    tone: isPositive ? InsightFeedTone.positive : InsightFeedTone.caution,
    mascot: isPositive ? InsightFeedMascot.angel : InsightFeedMascot.both,
    mascotFrame: isPositive
        ? 'angel:4_win.png'
        : 'angel:11_focuspray.png|devil:8_whisper.png',
  );
}

InsightFeedItem _worthItItem(BehavioralInsights insights) {
  final diff = insights.worthItCount - insights.previousMonthWorthItCount;
  return InsightFeedItem(
    id: 'worth-it-monthly',
    kind: InsightFeedKind.worthIt,
    priority: 54,
    title: 'More decisions are feeling worth it',
    body: 'You have made ${insights.worthItCount} decisions you are proud of.',
    metric: '+$diff',
    caption: 'vs last month',
    section: InsightFeedSection.thisWeek,
    tone: InsightFeedTone.positive,
    mascot: InsightFeedMascot.angel,
    mascotFrame: 'angel:15_numberone.png',
  );
}

InsightFeedItem _regretSummaryItem(
  InsightsSummary summary,
  ({String currency, String locale}) preferences,
) {
  final amount = CurrencyFormatter.format(
    summary.regrettedAmount,
    currencyCode: preferences.currency,
    locale: preferences.locale,
  );
  return InsightFeedItem(
    id: 'regret-summary-${_slug(summary.regrettedCategory)}',
    kind: InsightFeedKind.regretSummary,
    priority: 86,
    title: '$amount regretted on ${summary.regrettedCategory}',
    body: 'Tap to see the pattern behind this spending.',
    metric: '${(summary.avgRegretRate * 100).round()}%',
    caption: '${summary.patternCount} patterns',
    route:
        '/insights/categories/${Uri.encodeComponent(summary.regrettedCategory)}',
    section: InsightFeedSection.regretPatterns,
    tone: InsightFeedTone.urgent,
    mascot: InsightFeedMascot.devil,
    mascotFrame: 'devil:14_frustrated.png',
    interaction: InsightFeedInteraction.drillDown,
    interactionLabel: 'View pattern',
  );
}

InsightFeedItem _categoryRegretItem(
  CategoryStat category,
  ({String currency, String locale}) preferences,
) {
  final amount = CurrencyFormatter.format(
    category.regrettedSpend,
    currencyCode: preferences.currency,
    locale: preferences.locale,
  );
  return InsightFeedItem(
    id: 'category-regret-${_slug(category.category)}',
    kind: InsightFeedKind.regretSummary,
    priority: 80,
    title: '$amount regretted in ${category.category}',
    body: 'This category is carrying the strongest regret signal right now.',
    metric: '${(category.regretRate * 100).round()}%',
    caption: '${category.transactionCount} purchases',
    route: '/insights/categories/${Uri.encodeComponent(category.category)}',
    section: InsightFeedSection.regretPatterns,
    tone: InsightFeedTone.urgent,
    mascot: InsightFeedMascot.devil,
    mascotFrame: 'devil:14_frustrated.png',
    interaction: InsightFeedInteraction.drillDown,
    interactionLabel: 'View pattern',
  );
}

InsightFeedItem _merchantPatternItem(MerchantStat merchant) {
  return InsightFeedItem(
    id: 'merchant-pattern-${_slug(merchant.merchant)}',
    kind: InsightFeedKind.merchantPattern,
    priority: 70,
    title: '${merchant.merchant} keeps showing up',
    body:
        '${merchant.regretCount} of ${merchant.visitCount} visits were later marked regret.',
    metric: '${(merchant.regretRate * 100).round()}%',
    caption: 'Regret rate',
    route: '/insights/merchants/${Uri.encodeComponent(merchant.merchant)}',
    section: InsightFeedSection.regretPatterns,
    tone: InsightFeedTone.caution,
    mascot: InsightFeedMascot.devil,
    mascotFrame: 'devil:9_coin.png',
    interaction: InsightFeedInteraction.drillDown,
    interactionLabel: 'View merchant',
  );
}

String _moodLabel(FinancialMood mood) {
  switch (mood) {
    case FinancialMood.confident:
      return 'confident';
    case FinancialMood.balanced:
      return 'balanced';
    case FinancialMood.cautious:
      return 'cautious';
    case FinancialMood.impulsive:
      return 'impulsive';
  }
}

String _slug(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
