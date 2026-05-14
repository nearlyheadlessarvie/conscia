import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/budgets/budgets_screen.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_form_sheet.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/budget_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }
}

final _authenticatedOverride = authProvider.overrideWith(
  (ref) => _TestAuthNotifier(
    const AuthState(status: AuthStatus.authenticated, userId: 'user-1'),
  ),
);

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
      id: 'budget-1',
      category: dto.category,
      monthlyLimit: dto.monthlyLimit,
      spent: 0,
      currencyCode: dto.currencyCode,
      percentage: 0,
      isOverBudget: false,
    );
  }
}

Future<void> _pumpBudgetsScreen(
  WidgetTester tester, {
  required List<Budget> budgets,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _authenticatedOverride,
        budgetServiceProvider.overrideWithValue(_StaticBudgetService(budgets)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'premium',
            isPremium: true,
          ),
        ),
      ],
      child: const MaterialApp(home: BudgetsScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  test('create budget dto serializes family scope', () {
    const dto = CreateBudgetDto(
      category: 'Groceries',
      monthlyLimit: 12000,
      currencyCode: 'PHP',
      scope: 'family',
      familySpaceId: 'family-1',
    );

    expect(dto.toJson()['scope'], 'Family');
    expect(dto.toJson()['familySpaceId'], 'family-1');
  });

  testWidgets('budgets screen empty state uses shared hero language',
      (tester) async {
    await _pumpBudgetsScreen(tester, budgets: const []);

    expect(
        find.text('Budgets that match how you actually spend'), findsOneWidget);
    expect(find.text('Create your first budget'), findsOneWidget);
  });

  testWidgets('budgets screen list shows redesigned progress cards',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Monthly cap'), findsOneWidget);
    expect(find.text('Spent so far'), findsOneWidget);
  });

  testWidgets('budgets screen uses pull to refresh instead of a refresh icon',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('budgets screen uses a single vertical scroll container',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Shopping',
          monthlyLimit: 1200,
          spent: 650,
          currencyCode: 'USD',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('budget form can create a family-scoped budget', (tester) async {
    final budgetService = _RecordingBudgetService();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _authenticatedOverride,
          budgetServiceProvider.overrideWithValue(budgetService),
          sharedPreferencesProvider.overrideWithValue(prefs),
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'family@example.com',
              currencyCode: 'PHP',
              locale: 'en_PH',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'premium',
              isPremium: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BudgetFormSheet(initialCategory: 'Groceries')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '12000');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Family'));
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Budget'));
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create Budget'),
    );
    expect(createButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Create Budget'));
    await tester.pumpAndSettle();

    expect(budgetService.lastCreated?.scope, 'family');
    expect(budgetService.lastCreated?.familySpaceId, 'family-1');
  });
}
