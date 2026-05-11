# Dynamic Insights Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static dashboard insight stack with a curated, dismissible, mascot-backed insight feed, and expand the Insights screen into a dynamic multi-section insight surface.

**Architecture:** Build insight cards app-side from existing API-backed providers, keeping the first pass backend-free and drift-free from persisted insight card state. A pure feed builder produces stable `InsightFeedItem`s, a SharedPreferences-backed notifier stores dismissed item IDs, and dashboard/Insights widgets render the same model with different density.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, GoRouter, existing Conscia insight providers, existing mascot sprite-sheet renderer.

---

## File Structure

- Create `app/lib/models/insight_feed_item.dart`
  - Defines `InsightFeedItem` plus small enums for card kind, tone, section, mascot family, and mascot frame.
- Create `app/lib/core/insights/insight_feed_builder.dart`
  - Pure, synchronous builder that maps `BehavioralInsights`, `InsightsSummary`, `CategoryStat`, `MerchantStat`, and user preferences into ranked insight feed items.
- Create `app/lib/providers/insight_feed_provider.dart`
  - Riverpod composition layer that watches existing async insight providers, watches local dismissals, and exposes full + dashboard-visible feed providers.
- Create `app/lib/screens/dashboard/widgets/insight_feed_card.dart`
  - Compact dashboard card with optional mascot cameo, tap route, and dismiss button.
- Modify `app/lib/screens/dashboard/dashboard_screen.dart`
  - Replace fixed behavioral card stack with `dashboardInsightFeedProvider` rendering max three `InsightFeedCard`s.
- Modify `app/lib/screens/insights/insights_screen.dart`
  - Retitle to `Insights`, render sections from the feed plus existing regret/category/merchant details, and collapse empty sections.
- Create `app/test/core/insights/insight_feed_builder_test.dart`
  - Verifies stable IDs, ranking, max dashboard candidates, section classification, and mascot selection.
- Create `app/test/providers/insight_feed_provider_test.dart`
  - Verifies SharedPreferences dismissal behavior and dashboard filtering.
- Modify `app/test/screens/dashboard/dashboard_alerts_test.dart`
  - Update dashboard insight assertions from old fixed cards to dynamic feed cards and dismissal.
- Modify `app/test/screens/insights/insights_screen_test.dart`
  - Update title/sections expectations and verify the expanded screen renders dynamic sections.

---

### Task 1: Add Feed Model and Pure Builder

**Files:**
- Create: `app/lib/models/insight_feed_item.dart`
- Create: `app/lib/core/insights/insight_feed_builder.dart`
- Test: `app/test/core/insights/insight_feed_builder_test.dart`

- [ ] **Step 1: Write the failing builder tests**

Create `app/test/core/insights/insight_feed_builder_test.dart`:

```dart
import 'package:conscia_app/core/insights/insight_feed_builder.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/models/insights_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prefs = (currency: 'PHP', locale: 'en_PH');

  test('buildInsightFeedItems creates stable IDs and prioritizes urgent cards', () {
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

    expect(items.map((item) => item.id), contains('budget-unbudgeted-subscriptions'));
    expect(items.map((item) => item.id), contains('regret-summary-shopping'));
    expect(items.map((item) => item.id), contains('impulse-shopping-worsening'));
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
}
```

- [ ] **Step 2: Run builder tests to verify they fail**

Run:

```powershell
Set-Location app
flutter test test/core/insights/insight_feed_builder_test.dart
```

Expected: FAIL because `InsightFeedItem` and `buildInsightFeedItems` do not exist yet.

- [ ] **Step 3: Implement the feed model**

Create `app/lib/models/insight_feed_item.dart`:

