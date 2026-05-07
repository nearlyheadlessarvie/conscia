import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';
import 'package:conscia_app/screens/transactions/widgets/voice_input_button.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.suggestions = const (
      nearbyMerchants: ['Blue Bottle Coffee'],
      likelyCategories: ['Coffee'],
    ),
  });

  final bool permissionGranted;
  final ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) suggestions;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() => suggestions;
}

class _RecordingTransactionService extends TransactionService {
  _RecordingTransactionService() : super(Dio());

  CreateTransactionDto? lastCreated;
  CreateTransactionDto? lastUpdated;

  @override
  Future<Transaction> create(CreateTransactionDto dto) async {
    lastCreated = dto;
    return Transaction(
      id: 'tx-1',
      amount: dto.amount,
      currencyCode: dto.currencyCode,
      category: dto.category,
      description: dto.counterparty,
      type: dto.type,
      date: dto.date,
    );
  }

  @override
  Future<Transaction> getById(String id) async {
    return Transaction(
      id: id,
      amount: 14.75,
      currencyCode: 'USD',
      category: 'Coffee',
      description: '',
      type: 'expense',
      date: DateTime(2026, 5, 7, 12, 30),
    );
  }

  @override
  Future<Transaction> update(String id, CreateTransactionDto dto) async {
    lastUpdated = dto;
    return Transaction(
      id: id,
      amount: dto.amount,
      currencyCode: dto.currencyCode,
      category: dto.category,
      description: dto.counterparty,
      type: dto.type,
      date: dto.date,
    );
  }
}

class _StaticBudgetService extends BudgetService {
  _StaticBudgetService(this.budgets) : super(Dio());

  final List<Budget> budgets;

  @override
  Future<List<Budget>> list() async => budgets;
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(Dio());

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    bool? locationSuggestionsEnabled,
    String? aiPersonalityIntensity,
  }) async {
    return UserProfile(
      id: 'user-1',
      email: 'tx@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: hasCompletedOnboarding ?? true,
      locationSuggestionsEnabled: locationSuggestionsEnabled ?? false,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
    );
  }
}

Future<ProviderContainer> _pumpTransactionForm(
  WidgetTester tester, {
  SharedPreferences? prefs,
  LocationAssistanceService? locationService,
  TransactionService? transactionService,
  List<Budget> budgets = const [],
  bool locationSuggestionsEnabled = false,
}) async {
  final resolvedPrefs = prefs ??
      await () async {
        SharedPreferences.setMockInitialValues({
          'location_suggestions_enabled': false,
          'location_suggestions_prompted': true,
        });
        return SharedPreferences.getInstance();
      }();

  final container = ProviderContainer(
    overrides: [
      categoryFrequencyProvider.overrideWithValue(
        ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
      ),
      subscriptionProvider.overrideWith(
        (ref) async => const SubscriptionStatus(
          tier: 'free',
          isPremium: false,
        ),
      ),
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'tx@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
          locationSuggestionsEnabled: locationSuggestionsEnabled,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(resolvedPrefs),
      userServiceProvider.overrideWithValue(_FakeUserService()),
      locationAssistanceServiceProvider.overrideWithValue(
        locationService ??
            _FakeLocationAssistanceService(permissionGranted: true),
      ),
      transactionServiceProvider.overrideWithValue(
        transactionService ?? _RecordingTransactionService(),
      ),
      budgetServiceProvider.overrideWithValue(_StaticBudgetService(budgets)),
      budgetReconciliationEnabledProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(_buildTransactionFormApp(container));

  return container;
}

Widget _buildTransactionFormApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: TransactionFormScreen(),
    ),
  );
}

Future<Widget> buildTransactionFormApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  },
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final resolvedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      categoryFrequencyProvider.overrideWithValue(
        ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
      ),
      subscriptionProvider.overrideWith(
        (ref) async => const SubscriptionStatus(
          tier: 'free',
          isPremium: false,
        ),
      ),
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'tx@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(resolvedPrefs),
      userServiceProvider.overrideWithValue(_FakeUserService()),
      locationAssistanceServiceProvider.overrideWithValue(
        _FakeLocationAssistanceService(permissionGranted: true),
      ),
      transactionServiceProvider
          .overrideWithValue(_RecordingTransactionService()),
      budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
      budgetReconciliationEnabledProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);

  return _buildTransactionFormApp(container);
}

