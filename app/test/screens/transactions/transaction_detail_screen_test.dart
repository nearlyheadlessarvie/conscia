import 'dart:async';

import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/ai_provider.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/screens/transactions/transaction_detail_screen.dart';
import 'package:conscia_app/screens/assistant/widgets/ai_message_bubble.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/ai_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/editorial_sticky_header.dart';
import 'package:conscia_app/widgets/feeling_choice_button.dart';
import 'package:conscia_app/widgets/thinking_cloud.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTransactionService extends TransactionService {
  _RecordingTransactionService() : super(Dio());

  String? deletedId;

  @override
  Future<void> delete(String id) async {
    deletedId = id;
  }

  @override
  Future<void> updateRegret(String id, int regretLevel) async {}
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

class _RecordingBudgetService extends BudgetService {
  _RecordingBudgetService() : super(Dio());

  CreateBudgetDto? lastCreated;

  @override
  Future<List<Budget>> list() async => const [];

  @override
  Future<Budget> create(CreateBudgetDto dto) async {
    lastCreated = dto;
    return Budget(
      id: 'budget-${dto.category.toLowerCase()}',
      category: dto.category,
      monthlyLimit: dto.monthlyLimit,
      spent: 0,
      currencyCode: dto.currencyCode,
      percentage: 0,
      isOverBudget: false,
    );
  }
}

class _DelayedReflectionAIService extends AIService {
  _DelayedReflectionAIService() : super(Dio());

  @override
  Future<AIResponse> reflection({required String transactionId}) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    return const AIResponse(
      impulse: 'Impulse',
      reason: 'Reason',
      neutral: 'Reflection',
    );
  }
}

class _ImmediateReflectionAIService extends AIService {
  _ImmediateReflectionAIService() : super(Dio());

  @override
  Future<AIResponse> reflection({required String transactionId}) async {
    return const AIResponse(
      impulse: 'Treat it like a reward.',
      reason: 'Pause and compare it with your goals.',
      neutral: 'This purchase may be part of a pattern worth noticing.',
    );
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('detail screen falls back to Unknown when description is empty', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-2',
      amount: 250,
      currencyCode: 'PHP',
      category: 'Dining',
      description: '',
      type: 'expense',
      date: DateTime(2026, 5, 7, 19, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('detail screen uses editorial hero and open metadata',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-editorial',
      amount: 350,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Jollibee Cubao',
      type: 'expense',
      date: DateTime(2026, 5, 7, 19, 0),
      regretLevel: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-editorial'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jollibee Cubao'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(EditorialStickyHeader), findsOneWidget);
    final hero = find.byKey(const ValueKey('transaction-detail-hero'));
    expect(hero, findsOneWidget);
    expect(tester.getTopLeft(hero).dx, 0);
    expect(tester.getTopLeft(find.text('DETAILS')).dx, 20);
    final header = find.byKey(
      const ValueKey('editorial-sticky-header-Transaction'),
    );
    final heroLabelGap = tester.getTopLeft(find.text('PURCHASE SNAPSHOT')).dy -
        tester.getBottomLeft(header).dy;
    expect(heroLabelGap, lessThanOrEqualTo(28));
    expect(find.text('PURCHASE SNAPSHOT'), findsOneWidget);
    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('HOW DID THIS FEEL?'), findsOneWidget);
    expect(find.text('Reflect'), findsOneWidget);
    expect(find.text('Reflect with Conscia'), findsNothing);
  });