```dart
enum InsightFeedKind {
  budgetTrend,
  regretSummary,
  impulseTrend,
  weeklyMood,
  worthIt,
  merchantPattern,
}

enum InsightFeedTone {
  positive,
  caution,
  urgent,
  neutral,
}

enum InsightFeedSection {
  thisWeek,
  budgetTrends,
  regretPatterns,
  recentSignals,
}

enum InsightFeedMascot {
  none,
  angel,
  devil,
  both,
}

class InsightFeedItem {
  const InsightFeedItem({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.body,
    required this.section,
    required this.tone,
    required this.mascot,
    this.metric,
    this.caption,
    this.route = '/insights',
    this.mascotFrame,
    this.expiresKey,
    this.dismissible = true,
    this.showOnDashboard = true,
  });

  final String id;
  final InsightFeedKind kind;
  final int priority;
  final String title;
  final String body;
  final String? metric;
  final String? caption;
  final String route;
  final InsightFeedSection section;
  final InsightFeedTone tone;
  final InsightFeedMascot mascot;
  final String? mascotFrame;
  final String? expiresKey;
  final bool dismissible;
  final bool showOnDashboard;
}
```

- [ ] **Step 4: Implement the pure builder**

Create `app/lib/core/insights/insight_feed_builder.dart`:

```dart
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
    items.addAll(_budgetTrendItems(behavioralInsights.budgetTrends, preferences));
    items.addAll(_impulseTrendItems(behavioralInsights.impulseeTrends));
    items.add(_weeklyMoodItem(behavioralInsights));
    if (behavioralInsights.worthItCount > behavioralInsights.previousMonthWorthItCount) {
      items.add(_worthItItem(behavioralInsights));
    }
  }

  if (summary != null && summary.regrettedAmount > 0) {
    items.add(_regretSummaryItem(summary, preferences));
  }

  if (merchants.isNotEmpty) {
    final merchant = [...merchants]..sort((a, b) => b.regretRate.compareTo(a.regretRate));
    final top = merchant.first;
    if (top.regretCount > 0) {
      items.add(_merchantPatternItem(top));
    }
  }

  if (categories.isNotEmpty && summary == null) {
    final category = [...categories]..sort((a, b) => b.regrettedSpend.compareTo(a.regrettedSpend));
    final top = category.first;
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

List<InsightFeedItem> buildDashboardInsightItems(List<InsightFeedItem> items) {
  return items.where((item) => item.showOnDashboard).take(3).toList();
}

List<InsightFeedItem> _budgetTrendItems(
  List<BudgetTrendInsight> trends,
  ({String currency, String locale}) preferences,
) {
  return trends
      .where((trend) => !trend.hasBudget || (trend.currentMonthPercentUsed ?? 0) >= 80)
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
        body: trend.nudge ?? 'Add a budget so Conscia can make this trend more useful.',
        metric: amount,
        caption: 'No budget yet',
        section: InsightFeedSection.budgetTrends,
        tone: InsightFeedTone.caution,
        mascot: InsightFeedMascot.both,
        mascotFrame: 'angel:8_shield.png|devil:9_coin.png',
      );
    }

    final percent = trend.currentMonthPercentUsed?.round() ?? 0;
    return InsightFeedItem(
      id: 'budget-usage-${_slug(trend.category)}',
      kind: InsightFeedKind.budgetTrend,
      priority: percent >= 95 ? 96 : 88,
      title: '${trend.category} is pacing high',
      body: trend.insightLabel,
      metric: '$percent%',
      caption: 'Current monthly usage',
      section: InsightFeedSection.budgetTrends,
      tone: percent >= 95 ? InsightFeedTone.urgent : InsightFeedTone.caution,
      mascot: InsightFeedMascot.devil,
      mascotFrame: 'devil:8_whisper.png',
    );
  }).toList();
}

List<InsightFeedItem> _impulseTrendItems(List<CategoryTrend> trends) {
  return trends
      .where((trend) => trend.trend == TrendDirection.worsening)
      .map((trend) => InsightFeedItem(
            id: 'impulse-${_slug(trend.category)}-${trend.trend.name}',
            kind: InsightFeedKind.impulseTrend,
            priority: 78,
            title: '${trend.category} is getting more impulsive',
            body: 'Recent reflections suggest this category deserves a pause before spending.',
            metric: '${(trend.regretRate * 100).round()}%',
            caption: '${trend.transactionCount} recent decisions',
            section: InsightFeedSection.recentSignals,
            tone: InsightFeedTone.caution,
            mascot: InsightFeedMascot.devil,
            mascotFrame: 'devil:8_whisper.png',
          ))
      .toList();
}

InsightFeedItem _weeklyMoodItem(BehavioralInsights insights) {
  final mood = _moodLabel(insights.mood);
  final isPositive =
      insights.mood == FinancialMood.confident || insights.mood == FinancialMood.balanced;
  return InsightFeedItem(
    id: 'weekly-mood-${insights.mood.name}',
    kind: InsightFeedKind.weeklyMood,
    priority: isPositive ? 58 : 72,
    title: 'Your financial mood is $mood',
    body: '${insights.worthItPercentage.round()}% of your decisions this week were reasoned.',
    metric: '${insights.worthItPercentage.round()}%',
    caption: 'This week',
    section: InsightFeedSection.thisWeek,
    tone: isPositive ? InsightFeedTone.positive : InsightFeedTone.caution,
    mascot: isPositive ? InsightFeedMascot.angel : InsightFeedMascot.both,
    mascotFrame: isPositive ? 'angel:4_win.png' : 'angel:11_focuspray.png|devil:8_whisper.png',
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
    route: '/insights',
    section: InsightFeedSection.regretPatterns,
    tone: InsightFeedTone.urgent,
    mascot: InsightFeedMascot.devil,
    mascotFrame: 'devil:14_frustrated.png',
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
  );
}

InsightFeedItem _merchantPatternItem(MerchantStat merchant) {
  return InsightFeedItem(
    id: 'merchant-pattern-${_slug(merchant.merchant)}',
    kind: InsightFeedKind.merchantPattern,
    priority: 70,
    title: '${merchant.merchant} keeps showing up',
    body: '${merchant.regretCount} of ${merchant.visitCount} visits were later marked regret.',
    metric: '${(merchant.regretRate * 100).round()}%',
    caption: 'Regret rate',
    route: '/insights/merchants/${Uri.encodeComponent(merchant.merchant)}',
    section: InsightFeedSection.regretPatterns,
    tone: InsightFeedTone.caution,
    mascot: InsightFeedMascot.devil,
    mascotFrame: 'devil:9_coin.png',
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
```

