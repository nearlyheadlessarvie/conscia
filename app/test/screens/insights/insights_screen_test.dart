import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/insights_models.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/insights_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/insights/category_detail_screen.dart';
import 'package:conscia_app/screens/insights/insights_screen.dart';
import 'package:conscia_app/screens/insights/merchant_detail_screen.dart';
import 'package:conscia_app/screens/insights/widgets/insights_formatting.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [];
}

class _ExistingSubscriptionsBudgetService extends BudgetService {
  _ExistingSubscriptionsBudgetService() : super(Dio());

  @override
  Future<List<Budget>> list() async => const [
        Budget(
          id: 'budget-subscriptions',
          category: 'Subscriptions',
          monthlyLimit: 2500,
          spent: 1140,
          currencyCode: 'PHP',
          percentage: 45.6,
          isOverBudget: false,
        ),
      ];
}

void main() {
  test('insights formatter falls back when locale is invalid', () {
    final formatted = formatInsightCurrency(
      42.5,
      currencyCode: 'USD',
      locale: 'bad_locale',
    );

    expect(
      formatted,
      CurrencyFormatter.format(42.5, currencyCode: 'USD'),
    );
  });

  testWidgets(
      'insights summary uses shared currency formatting instead of hardcoded pound text',
      (tester) async {
    final summary = InsightsSummary(
      regrettedAmount: 600,
      regrettedCategory: 'Dining',
      avgRegretRate: 0.42,
      patternCount: 3,
      updatedAt: DateTime(2026, 5, 8),
    );
    final expected = CurrencyFormatter.format(
      600,
      currencyCode: 'PHP',
      locale: 'en_PH',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'PHP', locale: 'en_PH'),
          ),
          behavioralInsightsProvider.overrideWith((ref) async => null),
          insightsSummaryProvider.overrideWith((ref) async => summary),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('£600'), findsNothing);
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('insights hero appears before the regret pulse', (tester) async {
    final summary = InsightsSummary(
      regrettedAmount: 1890,
      regrettedCategory: 'Shopping',
      avgRegretRate: 0.33,
      patternCount: 4,
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
              impulseeTrends: [],
              budgetTrends: [],
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

    final heroTop = tester
        .getTopLeft(find.byKey(const ValueKey('insights-editorial-hero')))
        .dy;
    final pulseTop = tester.getTopLeft(find.text('YOUR REGRET PULSE')).dy;

    expect(heroTop, lessThan(pulseTop));
    expect(find.text('Your spending story is pointing at Shopping.'),
        findsOneWidget);
    expect(find.text('😇  ⚔️  😈'), findsNothing);
  });

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
          insightsMerchantsProvider.overrideWith(
            (ref) async => const [
              MerchantStat(
                merchant: 'OpenAI',
                visitCount: 3,
                regretCount: 2,
                regretRate: 0.67,
                lastVisitDate: '2026-05-10',
              ),
            ],
          ),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('insights-editorial-hero')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('insights-sticky-header')), findsOneWidget);
    expect(find.text('😇  ⚔️  😈'), findsNothing);
    expect(find.text('BUDGET TRENDS'), findsOneWidget);
    expect(find.text('REGRET PATTERNS'), findsOneWidget);
    expect(find.text('RECENT SIGNALS'), findsOneWidget);
    expect(find.text('Regret patterns'), findsNothing);
    expect(
      find.text('Subscriptions has enough activity for a budget'),
      findsOneWidget,
    );
    expect(find.text('Shopping is getting more impulsive'), findsOneWidget);
    expect(find.text('+ No budget yet'), findsOneWidget);
    expect(find.text('No budget yet'), findsNothing);
    expect(find.byTooltip('Add budget'), findsNothing);
    expect(find.text('View merchant'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

    final staticInsight = find.text('Your financial mood is balanced');
    await Scrollable.ensureVisible(
      tester.element(staticInsight),
      alignment: 0.45,
    );
    await tester.pumpAndSettle();
    await tester.tap(staticInsight);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('static insight cards do not show action or drill-down cues',
      (tester) async {
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
              impulseeTrends: [],
              budgetTrends: [],
            ),
          ),
          insightsSummaryProvider.overrideWith((ref) async => null),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your financial mood is balanced'), findsOneWidget);
    expect(find.text('Add budget'), findsNothing);
    expect(find.text('View pattern'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('unbudgeted budget trend opens create budget with category',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final budgetService = _StaticBudgetService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'PHP', locale: 'en_PH'),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          budgetServiceProvider.overrideWithValue(budgetService),
          budgetListProvider.overrideWith(
            (ref) => BudgetListNotifier(budgetService),
          ),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'insights@example.com',
              currencyCode: 'PHP',
              locale: 'en_PH',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
          behavioralInsightsProvider.overrideWith(
            (ref) async => const BehavioralInsights(
              mood: FinancialMood.balanced,
              worthItPercentage: 71,
              worthItCount: 5,
              previousMonthWorthItCount: 2,
              impulseeTrends: [],
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
          insightsSummaryProvider.overrideWith((ref) async => null),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Subscriptions has enough activity for a budget'),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Budget'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('budget trend nudge disappears once budget exists',
      (tester) async {
    final budgetService = _ExistingSubscriptionsBudgetService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'PHP', locale: 'en_PH'),
          ),
          budgetServiceProvider.overrideWithValue(budgetService),
          budgetListProvider.overrideWith(
            (ref) => BudgetListNotifier(budgetService),
          ),
          behavioralInsightsProvider.overrideWith(
            (ref) async => const BehavioralInsights(
              mood: FinancialMood.balanced,
              worthItPercentage: 71,
              worthItCount: 5,
              previousMonthWorthItCount: 2,
              impulseeTrends: [],
              budgetTrends: [
                BudgetTrendInsight(
                  category: 'Subscriptions',
                  hasBudget: false,
                  currencyCode: 'PHP',
                  months: [820, 980, 1140],
                  currentMonthSpend: 1140,
                  insightLabel: 'Spending trending up',
                  nudge: 'Add a budget for sharper insights',
                ),
              ],
            ),
          ),
          insightsSummaryProvider.overrideWith((ref) async => null),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Budget'), findsNothing);
    expect(find.text('+ No budget yet'), findsNothing);
    expect(
      find.text('Subscriptions has enough activity for a budget'),
      findsNothing,
    );
    expect(find.text('Add a budget for sharper insights'), findsNothing);
  });

  testWidgets('regret summary card drills into the regretted category',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/insights/categories/:category',
          builder: (_, state) => Scaffold(
            body: Text('category:${state.pathParameters['category']}'),
          ),
        ),
      ],
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
              impulseeTrends: [],
              budgetTrends: [],
            ),
          ),
          insightsSummaryProvider.overrideWith(
            (ref) async => InsightsSummary(
              regrettedAmount: 1890,
              regrettedCategory: 'Shopping',
              avgRegretRate: 0.33,
              patternCount: 4,
              updatedAt: DateTime(2026, 5, 8),
            ),
          ),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final regretCard = find.textContaining('regretted on Shopping');
    await Scrollable.ensureVisible(
      tester.element(regretCard),
      alignment: 0.45,
    );
    await tester.pumpAndSettle();
    await tester.tap(regretCard);
    await tester.pumpAndSettle();

    expect(find.text('category:Shopping'), findsOneWidget);
  });

  testWidgets(
      'category detail formats transaction amounts with a locale-safe shared formatter',
      (tester) async {
    final detail = CategoryDetail(
      stats: const CategoryStat(
        category: 'Dining',
        totalSpend: 240,
        regrettedSpend: 120,
        regretRate: 0.5,
        transactionCount: 4,
        projectedAnnual: 1440,
      ),
      recentTransactions: [
        TransactionSummary(
          id: 'tx-1',
          amount: 18.75,
          currencyCode: 'USD',
          category: 'Dining',
          merchant: 'Corner Cafe',
          date: DateTime(2026, 5, 1),
          regretLevel: 'regret',
        ),
      ],
    );
    final expected = CurrencyFormatter.format(18.75, currencyCode: 'USD');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'USD', locale: 'bad_locale'),
          ),
          categoryDetailProvider('Dining').overrideWith((ref) async => detail),
        ],
        child: const MaterialApp(
          home: CategoryDetailScreen(category: 'Dining'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('USD 18.75'), findsNothing);
    expect(find.text(expected), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('merchant detail uses an iOS chevron back control',
      (tester) async {
    const detail = MerchantDetail(
      stats: MerchantStat(
        merchant: 'Corner Cafe',
        visitCount: 3,
        regretCount: 1,
        regretRate: 0.33,
        lastVisitDate: '2026-05-01',
      ),
      recentTransactions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'USD', locale: 'en_US'),
          ),
          merchantDetailProvider('Corner Cafe').overrideWith(
            (ref) async => detail,
          ),
        ],
        child: const MaterialApp(
          home: MerchantDetailScreen(merchant: 'Corner Cafe'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
