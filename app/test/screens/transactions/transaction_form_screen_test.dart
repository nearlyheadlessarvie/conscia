import 'package:conscia_app/providers/alert_provider.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/category_provider.dart';
import 'package:conscia_app/providers/exchange_rate_provider.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/models/recurring_schedule.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/voice_input_button.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/recurring_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/amount_hero_field.dart';
import 'package:conscia_app/widgets/conscia_bottom_sheet.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({
    required this.permissionGranted,
    this.suggestions = const (
      nearbyMerchants: ['Blue Bottle Coffee'],
      likelyCategories: ['Coffee'],
    ),
    this.merchantCategories = const {},
  });

  final bool permissionGranted;
  final ({
    List<String> nearbyMerchants,
    List<String> likelyCategories
  }) suggestions;
  final Map<String, String> merchantCategories;
  String? recordedMerchant;
  String? recordedCategory;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() => suggestions;

  @override
  String? categoryForMerchant(String merchant) => merchantCategories[merchant];

  @override
  Future<void> recordTransactionContext({
    required String merchant,
    required String category,
  }) async {
    recordedMerchant = merchant;
    recordedCategory = category;
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async =>
      null;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
    state = initialState;
  }
}

final _authenticatedOverride = authProvider.overrideWith(
  (ref) => _TestAuthNotifier(
    const AuthState(status: AuthStatus.authenticated, userId: 'user-1'),
  ),
);

class _RecordingTransactionService extends TransactionService {
  _RecordingTransactionService({this.editTransaction}) : super(Dio());

  final Transaction? editTransaction;

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
      scope: dto.scope,
      familySpaceId: dto.familySpaceId,
      recurringScheduleId: dto.recurring?.enabled == true ? 'schedule-1' : null,
      recurringOccurrenceDate: dto.recurring?.enabled == true ? dto.date : null,
    );
  }

  @override
  Future<Transaction> getById(String id) async {
    if (editTransaction != null) return editTransaction!;

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
      scope: dto.scope,
      familySpaceId: dto.familySpaceId,
      recurringScheduleId: dto.recurring?.enabled == true ? 'schedule-1' : null,
      recurringOccurrenceDate: dto.recurring?.enabled == true ? dto.date : null,
    );
  }
}

class _FakeRecurringService extends RecurringService {
  _FakeRecurringService() : super(Dio());
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
    String? displayName,
    String? profilePictureKey,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    String? aiPersonalityIntensity,
  }) async {
    return UserProfile(
      id: 'user-1',
      email: 'tx@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: hasCompletedOnboarding ?? true,
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
  String? transactionId,
  String? initialCategory,
  List<Budget> budgets = const [],
  FamilySpace? familySpace,
  String locale = 'en_US',
  bool locationSuggestionsEnabled = false,
}) async {
  final resolvedPrefs = prefs ??
      await () async {
        SharedPreferences.setMockInitialValues({
          'location_suggestions_enabled': locationSuggestionsEnabled,
          'location_suggestions_prompted': true,
        });
        return SharedPreferences.getInstance();
      }();

  final container = ProviderContainer(
    overrides: [
      _authenticatedOverride,
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
          locale: locale,
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
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
      recurringServiceProvider.overrideWithValue(_FakeRecurringService()),
      budgetServiceProvider.overrideWithValue(_StaticBudgetService(budgets)),
      budgetReconciliationEnabledProvider.overrideWithValue(false),
      _disabledRemoteAlertSyncOverride(),
      exchangeRateProvider.overrideWith((ref, pair) async => null),
      managedCategoriesProvider.overrideWith((ref, query) async => const []),
      familySpaceProvider.overrideWith((ref) async => familySpace),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    _buildTransactionFormApp(
      container,
      transactionId: transactionId,
      initialCategory: initialCategory,
    ),
  );

  return container;
}

Widget _buildTransactionFormApp(
  ProviderContainer container, {
  String? transactionId,
  String? initialCategory,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: TransactionFormScreen(
        transactionId: transactionId,
        initialCategory: initialCategory,
      ),
    ),
  );
}

