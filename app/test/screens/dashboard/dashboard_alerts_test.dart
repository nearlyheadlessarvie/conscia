import 'package:conscia_app/models/insight_feed_item.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/behavioral_insights_provider.dart';
import 'package:conscia_app/models/behavioral_insights.dart';
import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/providers/insight_feed_provider.dart';
import 'package:conscia_app/providers/insights_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/core/routing/app_router.dart';
import 'package:conscia_app/screens/dashboard/dashboard_screen.dart';
import 'package:conscia_app/screens/dashboard/widgets/insight_feed_card.dart';
import 'package:conscia_app/screens/dashboard/widgets/recent_transaction_tile.dart';
import 'package:conscia_app/screens/dashboard/widgets/regret_prompt_card.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/skeleton_loader.dart';
import 'package:conscia_app/widgets/main_shell.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

class _StaticTransactionService extends TransactionService {
  _StaticTransactionService([this.transactions = const []]) : super(Dio());

  final List<Transaction> transactions;

  @override
  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
  }) async {
    return PaginatedTransactions(
      items: transactions,
      totalCount: transactions.length,
      page: 1,
      pageSize: 20,
      hasMore: false,
    );
  }
}

class _StaticConscienceJourneyService extends ConscienceJourneyService {
  _StaticConscienceJourneyService() : super(Dio());

  @override
  Future<ConscienceJourneySummary> fetchJourney() async => _testJourneySummary;
}

class _PendingConscienceJourneyService extends ConscienceJourneyService {
  _PendingConscienceJourneyService() : super(Dio());

  @override
  Future<ConscienceJourneySummary> fetchJourney() =>
      Completer<ConscienceJourneySummary>().future;
}

class _LocalAlertsTestNotifier extends LocalAlertsNotifier {
  _LocalAlertsTestNotifier(List<AppAlert> alerts) : super() {
    state = alerts;
  }
}

final _testUser = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Arvie Aguirre',
  currencyCode: 'PHP',
  locale: 'en_PH',
  createdAt: DateTime.utc(2026, 5, 1),
  hasCompletedOnboarding: true,
);

const _testSubscription = SubscriptionStatus(
  tier: 'free',
  isPremium: false,
);

const _testJourneySummary = ConscienceJourneySummary(
  xpTotal: 0,
  currentLevel: ConscienceLevel(
    key: 'awakening',
    title: 'Awakening',
    requiredXp: 0,
  ),
  nextLevel: ConscienceLevel(
    key: 'impulse_spotter',
    title: 'Impulse Spotter',
    requiredXp: 120,
  ),
  xpIntoLevel: 0,
  xpToNextLevel: 120,
  momentumDays: 0,
  bestMomentumDays: 0,
  weeklyQuests: [],
  badges: [],
);

final _testJourneyService = _StaticConscienceJourneyService();