- [ ] **Step 5: Run builder tests to verify they pass**

Run:

```powershell
Set-Location app
flutter test test/core/insights/insight_feed_builder_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit Task 1**

Run:

```powershell
git add app/lib/models/insight_feed_item.dart app/lib/core/insights/insight_feed_builder.dart app/test/core/insights/insight_feed_builder_test.dart
git commit -m "feat: add dynamic insight feed builder"
```

Expected: commit succeeds.

---

### Task 2: Add Feed Providers and Dismissal Persistence

**Files:**
- Create: `app/lib/providers/insight_feed_provider.dart`
- Test: `app/test/providers/insight_feed_provider_test.dart`

- [ ] **Step 1: Write failing provider tests**

Create `app/test/providers/insight_feed_provider_test.dart`:

```dart
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
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

    expect(items.map((item) => item.id), isNot(contains('regret-summary-shopping')));
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

    final refreshedItems = await container.read(dashboardInsightFeedProvider.future);
    expect(refreshedItems.map((item) => item.id), isNot(contains('weekly-mood-confident')));
    expect(prefs.getStringList('dismissed_insight_feed_ids'), contains('weekly-mood-confident'));
  });
}
```

- [ ] **Step 2: Run provider tests to verify they fail**

Run:

```powershell
Set-Location app
flutter test test/providers/insight_feed_provider_test.dart
```

Expected: FAIL because `insight_feed_provider.dart` does not exist.

- [ ] **Step 3: Implement providers**

Create `app/lib/providers/insight_feed_provider.dart`:

```dart
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
          (_ref.watch(sharedPreferencesProvider)
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
```

- [ ] **Step 4: Run provider tests to verify they pass**

Run:

```powershell
Set-Location app
flutter test test/providers/insight_feed_provider_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit Task 2**

Run:

```powershell
git add app/lib/providers/insight_feed_provider.dart app/test/providers/insight_feed_provider_test.dart
git commit -m "feat: persist dismissed insight feed cards"
```

Expected: commit succeeds.

---

### Task 3: Add Dashboard Feed Card UI

**Files:**
- Create: `app/lib/screens/dashboard/widgets/insight_feed_card.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Add a failing direct widget test**

Add these imports to `app/test/screens/dashboard/dashboard_alerts_test.dart`:

```dart
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/screens/dashboard/widgets/insight_feed_card.dart';
```

Add this test near the existing dashboard widget tests:

```dart
  testWidgets('insight feed card displays content and dismiss action',
      (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightFeedCard(
            item: const InsightFeedItem(
              id: 'weekly-mood-confident',
              kind: InsightFeedKind.weeklyMood,
              priority: 58,
              title: 'Your financial mood is confident',
              body: '90% of your decisions this week were reasoned.',
              metric: '90%',
              caption: 'This week',
              section: InsightFeedSection.thisWeek,
              tone: InsightFeedTone.positive,
              mascot: InsightFeedMascot.angel,
              mascotFrame: 'angel:4_win.png',
            ),
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('Your financial mood is confident'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.byTooltip('Dismiss insight'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss insight'));
    await tester.pump();

    expect(dismissed, isTrue);
  });
```

- [ ] **Step 2: Run dashboard tests to verify they fail**

Run:

```powershell
Set-Location app
flutter test test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: FAIL because `InsightFeedCard` does not exist yet.

- [ ] **Step 3: Implement compact feed card**

Create `app/lib/screens/dashboard/widgets/insight_feed_card.dart`:

```dart
import 'package:conscia_app/core/assets/mascot_sprite_sheet.dart';
import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InsightFeedCard extends StatelessWidget {
  const InsightFeedCard({
    super.key,
    required this.item,
    this.onDismiss,
  });

  final InsightFeedItem item;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(colors);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MascotCameo(item: item, color: toneColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (item.metric != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: toneColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.metric!,
                              style: textTheme.labelLarge?.copyWith(
                                color: toneColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (item.caption != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.caption!,
                        style: textTheme.labelSmall?.copyWith(
                          color: toneColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.dismissible && onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Dismiss insight',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(ColorScheme colors) {
    switch (item.tone) {
      case InsightFeedTone.positive:
        return colors.primary;
      case InsightFeedTone.caution:
        return colors.tertiary;
      case InsightFeedTone.urgent:
        return colors.error;
      case InsightFeedTone.neutral:
        return colors.secondary;
    }
  }
}

class _MascotCameo extends StatelessWidget {
  const _MascotCameo({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (item.mascot == InsightFeedMascot.none) {
      return _FallbackIcon(item: item, color: color);
    }

    return SizedBox(
      width: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (item.mascot == InsightFeedMascot.angel ||
              item.mascot == InsightFeedMascot.both)
            MascotSpriteFrame(
              atlas: angelMascotAtlas,
              frameName: _frameFor('angel', item.mascotFrame) ?? '1_neutral.png',
              width: item.mascot == InsightFeedMascot.both ? 36 : 44,
            ),
          if (item.mascot == InsightFeedMascot.devil ||
              item.mascot == InsightFeedMascot.both)
            Positioned(
              left: item.mascot == InsightFeedMascot.both ? 16 : 0,
              top: item.mascot == InsightFeedMascot.both ? 8 : 0,
              child: MascotSpriteFrame(
                atlas: devilMascotAtlas,
                frameName: _frameFor('devil', item.mascotFrame) ?? '1_neutral.png',
                width: item.mascot == InsightFeedMascot.both ? 36 : 44,
              ),
            ),
        ],
      ),
    );
  }

  static String? _frameFor(String family, String? descriptor) {
    if (descriptor == null) return null;
    for (final part in descriptor.split('|')) {
      final pieces = part.split(':');
      if (pieces.length == 2 && pieces.first == family) {
        return pieces.last;
      }
    }
    return null;
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
    required this.item,
    required this.color,
  });

  final InsightFeedItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_icon, color: color),
    );
  }

  IconData get _icon {
    switch (item.kind) {
      case InsightFeedKind.budgetTrend:
        return Icons.account_balance_wallet_rounded;
      case InsightFeedKind.regretSummary:
        return Icons.warning_amber_rounded;
      case InsightFeedKind.impulseTrend:
        return Icons.trending_up_rounded;
      case InsightFeedKind.weeklyMood:
        return Icons.psychology_rounded;
      case InsightFeedKind.worthIt:
        return Icons.thumb_up_alt_rounded;
      case InsightFeedKind.merchantPattern:
        return Icons.storefront_rounded;
    }
  }
}
```

- [ ] **Step 4: Run dashboard tests to verify the widget passes**

Run:

```powershell
Set-Location app
flutter test test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit Task 3**

Run:

```powershell
git add app/lib/screens/dashboard/widgets/insight_feed_card.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat: add dynamic dashboard insight card"
```

Expected: commit succeeds.

---

### Task 4: Wire Dynamic Feed Into Dashboard

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Add failing dashboard integration assertions**

Modify the existing `dashboard shows budget trends card when behavioral insights include trends` test in `app/test/screens/dashboard/dashboard_alerts_test.dart` so the final expectations are:

```dart
    expect(find.text('Your Insights'), findsOneWidget);
    expect(find.text('Subscriptions has enough activity for a budget'), findsOneWidget);
    expect(find.text('No budget yet'), findsOneWidget);
    expect(find.text('Add a budget for sharper insights'), findsOneWidget);
    expect(find.text('Budget trends'), findsNothing);
```

Add this new test near the existing dashboard insight test:

```dart
  testWidgets('dashboard insight card can be dismissed locally', (tester) async {
    final container = ProviderContainer(
      overrides: [
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
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
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Your financial mood is confident'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss insight').first);
    await tester.pumpAndSettle();

    expect(find.text('Your financial mood is confident'), findsNothing);
  });
```

Also add this import at the top if missing:

```dart
import 'package:conscia_app/providers/insights_provider.dart';
```

- [ ] **Step 2: Run dashboard tests to verify they fail**

Run:

```powershell
Set-Location app
flutter test test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: FAIL because the dashboard still renders the old static cards.

- [ ] **Step 3: Update dashboard imports**

In `app/lib/screens/dashboard/dashboard_screen.dart`, remove these imports:

```dart
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/screens/dashboard/widgets/budget_trends_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/financial_mood_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/impulse_trends_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_summary_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/worth_it_counter_card.dart';
```

Add these imports:

```dart
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/screens/dashboard/widgets/insight_feed_card.dart';
```

Keep `behavioral_insights_provider.dart` because `_onRefresh` still invalidates the source provider.

- [ ] **Step 4: Replace dashboard insight state read**

In `build`, replace:

```dart
    final insightsState = ref.watch(behavioralInsightsProvider);
```

with:

```dart
    final insightsState = ref.watch(dashboardInsightFeedProvider);
```

- [ ] **Step 5: Replace the old fixed insight section**

In `DashboardScreen`, replace the whole block starting at:

```dart
        // Behavioral Insights Section — only rendered when data is available
        ...insightsState.when<List<Widget>>(
```

through the closing `),` of that `when` block with:

```dart
        ...insightsState.when<List<Widget>>(
          loading: () => [
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Your Insights'),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: InsightSkeletonSection(),
              ),
            ),
          ],
          data: (items) {
            if (items.isEmpty) return <Widget>[];
            return [
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'Your Insights'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InsightFeedCard(
                      item: item,
                      onDismiss: item.dismissible
                          ? () => ref
                              .read(insightDismissalsProvider.notifier)
                              .dismiss(item.id)
                          : null,
                    );
                  },
                ),
              ),
            ];
          },
          error: (_, __) => <Widget>[],
        ),
```

- [ ] **Step 6: Refresh all feed sources**

In `_onRefresh`, add invalidations:

```dart
    ref.invalidate(insightFeedProvider);
    ref.invalidate(dashboardInsightFeedProvider);
```

The full `_onRefresh` should be:

```dart
  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(budgetListProvider.notifier).load(),
      ref.read(transactionListProvider.notifier).refresh(),
    ]);
    ref.invalidate(behavioralInsightsProvider);
    ref.invalidate(insightFeedProvider);
    ref.invalidate(dashboardInsightFeedProvider);
  }
```

- [ ] **Step 7: Run dashboard tests**

Run:

```powershell
Set-Location app
flutter test test/screens/dashboard/dashboard_alerts_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit Task 4**

Run:

```powershell
git add app/lib/screens/dashboard/dashboard_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat: show dynamic insight feed on dashboard"
```

Expected: commit succeeds.

---

### Task 5: Expand Insights Screen Into Dynamic Sections

**Files:**
- Modify: `app/lib/screens/insights/insights_screen.dart`
- Test: `app/test/screens/insights/insights_screen_test.dart`

- [ ] **Step 1: Write failing Insights screen tests**

Add imports to `app/test/screens/insights/insights_screen_test.dart`:

```dart
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
```

Add this test:

```dart
  testWidgets('insights screen renders dynamic sections from the feed',
      (tester) async {
    final summary = InsightsSummary(
      regrettedAmount: 1890,
      regrettedCategory: 'Shopping',
      avgRegretRate: 0.44,
      patternCount: 3,
      updatedAt: DateTime(2026, 5, 8),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'PHP', locale: 'en_PH'),
          ),
          behavioralInsightsProvider.overrideWith(
            (ref) async => const BehavioralInsights(
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
              ],
            ),
          ),
          insightsSummaryProvider.overrideWith((ref) async => summary),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Budget trends'), findsOneWidget);
    expect(find.text('Regret patterns'), findsOneWidget);
    expect(find.text('Recent signals'), findsOneWidget);
    expect(find.text('Subscriptions has enough activity for a budget'), findsOneWidget);
    expect(find.text('Shopping is getting more impulsive'), findsOneWidget);
    expect(find.text('Regret Patterns'), findsNothing);
  });
```

- [ ] **Step 2: Run Insights tests to verify they fail**

Run:

```powershell
Set-Location app
flutter test test/screens/insights/insights_screen_test.dart
```

Expected: FAIL because the screen still renders the regret-only layout.

- [ ] **Step 3: Update Insights screen imports**

In `app/lib/screens/insights/insights_screen.dart`, add:

```dart
import '../../models/insight_feed_item.dart';
import '../../providers/insight_feed_provider.dart';
import '../dashboard/widgets/insight_feed_card.dart';
```

- [ ] **Step 4: Replace top-level build logic**

In `InsightsScreen.build`, keep existing watches for summary, merchants, categories, and prefs, then add:

```dart
    final feedSectionsAsync = ref.watch(insightFeedBySectionProvider);
```

Change the scaffold app bar from:

```dart
      appBar: AppBar(title: const Text('Regret Patterns')),
```

to:

```dart
      appBar: AppBar(title: const Text('Insights')),
```

Replace the `child: summaryAsync.when(...)` block with:

```dart
      child: feedSectionsAsync.when(
        loading: () => const _CenteredState(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const _InsightMessageCard(
          icon: Icons.auto_graph_rounded,
          title: 'Insights are taking a minute',
          body: 'We could not load your patterns just now.',
        ),
        data: (sections) {
          final hasAnyInsight = sections.values.any((items) => items.isNotEmpty) ||
              summaryAsync.valueOrNull != null;

          if (!hasAnyInsight) {
            return const _InsightMessageCard(
              icon: Icons.timeline_rounded,
              title: 'Patterns show up after a little history',
              body:
                  'Check back after your first week of tracking and Conscia will start surfacing your spending patterns.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InsightFeedSection(
                title: 'This week',
                subtitle: 'The freshest read on how your money decisions feel.',
                items: sections[InsightFeedSection.thisWeek] ?? const [],
              ),
              _InsightFeedSection(
                title: 'Budget trends',
                subtitle: 'Where spending is pacing high or ready for a budget.',
                items: sections[InsightFeedSection.budgetTrends] ?? const [],
              ),
              if (summaryAsync.valueOrNull != null) ...[
                _SummaryCard(
                  summary: summaryAsync.valueOrNull!,
                  currencyCode: prefs.currency,
                  locale: prefs.locale,
                ),
                const SizedBox(height: 26),
              ],
              _InsightFeedSection(
                title: 'Regret patterns',
                subtitle: 'The repeat signals worth noticing before the next purchase.',
                items: sections[InsightFeedSection.regretPatterns] ?? const [],
              ),
              ScreenSection(
                title: 'Merchant spotlight',
                subtitle:
                    'The place most likely to nudge you into a purchase you later rethink.',
                child: merchantsAsync.when(
                  loading: () => const _InlineLoader(),
                  error: (_, __) => const _SectionFallbackCard(
                    message: 'Merchant trends are unavailable right now.',
                  ),
                  data: (merchants) {
                    if (merchants.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return MerchantSpotlightCard(merchant: merchants.first);
                  },
                ),
              ),
              ScreenSection(
                title: 'Category trend',
                subtitle:
                    'Where your regret spend is stacking up fastest right now.',
                child: categoriesAsync.when(
                  loading: () => const _InlineLoader(),
                  error: (_, __) => const _SectionFallbackCard(
                    message: 'Category trends are unavailable right now.',
                  ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return CategoryTrendCard(
                      category: categories.first,
                      currencyCode: prefs.currency,
                      locale: prefs.locale,
                    );
                  },
                ),
              ),
              _InsightFeedSection(
                title: 'Recent signals',
                subtitle: 'Small changes that may deserve a pause.',
                items: sections[InsightFeedSection.recentSignals] ?? const [],
              ),
            ],
          );
        },
      ),
```

- [ ] **Step 5: Add reusable feed section widget**

Add below `InsightsScreen`:

```dart
class _InsightFeedSection extends StatelessWidget {
  const _InsightFeedSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<InsightFeedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ScreenSection(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          for (final item in items) ...[
            InsightFeedCard(item: item),
            if (item != items.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run Insights tests**

Run:

```powershell
Set-Location app
flutter test test/screens/insights/insights_screen_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

Run:

```powershell
git add app/lib/screens/insights/insights_screen.dart app/test/screens/insights/insights_screen_test.dart
git commit -m "feat: expand insights screen into dynamic sections"
```

Expected: commit succeeds.

---

### Task 6: Final Verification and Polish

**Files:**
- Modify only if formatter/lint/test failures require small fixes.

- [ ] **Step 1: Format Flutter code**

Run:

```powershell
Set-Location app
dart format lib test/core/insights test/providers test/screens/dashboard test/screens/insights
```

Expected: formatter completes and reports changed files if any.

- [ ] **Step 2: Run focused tests**

Run:

```powershell
Set-Location app
flutter test test/core/insights/insight_feed_builder_test.dart test/providers/insight_feed_provider_test.dart test/screens/dashboard/dashboard_alerts_test.dart test/screens/insights/insights_screen_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run analyzer**

Run:

```powershell
Set-Location app
flutter analyze
```

Expected: no new errors. Existing warnings may be noted separately, but do not ignore new errors introduced by this branch.

- [ ] **Step 4: Inspect git diff**

Run:

```powershell
git diff --stat
git diff -- app/lib/models/insight_feed_item.dart app/lib/core/insights/insight_feed_builder.dart app/lib/providers/insight_feed_provider.dart app/lib/screens/dashboard/dashboard_screen.dart app/lib/screens/insights/insights_screen.dart
```

Expected: diff contains only dynamic insight feed changes and no unrelated reversions.

- [ ] **Step 5: Commit final polish if needed**

If formatting or small fixes changed files, run:

```powershell
git add app
git commit -m "chore: polish dynamic insights feed"
```

Expected: commit succeeds, or skip this step if no files changed.

---

## Self-Review

- Spec coverage: The plan implements a curated dashboard feed, max three cards, SharedPreferences dismissal, stable IDs, dashboard hiding when no cards remain, broader Insights screen sections, mascot-backed cards, routing to existing Insights routes, and story-demo-compatible seeded signals through existing providers.
- Backend scope: The plan intentionally avoids a persisted backend `InsightCard` table. It composes from current `/insights/behavioral`, `/insights/summary`, `/insights/categories`, and `/insights/merchants` responses.
- Known tradeoff: Dismissed card IDs are local-device only. This matches the approved first pass and avoids server-side dismissal state until we know users need cross-device dismissal.
- Test coverage: Pure builder tests cover ranking and mascot choice; provider tests cover dismissal persistence; widget tests cover dashboard rendering/dismissal and Insights sections.