Finder _floatingLabelInput(String label) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is FloatingLabelTextField && widget.label == label,
    ),
    matching: find.byType(TextField),
  );
}

Finder _amountInput() {
  return find.descendant(
    of: find.byType(AmountHeroField),
    matching: find.byType(EditableText),
  );
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<Widget> buildTransactionFormApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  },
  String locale = 'en_US',
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final resolvedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      _authenticatedOverride,
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
          locale: locale,
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
      recurringServiceProvider.overrideWithValue(_FakeRecurringService()),
      budgetServiceProvider.overrideWithValue(_StaticBudgetService(const [])),
      budgetReconciliationEnabledProvider.overrideWithValue(false),
      _disabledRemoteAlertSyncOverride(),
      exchangeRateProvider.overrideWith((ref, pair) async => null),
      managedCategoriesProvider.overrideWith((ref, query) async => const []),
      familySpaceProvider.overrideWith((ref) async => null),
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

  test('transaction json reads scope and family space id', () {
    final tx = Transaction.fromJson({
      'id': 'tx-1',
      'amount': 2460,
      'currencyCode': 'PHP',
      'category': 'Dining',
      'counterparty': 'Manam',
      'type': 'Expense',
      'date': '2026-05-03T00:00:00Z',
      'scope': 'Family',
      'familySpaceId': 'family-1',
    });

    expect(tx.scope, 'family');
    expect(tx.familySpaceId, 'family-1');
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

  test('create transaction dto serializes family scope', () {
    final dto = CreateTransactionDto(
      amount: 1500,
      currencyCode: 'PHP',
      category: 'Groceries',
      counterparty: 'Landers',
      type: 'expense',
      date: DateTime.utc(2026, 5, 7),
      scope: 'family',
      familySpaceId: 'family-1',
    );

    expect(dto.toJson()['scope'], 'Family');
    expect(dto.toJson()['familySpaceId'], 'family-1');
  });

  testWidgets('transaction form route presents as a Conscia pull-up sheet', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsAtLeastNWidgets(1));
    expect(find.byType(ConsciaSheetHandle), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
  });

  testWidgets(
      'transaction form shows a single quick preset row when unselected', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);

    await tester.pumpAndSettle();

    expect(find.text('Premium categories'), findsOneWidget);
    expect(find.text('More'), findsNothing);
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Source (optional)'), findsOneWidget);
    expect(find.text('Merchant (optional)'), findsNothing);
  });

  testWidgets('transaction form asks details before amount and category', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);
    await tester.pumpAndSettle();

    expect(find.text('AMOUNT'), findsNothing);
    expect(find.text('Transaction Details'), findsOneWidget);

    final detailsTop = tester.getTopLeft(find.text('Transaction Details')).dy;
    final merchantTop =
        tester.getTopLeft(_floatingLabelInput('Merchant (optional)')).dy;
    final amountTop = tester.getTopLeft(find.byType(AmountHeroField)).dy;
    final categoryTop = tester.getTopLeft(find.text('Category')).dy;

    expect(detailsTop, lessThan(merchantTop));
    expect(merchantTop, lessThan(amountTop));
    expect(amountTop, lessThan(categoryTop));
  });

  testWidgets('transaction form advances from merchant to amount', (
    tester,
  ) async {
    await _pumpTransactionForm(tester);
    await tester.pumpAndSettle();

    final merchantField = tester.widget<TextField>(
      _floatingLabelInput('Merchant (optional)'),
    );
    expect(merchantField.focusNode?.hasFocus, isTrue);

    merchantField.onSubmitted?.call('Corner Bakery');
    await tester.pumpAndSettle();

    final amountField = tester.widget<EditableText>(_amountInput());
    expect(amountField.focusNode.hasFocus, isTrue);
  });

  testWidgets('transaction amount submit brings category into view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTransactionForm(tester);
    await tester.pumpAndSettle();

    final categoryTitle = find.text('Category', skipOffstage: false);
    final before = tester.getTopLeft(categoryTitle).dy;

    tester.widget<EditableText>(_amountInput()).onSubmitted?.call('12.50');
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(categoryTitle).dy;
    expect(after, lessThan(before));
  });

  testWidgets('income transactions do not show merchant autosuggestions', (
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

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await tester.tap(_floatingLabelInput('Source (optional)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('smart-merchant-suggestion-strip')),
        findsNothing);
    expect(find.text('Corner Bakery'), findsNothing);
  });

  testWidgets('transaction form does not show a voice mic button', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceInputButton), findsNothing);
  });

  testWidgets(
      'transaction form shows category chips above all categories action', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    // 'Dining' chip and premium affordance are in the same horizontal chip rail row
    final chipsY = tester.getCenter(find.text('Dining').first).dy;
    final actionY = tester.getCenter(find.text('Premium categories')).dy;

    expect((chipsY - actionY).abs(), lessThan(8));
  });

  testWidgets(
      'transaction form shows premium categories entrypoint for free users',
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

    expect(find.text('More'), findsNothing);
    expect(find.text('Premium categories'), findsOneWidget);

    await _tapVisibleText(tester, 'Premium categories');

    expect(find.byType(BottomSheet), findsAtLeastNWidgets(1));
    expect(find.text('Premium Feature'), findsOneWidget);
    expect(
      find.text(
        'Free users can only log transactions in Dining, Groceries, and Salary.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('transaction form keeps category separate from scope',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));

    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('Was this money in or out?'), findsOneWidget);
    expect(find.text('Classify'), findsNothing);
    expect(find.text('Category'), findsOneWidget);
    expect(
      find.text(
        'Choose where this transaction belongs so budgets and insights stay accurate.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('income category copy explains income rhythm tracking',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(
      find.text(
        'Choose where this money came from so Conscia can understand your income rhythm separately from spending.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('family scope uses its own classify section', (tester) async {
    await _pumpTransactionForm(
      tester,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'USD',
        isReadOnly: false,
        role: 'Contributor',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classify'), findsOneWidget);
    expect(
      find.text('Where should this live in your money story?'),
      findsOneWidget,
    );
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('SCOPE'), findsNothing);
  });

  testWidgets('category selector and merchant field are always visible',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Premium categories'), findsOneWidget);
    expect(find.text('Merchant (optional)'), findsOneWidget);
  });

  testWidgets('category label and chip rail are always visible',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Premium categories'), findsOneWidget);
  });

  testWidgets('merchant field and date are always visible', (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Merchant (optional)'), findsOneWidget);
    expect(find.text('Timing'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('merchant field uses Conscia v2 floating label treatment',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
      floatingFields.any((field) => field.label == 'Merchant (optional)'),
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Merchant (optional)',
      ),
      findsNothing,
    );
  });

  testWidgets(
      'recurring section is always visible and cadence options are hidden by default',
      (tester) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('RECURRING'), findsNothing);
    expect(find.text('Repeat on a schedule.'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);

    final title = tester.widget<Text>(find.text('Recurring'));
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(find.text('Weekly'), findsNothing);
  });

  testWidgets('shows recurring controls when recurring switch is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTransactionFormApp(tester));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('END DATE'), findsOneWidget);
    expect(find.text('Never ends'), findsWidgets);
  });

  testWidgets('create transaction dto serializes recurring payload', (
    tester,
  ) async {
    final dto = CreateTransactionDto(
      amount: 1000,
      currencyCode: 'PHP',
      category: 'Salary',
      counterparty: 'ACME Corp',
      type: 'income',
      date: DateTime.utc(2026, 5, 7),
      recurring: const RecurringDraft(enabled: true, cadence: 'Monthly'),
    );

    expect(dto.toJson()['recurring'], {
      'cadence': 'Monthly',
    });
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

  testWidgets('transaction form shows quiet merchant suggestions when enabled',
      (
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

    expect(find.text('Smart suggestions nearby'), findsNothing);
    expect(find.byKey(const ValueKey('smart-merchant-suggestion-strip')),
        findsOneWidget);
    expect(find.text('Likely categories'), findsNothing);
    expect(find.text('Corner Bakery'), findsOneWidget);
    expect(find.text('Local Grocer'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsNothing);
  });

  testWidgets('merchant suggestions stay open while horizontally scrolling', (
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
          nearbyMerchants: [
            'Corner Bakery',
            'Local Grocer',
            'Starbucks',
            'Manam',
            'Grab',
          ],
          likelyCategories: ['Groceries', 'Dining'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    final strip = find.byKey(
      const ValueKey('smart-merchant-suggestion-strip'),
    );
    expect(strip, findsOneWidget);

    await tester.drag(strip, const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(strip, findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
  });

  testWidgets('tapping a merchant suggestion fills merchant and category',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': true,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final transactionService = _RecordingTransactionService();

    await _pumpTransactionForm(
      tester,
      prefs: prefs,
      transactionService: transactionService,
      locationSuggestionsEnabled: true,
      locationService: _FakeLocationAssistanceService(
        permissionGranted: true,
        suggestions: const (
          nearbyMerchants: ['Corner Bakery'],
          likelyCategories: ['Groceries'],
        ),
        merchantCategories: const {'Corner Bakery': 'Groceries'},
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Corner Bakery'));
    await tester.tap(find.text('Corner Bakery'));
    await tester.pumpAndSettle();

    final merchantField = tester.widget<FloatingLabelTextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingLabelTextField &&
            widget.label == 'Merchant (optional)',
      ),
    );
    expect(merchantField.controller.text, 'Corner Bakery');
    expect(find.text('Groceries'), findsWidgets);
    expect(
        tester.widget<EditableText>(_amountInput()).focusNode.hasFocus, isTrue);

    await tester.enterText(_amountInput(), '12.50');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Transaction'));
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastCreated?.counterparty, 'Corner Bakery');
    expect(transactionService.lastCreated?.category, 'Groceries');
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
    expect(find.byKey(const ValueKey('smart-merchant-suggestion-strip')),
        findsNothing);
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

    expect(find.text('Smart suggestions nearby'), findsNothing);
    expect(find.byKey(const ValueKey('smart-merchant-suggestion-strip')),
        findsOneWidget);
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

    await tester.enterText(_amountInput(), '12.50');
    await _tapVisibleText(tester, 'Dining');
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastCreated, isNotNull);
    final alerts = container.read(localAlertsProvider);
    expect(alerts, hasLength(1));
    expect(alerts.first.type, 'budget_nudge');
    expect(alerts.first.title, 'No budget for Dining yet');
  });

  testWidgets('transaction form parses localized amount input on save', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService();

    await _pumpTransactionForm(
      tester,
      transactionService: transactionService,
      locale: 'de_DE',
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 3000,
          spent: 25,
          currencyCode: 'USD',
          percentage: 0.01,
          isOverBudget: false,
        ),
      ],
    );

    await tester.pumpAndSettle();

    await tester.enterText(_amountInput(), '1.234,56');
    await _tapVisibleText(tester, 'Dining');
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastCreated?.amount, 1234.56);
  });

  testWidgets('transaction form uses locale when showing explicit dates', (
    tester,
  ) async {
    await _pumpTransactionForm(
      tester,
      transactionService: _RecordingTransactionService(
        editTransaction: Transaction(
          id: 'tx-locale-date',
          amount: 14.75,
          currencyCode: 'EUR',
          category: 'Coffee',
          description: 'Cafe',
          type: 'expense',
          date: DateTime(2026, 5, 3, 12, 30),
        ),
      ),
      transactionId: 'tx-locale-date',
      locale: 'de_DE',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('3.5.2026'), findsOneWidget);
  });

  testWidgets('transaction form can save a family-scoped transaction', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService();

    await _pumpTransactionForm(
      tester,
      transactionService: transactionService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Contributor',
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Family'));
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.enterText(_amountInput(), '1500');
    await _tapVisibleText(tester, 'Groceries');
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(transactionService.lastCreated?.scope, 'family');
    expect(transactionService.lastCreated?.familySpaceId, 'family-1');
  });

  testWidgets('edit form shows and preserves family transaction scope', (
    tester,
  ) async {
    final transactionService = _RecordingTransactionService(
      editTransaction: Transaction(
        id: 'tx-family',
        amount: 2460,
        currencyCode: 'PHP',
        category: 'Dining',
        description: 'Manam',
        type: 'expense',
        date: DateTime(2026, 5, 3),
        scope: 'family',
        familySpaceId: 'family-1',
      ),
    );

    await _pumpTransactionForm(
      tester,
      transactionService: transactionService,
      transactionId: 'tx-family',
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Contributor',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Classify'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);

    await tester.tap(find.text('Update Transaction'));
    await tester.pump();

    expect(transactionService.lastUpdated?.scope, 'family');
    expect(transactionService.lastUpdated?.familySpaceId, 'family-1');
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

    await tester.enterText(_amountInput(), '12.50');
    await _tapVisibleText(tester, 'Groceries');
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 32.5);
    expect(updatedBudget.percentage, 0.325);
    expect(container.read(localAlertsProvider), isEmpty);
  });

  testWidgets('saving a new expense records smart nearby suggestion history', (
    tester,
  ) async {
    final locationService =
        _FakeLocationAssistanceService(permissionGranted: true);
    await _pumpTransactionForm(
      tester,
      locationService: locationService,
      initialCategory: 'Dining',
      locationSuggestionsEnabled: true,
    );

    await tester.pumpAndSettle();

    await tester.enterText(_amountInput(), '12.50');
    await tester.enterText(
      _floatingLabelInput('Merchant (optional)'),
      'Wildflour',
    );
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(locationService.recordedMerchant, 'Wildflour');
    expect(locationService.recordedCategory, 'Dining');
  });

  testWidgets('saving an expense skips smart nearby history when disabled', (
    tester,
  ) async {
    final locationService =
        _FakeLocationAssistanceService(permissionGranted: true);
    await _pumpTransactionForm(
      tester,
      locationService: locationService,
      initialCategory: 'Dining',
      locationSuggestionsEnabled: false,
    );

    await tester.pumpAndSettle();

    await tester.enterText(_amountInput(), '12.50');
    await tester.enterText(
      _floatingLabelInput('Merchant (optional)'),
      'Wildflour',
    );
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    expect(locationService.recordedMerchant, isNull);
    expect(locationService.recordedCategory, isNull);
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
        _authenticatedOverride,
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
        exchangeRateProvider.overrideWith((ref, pair) async => null),
        managedCategoriesProvider.overrideWith((ref, query) async => const []),
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

    await tester.enterText(_amountInput(), '18.25');
    await tester.enterText(
        _floatingLabelInput('Merchant (optional)'), 'Morning Brew');
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
        _authenticatedOverride,
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
        exchangeRateProvider.overrideWith((ref, pair) async => null),
        managedCategoriesProvider.overrideWith((ref, query) async => const []),
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

    await tester.enterText(_amountInput(), '18.25');
    await tester.tap(find.text('Update Transaction'));
    await tester.pumpAndSettle();

    final updatedBudget = container.read(budgetListProvider).budgets.single;
    expect(updatedBudget.spent, 23.5);
    expect(updatedBudget.percentage, 0.235);
  });
}

Override _disabledRemoteAlertSyncOverride() {
  return alertActionsProvider.overrideWith(
    (ref) => AlertActions(
      dio: Dio(),
      enabled: false,
      onRemoteChanged: () {},
    ),
  );
}