Widget _buildApp(
  ProviderContainer container, {
  ConscienceJourneyService? journeyService,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: DashboardScreen()),
      ),
      GoRoute(
        path: '/settings/budgets',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Budgets placeholder')),
        ),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Insights placeholder')),
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('detail:${state.uri.toString()}'),
          ),
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: ProviderScope(
      overrides: [
        conscienceJourneyServiceProvider
            .overrideWithValue(journeyService ?? _testJourneyService),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

Widget _buildNestedShellApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: ProviderScope(
      overrides: [
        conscienceJourneyServiceProvider.overrideWithValue(_testJourneyService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const DashboardScreen(),
            ),
          ),
          bottomNavigationBar: const SizedBox(
            height: 72,
            child: Center(child: Text('Shell nav')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('recent transaction tile displays counterparty text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentTransactionTile(
            id: 'tx-1',
            categoryBadge: const Icon(Icons.restaurant),
            counterparty: 'Corner Bakery',
            category: 'Dining',
            date: DateTime(2026, 5, 7),
            amount: 12.5,
            isIncome: false,
            currencyCode: 'USD',
          ),
        ),
      ),
    );

    expect(find.text('Corner Bakery'), findsOneWidget);
  });

  testWidgets('dashboard recent transactions use shared icon-only status tags',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionListProvider.overrideWith(
          (ref) => TransactionListNotifier.fromList([
            Transaction(
              id: 'tx-shared-recurring-regret',
              amount: 280,
              currencyCode: 'PHP',
              category: 'Family Dining',
              description: 'Starbucks',
              type: 'expense',
              date: DateTime(2026, 5, 11),
              scope: 'family',
              familySpaceId: 'family-1',
              recurringScheduleId: 'schedule-1',
              recurringOccurrenceDate: DateTime(2026, 5, 11),
              regretLevel: 1,
            ),
            for (var index = 0; index < 8; index++)
              Transaction(
                id: 'tx-filler-$index',
                amount: 100 + index.toDouble(),
                currencyCode: 'PHP',
                category: 'Bills',
                description: 'Filler $index',
                type: 'expense',
                date: DateTime(2026, 5, 10).subtract(Duration(days: index)),
              ),
          ]),
        ),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        currentUserProvider.overrideWith((ref) async => _testUser),
        subscriptionProvider.overrideWith((ref) async => _testSubscription),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Starbucks'), findsOneWidget);
    expect(find.byType(RecentTransactionTile), findsAtLeastNWidgets(5));
    expect(find.text('Family Dining'), findsNothing);
    expect(find.text('Dining'), findsWidgets);
    expect(
      find.byKey(const ValueKey('family-transaction-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recurring-transaction-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('regret-transaction-badge')),
      findsOneWidget,
    );
  });

  testWidgets('regret prompt card displays counterparty text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegretPromptCard(
            categoryBadge: const Icon(Icons.restaurant),
            counterparty: 'Corner Bakery',
            amount: 12.5,
            currencyCode: 'USD',
            date: DateTime(2026, 5, 7),
          ),
        ),
      ),
    );

    expect(find.text('Corner Bakery'), findsOneWidget);
  });

  testWidgets(
      'insight feed card displays content without forced dismiss action',
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
    expect(find.byTooltip('Dismiss insight'), findsNothing);
    expect(dismissed, isFalse);
  });

  testWidgets('dashboard header stays visible while scrolling', (tester) async {
    final transactions = List.generate(
      12,
      (index) => Transaction(
        id: 'tx-$index',
        amount: 25 + index.toDouble(),
        currencyCode: 'USD',
        category: 'Dining',
        description: 'Transaction $index',
        type: 'expense',
        date: DateTime(2026, 5, 7).subtract(Duration(days: index)),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
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

    final headerFinder =
        find.byKey(const ValueKey('dashboard-sticky-identity-header'));
    expect(headerFinder, findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(headerFinder.hitTestable(), findsOneWidget);
  });

  testWidgets('dashboard header syncs with restored scroll position',
      (tester) async {
    final transactions = List.generate(
      12,
      (index) => Transaction(
        id: 'tx-restore-$index',
        amount: 25 + index.toDouble(),
        currencyCode: 'USD',
        category: 'Dining',
        description: 'Transaction $index',
        type: 'expense',
        date: DateTime(2026, 5, 7).subtract(Duration(days: index)),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final bucket = PageStorageBucket();

    Widget appWithDashboard() {
      return UncontrolledProviderScope(
        container: container,
        child: ProviderScope(
          overrides: [
            conscienceJourneyServiceProvider.overrideWithValue(
              _testJourneyService,
            ),
          ],
          child: MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: const Scaffold(body: DashboardScreen()),
            ),
          ),
        ),
      );
    }

    Color headerColor() {
      final header = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('dashboard-sticky-identity-header')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (header.decoration! as BoxDecoration).color!;
    }

    int headerAlpha() => (headerColor().a * 255).round().clamp(0, 255);

    await tester.pumpWidget(appWithDashboard());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final scrolledHeaderAlpha = headerAlpha();
    expect(scrolledHeaderAlpha, greaterThan(0));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(appWithDashboard());
    await tester.pump();

    expect(headerAlpha(), scrolledHeaderAlpha);
  });

  testWidgets('dashboard header syncs after returning through shell navigation',
      (tester) async {
    final transactions = List.generate(
      12,
      (index) => Transaction(
        id: 'tx-shell-restore-$index',
        amount: 25 + index.toDouble(),
        currencyCode: 'USD',
        category: 'Dining',
        description: 'Transaction $index',
        type: 'expense',
        date: DateTime(2026, 5, 7).subtract(Duration(days: index)),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService(transactions),
        ),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    Color headerColor() {
      final header = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('dashboard-sticky-identity-header')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (header.decoration! as BoxDecoration).color!;
    }

    int headerAlpha() => (headerColor().a * 255).round().clamp(0, 255);

    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/transactions',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Transactions tab'))),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ProviderScope(
          overrides: [
            conscienceJourneyServiceProvider.overrideWithValue(
              _testJourneyService,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final scrolledHeaderAlpha = headerAlpha();
    expect(scrolledHeaderAlpha, greaterThan(0));

    router.go('/transactions');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-sticky-identity-header')),
        findsOneWidget);
    expect(headerAlpha(), scrolledHeaderAlpha);
  });

  testWidgets('dashboard uses editorial hero and grouped recent activity',
      (tester) async {
    final transactions = List.generate(
      3,
      (index) => Transaction(
        id: 'tx-grouped-$index',
        amount: 100 + index.toDouble(),
        currencyCode: 'PHP',
        category: 'Dining',
        description: 'Transaction $index',
        type: 'expense',
        date: DateTime(2026, 5, 7).subtract(Duration(days: index)),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService(transactions)),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.notifier).refresh();

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-editorial-hero')),
      findsOneWidget,
    );
  });

  testWidgets('dashboard shows editorial hero before utility sections',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Dining',
              monthlyLimit: 5000,
              spent: 2400,
              currencyCode: 'PHP',
              percentage: 0.48,
              isOverBudget: false,
            ),
          ]),
        ),
        transactionServiceProvider.overrideWithValue(
          _StaticTransactionService([
            Transaction(
              id: 'tx-1',
              amount: 350,
              currencyCode: 'PHP',
              category: 'Dining',
              description: 'Starbucks',
              type: 'expense',
              date: DateTime(2026, 5, 10),
            ),
          ]),
        ),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
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

    final hero = find.byKey(const ValueKey('dashboard-editorial-hero'));
    final budgets = find.text('BUDGETS');

    expect(hero, findsOneWidget);
    expect(budgets, findsOneWidget);
    expect(tester.getTopLeft(hero).dy, lessThan(tester.getTopLeft(budgets).dy));
  });

  testWidgets('dashboard uses a personal welcome header', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
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

    expect(find.byKey(const ValueKey('dashboard-sticky-identity-header')),
        findsOneWidget);
    expect(find.byTooltip('Notifications'), findsWidgets);
  });

  testWidgets('dashboard does not render in-feed alert banners',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Dining',
              monthlyLimit: 500,
              spent: 450,
              currencyCode: 'PHP',
              percentage: 0.9,
              isOverBudget: false,
            ),
          ]),
        ),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        currentUserProvider.overrideWith((ref) async => _testUser),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'reflection-follow-up-tx-1',
                type: 'ReflectionFollowUp',
                title: 'This purchase still deserves a second look',
                message:
                    'A reflection can help you spot what was really going on.',
                priority: 50,
                actionLabel: 'Reflect now',
                actionRoute: AppRoutes.transactionDetail('tx-1'),
                transactionId: 'tx-1',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 9),
              ),
            ]),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message:
                    'You logged an expense in Dining without a matching budget.',
                category: 'Dining',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsNothing);
    expect(
        find.text('This purchase still deserves a second look'), findsNothing);
  });

  testWidgets('dashboard insight loading state matches summary card shape',
      (tester) async {
    final pendingSummary = Completer<DashboardInsightSummary?>();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        dashboardInsightSummaryProvider.overrideWith(
          (ref) => pendingSummary.future,
        ),
        alertsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildApp(
        container,
        journeyService: _PendingConscienceJourneyService(),
      ),
    );
    await tester.pump();

    expect(
        find.byKey(const ValueKey('dashboard-hero-skeleton')), findsOneWidget);
    expect(find.byType(InsightSkeletonCard), findsNothing);
  });

  testWidgets(
      'dashboard summarizes budget trends when behavioral insights include trends',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider
            .overrideWith((ref) async => const BehavioralInsights(
                  mood: FinancialMood.balanced,
                  worthItPercentage: 72,
                  worthItCount: 9,
                  previousMonthWorthItCount: 7,
                  impulseeTrends: [],
                  budgetTrends: [
                    BudgetTrendInsight(
                      category: 'Dining',
                      hasBudget: true,
                      currencyCode: 'PHP',
                      months: [50, 60, 75],
                      currentMonthSpend: 750,
                      currentMonthPercentUsed: 75,
                      insightLabel: 'Budget usage trending up',
                    ),
                    BudgetTrendInsight(
                      category: 'Subscriptions',
                      hasBudget: false,
                      currencyCode: 'PHP',
                      months: [100, 120, 140],
                      currentMonthSpend: 140,
                      insightLabel: 'Spending trending up',
                      nudge: 'Add a budget for sharper insights',
                    ),
                  ],
                )),
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

    expect(
        find.byKey(const ValueKey('dashboard-editorial-hero')), findsOneWidget);
    expect(
      find.text('Dining is above your recent 3-month pace.'),
      findsOneWidget,
    );
    expect(find.text('Subscriptions has enough activity for a budget'),
        findsNothing);
    expect(find.text('Budget trends'), findsNothing);
  });

  testWidgets('dashboard shows an inferred insight summary in the hero card',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider
            .overrideWith((ref) async => const BehavioralInsights(
                  mood: FinancialMood.confident,
                  worthItPercentage: 90,
                  worthItCount: 9,
                  previousMonthWorthItCount: 3,
                  impulseeTrends: [],
                  budgetTrends: [
                    BudgetTrendInsight(
                      category: 'Dining',
                      hasBudget: true,
                      currencyCode: 'PHP',
                      months: [52, 68, 80],
                      currentMonthSpend: 3200,
                      currentMonthPercentUsed: 80,
                      insightLabel: 'Dining is trending higher',
                    ),
                  ],
                )),
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

    expect(
      find.text('Dining is above your recent 3-month pace.'),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('dashboard-editorial-hero')), findsOneWidget);
    expect(find.text('Your financial mood is confident'), findsNothing);
    expect(find.text('More insights inside'), findsNothing);
    expect(find.byTooltip('Dismiss insight'), findsNothing);
  });

  testWidgets('dashboard notification bell opens active alerts sheet',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'reflection-follow-up-tx-1',
                type: 'ReflectionFollowUp',
                title: 'This purchase still deserves a second look',
                message:
                    'A reflection can help you spot what was really going on.',
                priority: 50,
                actionLabel: 'Reflect now',
                actionRoute: AppRoutes.transactionDetail('tx-1'),
                transactionId: 'tx-1',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 9),
              ),
            ]),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message: 'You logged an expense in Dining without a budget.',
                priority: 20,
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notifications').hitTestable(), findsWidgets);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(
        find.text('This purchase still deserves a second look'), findsWidgets);
    expect(find.text('No budget for Dining yet'), findsOneWidget);
  });

  testWidgets('notification sheet covers the root app shell', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildNestedShellApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Shell nav').hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Shell nav').hitTestable(), findsNothing);
  });

  testWidgets(
      'notification sheet surfaces local budget nudges with a budget CTA',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        currentUserProvider.overrideWith((ref) async => _testUser),
        subscriptionProvider.overrideWith((ref) async => _testSubscription),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message:
                    'You logged an expense in Dining without a matching budget.',
                category: 'Dining',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsNothing);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsOneWidget);
    expect(find.text('Add budget'), findsOneWidget);

    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();

    expect(find.text('New Budget'), findsOneWidget);
    expect(find.text('Budgets placeholder'), findsNothing);

    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();

    final createBudgetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create Budget'),
    );
    expect(createBudgetButton.onPressed, isNotNull);
    expect(container.read(activeAlertsProvider), hasLength(1));
  });

  testWidgets('notification sheet can dismiss a local budget nudge',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message:
                    'You logged an expense in Dining without a matching budget.',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsNothing);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dismiss notification').first);
    await tester.pumpAndSettle();

    expect(find.text('No budget for Dining yet'), findsNothing);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets(
      'matching-budget nudges stay in notifications instead of rendering in the feed',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Gaming',
              monthlyLimit: 500,
              spent: 0,
              currencyCode: 'PHP',
              percentage: 0,
              isOverBudget: false,
            ),
          ]),
        ),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-gaming',
                type: 'budget_nudge',
                title: 'No budget for Gaming yet',
                message:
                    'You logged an expense in Gaming without a matching budget.',
                category: 'Gaming',
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Gaming yet'), findsNothing);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('No budget for Gaming yet'), findsOneWidget);
  });

  testWidgets(
      'notification sheet prioritizes remote regret alerts above local nudges',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'repeated-regret-category-dining',
                type: 'RepeatedRegretCategory',
                title: 'Dining keeps turning into regret',
                message: 'You have marked recent Dining purchases as regret.',
                priority: 70,
                actionLabel: 'See category trend',
                actionRoute: '/insights/categories/Dining',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 8),
              ),
            ]),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(
            [
              AppAlert(
                id: 'budget-nudge-dining',
                type: 'budget_nudge',
                title: 'No budget for Dining yet',
                message: 'You logged an expense in Dining without a budget.',
                priority: 20,
                isDismissed: false,
                createdAt: DateTime(2026, 5, 7),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Dining keeps turning into regret'), findsNothing);
    expect(find.text('No budget for Dining yet'), findsNothing);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('Dining keeps turning into regret'), findsOneWidget);
    expect(find.text('No budget for Dining yet'), findsOneWidget);
  });

  testWidgets(
      'notification sheet reflection alert dismisses and routes to detail with auto reflect',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        transactionServiceProvider
            .overrideWithValue(_StaticTransactionService()),
        behavioralInsightsProvider.overrideWith((ref) async => null),
        insightsSummaryProvider.overrideWith((ref) async => null),
        insightsCategoriesProvider.overrideWith((ref) async => const []),
        insightsMerchantsProvider.overrideWith((ref) async => const []),
        alertsProvider.overrideWith((ref) async => [
              AppAlert(
                id: 'reflection-follow-up-tx-1',
                type: 'ReflectionFollowUp',
                title: 'This purchase still deserves a second look',
                message:
                    'A reflection can help you spot what was really going on.',
                priority: 50,
                actionLabel: 'Reflect now',
                actionRoute: AppRoutes.transactionDetail('tx-1'),
                transactionId: 'tx-1',
                isDismissed: false,
                createdAt: DateTime.utc(2026, 5, 9),
              ),
            ]),
        localAlertsProvider.overrideWith(
          (ref) => _LocalAlertsTestNotifier(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container));
    await tester.pumpAndSettle();

    expect(find.text('Reflect now'), findsNothing);

    await tester.tap(find.byTooltip('Notifications').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reflect now'));
    await tester.pumpAndSettle();

    expect(
        find.text('detail:/transactions/tx-1?autoReflect=1'), findsOneWidget);
    expect(
      container.read(dismissedAlertIdsProvider),
      contains('reflection-follow-up-tx-1'),
    );
  });
}
