import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/budget_providers.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/screens/budgets/budgets_screen.dart';
import 'package:conscia_app/screens/budgets/widgets/budget_card.dart';
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
import 'dart:async';

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
  FutureOr<SubscriptionStatus> Function()? subscriptionBuilder,
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
          (ref) async => await (subscriptionBuilder?.call() ??
              const SubscriptionStatus(
                tier: 'premium',
                isPremium: true,
              )),
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

  testWidgets('budgets screen list shows redesigned progress rows',
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

    expect(find.text('ACTIVE BUDGETS'), findsOneWidget);
    expect(find.text('Shopping'), findsWidgets);
    expect(find.text('On pace'), findsOneWidget);
  });

  testWidgets('budgets screen uses a bleeding editorial hero and flat rows',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 4000,
          spent: 3720,
          currencyCode: 'PHP',
          percentage: 0.93,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-2',
          category: 'Bills',
          monthlyLimit: 12000,
          spent: 2195,
          currencyCode: 'PHP',
          percentage: 0.18,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-3',
          category: 'Dining',
          monthlyLimit: 6500,
          spent: 3720,
          currencyCode: 'PHP',
          percentage: 0.57,
          isOverBudget: false,
          scope: 'family',
          familySpaceId: 'family-1',
        ),
      ],
    );

    expect(
        find.byKey(const ValueKey('budgets-editorial-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('budgets-hero-donut')), findsOneWidget);
    expect(find.text('used'), findsOneWidget);
    expect(find.text('BUDGET PACE'), findsOneWidget);
    expect(find.text('₱16,000.00'), findsOneWidget);
    expect(find.text('₱5,915.00'), findsOneWidget);
    expect(find.text('Dining 63%'), findsOneWidget);
    expect(find.text('Bills 37%'), findsOneWidget);
    expect(find.text('2 active'), findsNothing);
    expect(find.text('1 family'), findsNothing);
    expect(find.byType(BudgetCard), findsNothing);
    expect(find.text('Family budget'), findsNothing);
    final painter = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(const ValueKey('budgets-hero-donut')),
        matching: find.byType(CustomPaint),
      ),
    );
    final donutPainter = painter.painter as dynamic;
    expect(donutPainter.segmentColors.toSet().length, 2);
    expect(
      donutPainter.segmentColors,
      containsAllInOrder(
        const [
          Color(0xFF43A047),
          Color(0xFFFF9800),
        ],
      ),
    );
    expect(donutPainter.trackOpacity, closeTo(0.2, 0.01));
    expect(donutPainter.usesCapAwareGaps, isTrue);
    expect(donutPainter.visibleGapPx, 1.5);
    expect(donutPainter.trackStrokeWidth, 22);
    expect(donutPainter.segmentStrokeWidth, 16);
    final rail = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('budgets-mix-pill-rail')),
    );
    expect(rail.scrollDirection, Axis.horizontal);
    final diningIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('budget-row-icon-budget-1')),
    );
    expect(diningIcon.size, 30);
    expect(diningIcon.color, const Color(0xFF43A047));

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    expect(find.text('₱6,500.00'), findsOneWidget);
    expect(find.text('Family budget'), findsOneWidget);
  });

  testWidgets('tapping a budget donut segment calls out its mix pill',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 4000,
          spent: 3720,
          currencyCode: 'PHP',
          percentage: 0.93,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-2',
          category: 'Bills',
          monthlyLimit: 12000,
          spent: 2195,
          currencyCode: 'PHP',
          percentage: 0.18,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-3',
          category: 'Shopping',
          monthlyLimit: 3500,
          spent: 1890,
          currencyCode: 'PHP',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
    );

    expect(
        find.byKey(const ValueKey('budget-mix-chip-0-active')), findsNothing);

    final donutRect =
        tester.getRect(find.byKey(const ValueKey('budgets-hero-donut')));
    await tester.tapAt(donutRect.centerRight - const Offset(8, 0));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('budget-mix-chip-0-active')), findsOneWidget);
  });

  testWidgets('budgets hero donut spans the headline story block',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 4000,
          spent: 3720,
          currencyCode: 'PHP',
          percentage: 0.93,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-2',
          category: 'Bills',
          monthlyLimit: 12000,
          spent: 2195,
          currencyCode: 'PHP',
          percentage: 0.18,
          isOverBudget: false,
        ),
      ],
    );

    final donutRect =
        tester.getRect(find.byKey(const ValueKey('budgets-hero-donut')));
    final labelRect = tester.getRect(find.text('BUDGET PACE'));
    final summaryRect = tester.getRect(
      find.text(
        'Dining is currently carrying your strongest budget signal.',
      ),
    );

    expect(donutRect.height, greaterThanOrEqualTo(118));
    expect(donutRect.top, lessThanOrEqualTo(labelRect.top + 8));
    expect(donutRect.bottom, greaterThanOrEqualTo(summaryRect.bottom - 8));
  });

  testWidgets('budgets hero content starts close to the app bar',
      (tester) async {
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 4000,
          spent: 3720,
          currencyCode: 'PHP',
          percentage: 0.93,
          isOverBudget: false,
        ),
      ],
    );

    final headerBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('conscia-app-bar-capsule')))
        .dy;
    final labelTop = tester.getTopLeft(find.text('BUDGET PACE')).dy;

    expect(labelTop - headerBottom, lessThanOrEqualTo(32));
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

    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('budgets screen keeps only nav-shell-safe bottom breathing room',
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

    final spacer = tester.widget<SizedBox>(
      find.byKey(const ValueKey('budgets-bottom-nav-spacer')),
    );
    expect(spacer.height, 88);
  });

  testWidgets('add budget waits for premium status before showing limit dialog',
      (tester) async {
    final subscription = Completer<SubscriptionStatus>();
    await _pumpBudgetsScreen(
      tester,
      budgets: const [
        Budget(
          id: 'budget-1',
          category: 'Dining',
          monthlyLimit: 4000,
          spent: 1200,
          currencyCode: 'PHP',
          percentage: 0.3,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-2',
          category: 'Bills',
          monthlyLimit: 12000,
          spent: 2195,
          currencyCode: 'PHP',
          percentage: 0.18,
          isOverBudget: false,
        ),
        Budget(
          id: 'budget-3',
          category: 'Shopping',
          monthlyLimit: 3500,
          spent: 1890,
          currencyCode: 'PHP',
          percentage: 0.54,
          isOverBudget: false,
        ),
      ],
      subscriptionBuilder: () => subscription.future,
    );

    await tester.tap(find.byTooltip('Add budget'));
    await tester.pump();

    expect(find.text('Premium Feature'), findsNothing);

    subscription.complete(
      const SubscriptionStatus(tier: 'premium', isPremium: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Budget'), findsOneWidget);
    expect(find.text('Premium Feature'), findsNothing);
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