  testWidgets('detail loading skeleton uses the same bleed hero shape',
      (tester) async {
    final pendingTransaction = Completer<Transaction>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) => pendingTransaction.future),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-loading'),
        ),
      ),
    );

    await tester.pump();

    final skeletonHero =
        find.byKey(const ValueKey('transaction-detail-hero-skeleton'));
    expect(skeletonHero, findsOneWidget);
    expect(tester.getTopLeft(skeletonHero).dx, 0);

    pendingTransaction.complete(
      Transaction(
        id: 'tx-loading',
        amount: 300,
        currencyCode: 'PHP',
        category: 'Subscriptions',
        description: 'OpenAI',
        type: 'expense',
        date: DateTime(2026, 5, 9),
      ),
    );
  });

  testWidgets('detail screen labels income hero as income snapshot',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-income-snapshot',
      amount: 45000,
      currencyCode: 'PHP',
      category: 'Salary',
      description: 'Employer',
      type: 'income',
      date: DateTime(2026, 5, 10, 15, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-income-snapshot'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('INCOME SNAPSHOT'), findsOneWidget);
    expect(find.text('PURCHASE SNAPSHOT'), findsNothing);
    expect(find.text('Reflect'), findsNothing);
    expect(find.text('HOW DID THIS FEEL?'), findsNothing);
  });

  testWidgets('detail regret picker uses large shared feeling buttons',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-unreflected',
      amount: 280,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Starbucks',
      type: 'expense',
      date: DateTime(2026, 5, 11, 15, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-unreflected'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HOW DID THIS FEEL?'), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_alt_outlined), findsOneWidget);
    expect(find.text('Worth It'), findsOneWidget);
    expect(find.text('Not Sure'), findsOneWidget);
    expect(find.text('Regret'), findsOneWidget);

    for (final label in ['Worth It', 'Not Sure', 'Regret']) {
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.style?.minimumSize?.resolve({})?.height, 72);
    }
  });

  testWidgets('selected detail feeling shrinks to a compact changeable button',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-reflected',
      amount: 280,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Starbucks',
      type: 'expense',
      date: DateTime(2026, 5, 11, 15, 12),
      regretLevel: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-reflected'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final selectedButton = tester.widget<FeelingChoiceButton>(
      find.byType(FeelingChoiceButton),
    );
    expect(selectedButton.size, FeelingChoiceButtonSize.compact);
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    expect(find.text('Worth It'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('detail header starts transparent and docks after scrolling',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-scroll-header',
      amount: 280,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Starbucks',
      type: 'expense',
      date: DateTime(2026, 5, 11, 15, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-scroll-header'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    Color headerColor() {
      final header = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('editorial-sticky-header-Transaction')),
      );
      return (header.decoration! as BoxDecoration).color!;
    }

    expect(headerColor(), Colors.transparent);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -160),
    );
    await tester.pump(const Duration(milliseconds: 220));

    expect(headerColor(), isNot(Colors.transparent));
  });

  testWidgets('detail screen shows edited transaction returned from edit route',
      (
    tester,
  ) async {
    final originalTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Watami',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final updatedTransaction = Transaction(
      id: 'tx-1',
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Ippudo',
      type: 'expense',
      date: DateTime(2026, 5, 7, 13, 25),
    );

    final router = GoRouter(
      initialLocation: '/transactions/tx-1',
      routes: [
        GoRoute(
          path: '/transactions/:id',
          builder: (_, state) => TransactionDetailScreen(
            transactionId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(updatedTransaction),
                    child: const Text('Return updated'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith(
            (ref, id) async => originalTransaction,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Watami'), findsOneWidget);

    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return updated'));
    await tester.pumpAndSettle();

    expect(find.text('Ippudo'), findsOneWidget);
    expect(find.text('Watami'), findsNothing);
  });

  testWidgets('detail screen delete updates local budget usage immediately', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-1',
      amount: 12.5,
      currencyCode: 'USD',
      category: 'Coffee',
      description: 'Morning Brew',
      type: 'expense',
      date: DateTime(2026, 5, 7, 9, 0),
    );
    final transactionService = _RecordingTransactionService();

    final container = ProviderContainer(
      overrides: [
        budgetListProvider.overrideWith(
          (ref) => BudgetListNotifier(
            _StaticBudgetService(const [
              Budget(
                id: 'budget-1',
                category: 'Coffee',
                monthlyLimit: 100,
                spent: 32.5,
                currencyCode: 'USD',
                percentage: 0.325,
                isOverBudget: false,
              ),
            ]),
          ),
        ),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
        transactionServiceProvider.overrideWithValue(transactionService),
        transactionDetailProvider.overrideWith((ref, id) async => transaction),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/transactions/tx-1',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('Root')),
                routes: [
                  GoRoute(
                    path: 'transactions/:id',
                    builder: (_, state) => TransactionDetailScreen(
                      transactionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete transaction'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 20);
    expect(updatedBudget.percentage, 0.2);
    expect(transactionService.deletedId, 'tx-1');
  });

  testWidgets('detail screen does not render matching in-app alerts',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-9',
      amount: 1500,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Late Night Delivery',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
      regretLevel: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => [
                AppAlert(
                  id: 'reflection-follow-up-tx-9',
                  type: 'ReflectionFollowUp',
                  title: 'This purchase still deserves a second look',
                  message: 'A reflection can help you spot the pattern.',
                  priority: 40,
                  actionLabel: 'Reflect now',
                  transactionId: 'tx-9',
                  isDismissed: false,
                  createdAt: DateTime.utc(2026, 5, 8),
                ),
              ]),
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-9'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
        find.text('This purchase still deserves a second look'), findsNothing);
    expect(find.text('Reflect now'), findsNothing);
  });

  testWidgets('detail screen keeps recurring alerts out of the detail page',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-recurring-alert',
      amount: 3500,
      currencyCode: 'PHP',
      category: 'Salary',
      description: 'Freelance Client',
      type: 'income',
      date: DateTime(2026, 5, 8, 11, 12),
      recurringScheduleId: 'schedule-1',
      recurringOccurrenceDate: DateTime(2026, 5, 8),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => [
                AppAlert(
                  id: 'recurring-alert-tx-recurring-alert',
                  type: 'recurring_transaction_created',
                  title: 'Recurring income added',
                  message: 'Freelance Client was added automatically.',
                  priority: 30,
                  actionLabel: 'View transaction',
                  actionRoute: '/transactions/tx-recurring-alert',
                  transactionId: 'tx-recurring-alert',
                  isDismissed: false,
                  createdAt: DateTime.utc(2026, 5, 8),
                ),
              ]),
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-recurring-alert'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recurring income added'), findsNothing);
    expect(find.text('View transaction'), findsNothing);
  });

  testWidgets('detail hero opens create budget form for unbudgeted expenses',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-unbudgeted',
      amount: 499,
      currencyCode: 'PHP',
      category: 'Subscriptions',
      description: 'OpenAI',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
    );
    final budgetService = _RecordingBudgetService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetListProvider.overrideWith(
            (ref) => BudgetListNotifier(budgetService),
          ),
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'budget@example.com',
              currencyCode: 'PHP',
              locale: 'en_PH',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-unbudgeted'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No budget for Subscriptions yet'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Add Budget'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add Budget'));
    await tester.pumpAndSettle();

    expect(find.text('New Budget'), findsOneWidget);
    expect(find.text('Subscriptions'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows thinking cloud while reflection is loading',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-reflect',
      amount: 320,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Coffee',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
    );

    final transactionService = _RecordingTransactionService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
          aiServiceProvider.overrideWithValue(_DelayedReflectionAIService()),
          transactionServiceProvider.overrideWithValue(transactionService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-reflect'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reflect'));
    await tester.tap(find.text('Reflect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ThinkingCloudWidget), findsOneWidget);
    expect(find.text('Reflection is making sense of the moment...'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-reflection')),
        findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('reflection result uses shared guidance chat messages',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-reflect-chat',
      amount: 1500,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Fridays',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
          aiServiceProvider.overrideWithValue(_ImmediateReflectionAIService()),
          transactionServiceProvider
              .overrideWithValue(_RecordingTransactionService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'story@example.com',
              currencyCode: 'PHP',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-reflect-chat'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reflect'));
    await tester.tap(find.text('Reflect'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('reflection-user-message')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reflection-devil-message')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reflection-angel-message')), findsOneWidget);
    expect(find.byKey(const ValueKey('reflection-conscia-message')),
        findsOneWidget);
    final expectedAmount = CurrencyFormatter.format(
      transaction.amount.abs(),
      currencyCode: transaction.currencyCode,
    );
    expect(find.text('Help me reflect on $expectedAmount at Fridays.'),
        findsOneWidget);
    expect(find.byType(AiMessageBubble), findsNothing);
  });

  testWidgets('detail screen shows recurring provenance hint', (tester) async {
    final transaction = Transaction(
      id: 'tx-recurring',
      amount: 499,
      currencyCode: 'PHP',
      category: 'Subscriptions',
      description: 'Netflix',
      type: 'expense',
      date: DateTime(2026, 5, 31),
      recurringScheduleId: 'schedule-1',
      recurringOccurrenceDate: DateTime(2026, 5, 31),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-recurring'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recurring transaction'), findsOneWidget);
  });

  testWidgets('detail screen shows family context without redundant badge', (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-family-detail',
      amount: 2460,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Manam',
      type: 'expense',
      date: DateTime(2026, 5, 3),
      scope: 'family',
      familySpaceId: 'family-1',
      sharedByUserId: 'spouse-user-id',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                userId: 'current-user-id',
              ),
            ),
          ),
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: 'tx-family-detail'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Family transaction'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('family-transaction-badge')), findsNothing);
    expect(find.byKey(const ValueKey('transaction-sharer-avatar')),
        findsOneWidget);
  });

  testWidgets(
      'detail screen shows one shared context row for recurring family transaction',
      (
    tester,
  ) async {
    final transaction = Transaction(
      id: 'tx-family-recurring-detail',
      amount: 4200,
      currencyCode: 'PHP',
      category: 'Family Groceries',
      description: 'Landers',
      type: 'expense',
      date: DateTime(2026, 5, 3),
      scope: 'family',
      familySpaceId: 'family-1',
      recurringScheduleId: 'schedule-1',
      recurringOccurrenceDate: DateTime(2026, 5, 3),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(
            transactionId: 'tx-family-recurring-detail',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Shared context'), findsOneWidget);
    expect(find.text('Recurring family transaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('recurring-transaction-badge')),
        findsNothing);
    expect(
        find.byKey(const ValueKey('family-transaction-badge')), findsNothing);
  });

  testWidgets(
      'auto reflect entry suppresses follow-up banner and opens reflection flow',
      (tester) async {
    final transaction = Transaction(
      id: 'tx-auto',
      amount: 1500,
      currencyCode: 'PHP',
      category: 'Dining',
      description: 'Late Night Delivery',
      type: 'expense',
      date: DateTime(2026, 5, 7, 21, 0),
      regretLevel: 2,
    );

    final transactionService = _RecordingTransactionService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => [
                AppAlert(
                  id: 'reflection-follow-up-tx-auto',
                  type: 'ReflectionFollowUp',
                  title: 'This purchase still deserves a second look',
                  message: 'A reflection can help you spot the pattern.',
                  priority: 40,
                  actionLabel: 'Reflect now',
                  transactionId: 'tx-auto',
                  isDismissed: false,
                  createdAt: DateTime.utc(2026, 5, 8),
                ),
              ]),
          transactionDetailProvider
              .overrideWith((ref, id) async => transaction),
          aiServiceProvider.overrideWithValue(_DelayedReflectionAIService()),
          transactionServiceProvider.overrideWithValue(transactionService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(
            transactionId: 'tx-auto',
            autoReflect: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reflect now'), findsNothing);
    expect(find.byType(ThinkingCloudWidget), findsOneWidget);
    expect(find.text('Reflection is making sense of the moment...'),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(AuthService(Dio()), _FakeSecureStorage()) {
    state = initialState;
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return null;
  }
}