void main() {
  test('transaction json reads counterparty before legacy merchant fields', () {
    final tx = Transaction.fromJson({
      'id': 'tx-1',
      'amount': 1000,
      'currencyCode': 'PHP',
      'category': 'Salary',
      'counterparty': 'ACME Corp',
      'merchant': 'Legacy Merchant',
      'description': 'Legacy Description',
      'type': 'Income',
      'date': '2026-05-07T00:00:00Z',
    });

    expect(tx.description, 'ACME Corp');
  });

  test('create transaction dto serializes counterparty', () {
    final dto = CreateTransactionDto(
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Salary',
      counterparty: 'ACME Corp',
      type: 'income',
      date: DateTime.utc(2026, 5, 7),
    );

    expect(dto.toJson()['counterparty'], 'ACME Corp');
    expect(dto.toJson().containsKey('merchant'), isFalse);
  });

  testWidgets(
      'transaction form shows a single quick preset row when unselected', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.byType(QuickPresetChips), findsOneWidget);
    expect(find.text('Quick add'), findsNothing);
  });

  testWidgets('transaction form swaps visible quick categories for income', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Dining'), findsNothing);
  });

  testWidgets('income transactions label counterparty field as Source', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Source (optional)'), findsOneWidget);
    expect(find.text('Merchant (optional)'), findsNothing);
  });

  testWidgets('transaction form does not show a voice mic button', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceInputButton), findsNothing);
  });

  testWidgets('transaction form shows category chips above all categories action', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    final chipsTopLeft = tester.getTopLeft(find.text('Dining').first);
    final actionTopLeft = tester.getTopLeft(find.text('All categories'));

    expect(chipsTopLeft.dy, lessThan(actionTopLeft.dy));
  });

  testWidgets(
      'transaction form shows all categories entrypoint and orders sheet by recent categories',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(
      tester,
      initialPrefs: const {
        'location_suggestions_enabled': false,
        'location_suggestions_prompted': true,
        'recent_categories': ['Transport', 'Dining'],
      },
    ));

    await tester.pumpAndSettle();

    expect(find.text('More categories'), findsNothing);
    expect(find.text('All categories'), findsOneWidget);

    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);

    final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    final labels = choiceChips
        .map((chip) => (chip.label as Text).data)
        .whereType<String>()
        .toList();

    expect(labels.take(2).toList(), ['Transport', 'Dining']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Groceries').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.text('Groceries'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('transaction form shows only one category heading', (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));

    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
  });

  testWidgets('transaction form prompts for location assistance on first open',
      (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsOneWidget);
    expect(find.text('You can change this later in Settings.'), findsOneWidget);
    expect(
      find.text(
        'Get nearby merchant and category suggestions wherever you need a little guidance. Suggestions only help fill things faster. You can still edit everything yourself.',
      ),
      findsOneWidget,
    );
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Turn on'), findsOneWidget);
  });

  testWidgets('dismissed location assistance prompt is treated as handled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();
    expect(find.text('Turn on smart location help?'), findsOneWidget);

    Navigator.of(
      tester.element(find.byType(TransactionFormScreen)),
    ).pop();
    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationService: _FakeLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turn on smart location help?'), findsNothing);
  });

  testWidgets('transaction form shows merchant suggestion UI when enabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery', 'Local Grocer'],
          likelyCategories: ['Groceries', 'Dining'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsOneWidget);
    expect(find.text('Nearby merchants'), findsOneWidget);
    expect(find.text('Likely categories'), findsOneWidget);
    expect(find.text('Corner Bakery'), findsOneWidget);
    expect(find.text('Local Grocer'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Blue Bottle Coffee'), findsNothing);
  });

  testWidgets('tapping suggestion chips fills the form fields', (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Corner Bakery'));
    await tester.tap(find.text('Corner Bakery'));
    await tester.pumpAndSettle();

    final merchantField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Merchant (optional)',
      ),
    );
    expect(merchantField.controller?.text, 'Corner Bakery');

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.tap(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.text('Groceries'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'transaction form hides suggestion card when suggestions are empty',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: <String>[],
          likelyCategories: <String>[],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsNothing);
    expect(find.text('Nearby merchants'), findsNothing);
    expect(find.text('Likely categories'), findsNothing);
  });

  testWidgets(
      'transaction form only renders suggestion sections that have content',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: <String>[],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart suggestions nearby'), findsOneWidget);
    expect(find.text('Nearby merchants'), findsOneWidget);
    expect(find.text('Corner Bakery'), findsOneWidget);
    expect(find.text('Likely categories'), findsNothing);
  });

  testWidgets('saving an unbudgeted expense creates a local budget alert', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService();

    final container = await _pumpTransactionForm(
      tester,
      transactionService: transactionService,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Groceries',
          monthlyLimit: 300,
          spent: 25,
          currencyCode: 'USD',
          percentage: 0.08,
          isOverBudget: false,
        ),
      ],
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12.50');
    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastCreated, isNotNull);
    final alerts = container.read(localAlertsProvider);
    expect(alerts, hasLength(1));
    expect(alerts.first.type, 'budget_nudge');
    expect(alerts.first.title, 'No budget for Dining yet');
  });

  testWidgets('saving a budgeted expense updates budget usage immediately', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService();

    final container = await _pumpTransactionForm(
      tester,
      transactionService: transactionService,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Groceries',
          monthlyLimit: 100,
          spent: 20,
          currencyCode: 'USD',
          percentage: 0.2,
          isOverBudget: false,
        ),
      ],
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12.50');
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 32.5);
    expect(updatedBudget.percentage, 0.325);
    expect(container.read(localAlertsProvider), isEmpty);
  });

  testWidgets('budget nudges are deduplicated per category', (tester) async {
    final container = await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    final notifier = container.read(localAlertsProvider.notifier);
    notifier.addBudgetNudge(category: 'Coffee');
    notifier.addBudgetNudge(category: 'Coffee');

    final alerts = container.read(localAlertsProvider);
    expect(alerts, hasLength(1));
    expect(alerts.first.id, 'budget-nudge-coffee');
  });

  testWidgets('editing an unbudgeted expense does not create a fresh nudge', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService();
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
          ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
        ),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'tx@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        userServiceProvider.overrideWithValue(_FakeUserService()),
        locationAssistanceServiceProvider.overrideWithValue(
          _FakeLocationAssistanceService(permissionGranted: true),
        ),
        transactionServiceProvider.overrideWithValue(transactionService),
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const TransactionFormScreen(transactionId: 'tx-1'),
                    ),
                  );
                },
                child: const Text('Open edit'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '18.25');
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Merchant (optional)',
      ),
      'Morning Brew',
    );
    await tester.tap(find.text('Update Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastUpdated, isNotNull);
    expect(container.read(localAlertsProvider), isEmpty);
    expect(find.textContaining('Budget nudge saved'), findsNothing);
  });

  testWidgets(
      'editing a budgeted expense updates local budget usage immediately',
      (tester) async {
    final transactionService = _RecordingTransactionService();
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        categoryFrequencyProvider.overrideWithValue(
          ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
        ),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'free',
            isPremium: false,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'tx@example.com',
            currencyCode: 'USD',
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        userServiceProvider.overrideWithValue(_FakeUserService()),
        locationAssistanceServiceProvider.overrideWithValue(
          _FakeLocationAssistanceService(permissionGranted: true),
        ),
        transactionServiceProvider.overrideWithValue(transactionService),
        budgetServiceProvider.overrideWithValue(
          _StaticBudgetService(const [
            Budget(
              id: 'budget-1',
              category: 'Coffee',
              monthlyLimit: 100,
              spent: 20,
              currencyCode: 'USD',
              percentage: 0.2,
              isOverBudget: false,
            ),
          ]),
        ),
        budgetReconciliationEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TransactionFormScreen(transactionId: 'tx-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '18.25');
    await tester.tap(find.text('Update Transaction'));
    await tester.pumpAndSettle();

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 23.5);
    expect(updatedBudget.percentage, 0.235);
  });
}
