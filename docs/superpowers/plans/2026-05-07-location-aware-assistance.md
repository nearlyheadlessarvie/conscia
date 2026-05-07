# Location-Aware Assistance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add first-use location assistance prompting, shared merchant/category suggestions for Add Transaction and Pre-Purchase Assistant, a settings toggle for later control, and an in-app budget nudge after unbudgeted expenses.

**Architecture:** Add a small shared preference + location assistance layer in Flutter, then wire both transaction entry surfaces to it. Keep suggestions assistive and local-first, and use the existing in-app alerts provider pattern for the unbudgeted-expense nudge. Update docs alongside the feature so product status and new behavior stay accurate.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, existing Dio services/providers, widget tests, Flutter analyze

---

## File Structure

### New files

- `app/lib/providers/location_assistance_provider.dart`
  - Shared preference state, first-use prompt gating, and location assistance controller/provider surface.
- `app/lib/services/location_assistance_service.dart`
  - Encapsulates permission requests, current-location retrieval, and merchant/category suggestion heuristics.
- `app/lib/widgets/location_assistance_prompt_sheet.dart`
  - Reusable first-use explainer sheet for Add Transaction and Pre-Purchase Assistant.
- `app/test/providers/location_assistance_provider_test.dart`
  - Preference and first-use prompt state coverage.
- `app/test/screens/assistant/pre_purchase_screen_test.dart`
  - Prompt and suggestion surface coverage for Pre-Purchase Assistant.
- `app/test/screens/settings/settings_screen_location_test.dart`
  - Settings toggle coverage for location suggestions.

### Modified files

- `app/lib/providers/user_provider.dart`
  - Extend user preference domain with shared local location-assistance preference source.
- `app/lib/screens/transactions/transaction_form_screen.dart`
  - First-use prompt trigger, suggestion UI, remove/absorb hidden include-location switch, emit budget nudge signal.
- `app/lib/screens/assistant/pre_purchase_screen.dart`
  - First-use prompt trigger plus merchant/category suggestion UX.
- `app/lib/screens/settings/settings_screen.dart`
  - Add smart location suggestions setting and denied-permission helper text.
- `app/lib/providers/alert_provider.dart`
  - Add local/appended in-memory alert support or helper for transaction-triggered budget nudges.
- `app/lib/services/transaction_service.dart`
  - If needed, extend DTO model for explicit location fields only when the current API contract already supports them.
- `app/test/screens/transactions/transaction_form_screen_test.dart`
  - Prompt, suggestion, and budget-nudge regression coverage.
- `docs/README.md`
  - Refresh stale project status and mention the new location-aware assistance behavior where relevant.
- `docs/implementation-tasks.md`
  - Mark or annotate the friction-reduction/location-adjacent behavior so docs reflect the current product direction.

---

### Task 1: Shared Location Assistance State and Prompting

**Files:**
- Create: `app/lib/providers/location_assistance_provider.dart`
- Create: `app/lib/services/location_assistance_service.dart`
- Create: `app/test/providers/location_assistance_provider_test.dart`
- Modify: `app/lib/providers/user_provider.dart`

- [ ] **Step 1: Write the failing provider tests**

```dart
test('first-use prompt is needed before the user has chosen', () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  final state = container.read(locationAssistanceProvider);
  expect(state.shouldPromptOnFeatureOpen, isTrue);
  expect(state.isEnabled, isFalse);
});

test('decline marks the feature as prompted and stops re-prompting', () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  await container.read(locationAssistanceProvider.notifier).declinePrompt();

  final state = container.read(locationAssistanceProvider);
  expect(state.shouldPromptOnFeatureOpen, isFalse);
  expect(state.isEnabled, isFalse);
});

test('enable marks the feature active when permission succeeds', () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationAssistanceServiceProvider.overrideWithValue(
        FakeLocationAssistanceService(permissionGranted: true),
      ),
    ],
  );

  await container.read(locationAssistanceProvider.notifier).enableFromPrompt();

  final state = container.read(locationAssistanceProvider);
  expect(state.shouldPromptOnFeatureOpen, isFalse);
  expect(state.isEnabled, isTrue);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/location_assistance_provider_test.dart`
Expected: FAIL because `locationAssistanceProvider` and the new service do not exist yet.

- [ ] **Step 3: Write the minimal shared preference + provider implementation**

```dart
class LocationAssistanceState {
  final bool isEnabled;
  final bool hasPrompted;
  final bool permissionDenied;

  const LocationAssistanceState({
    required this.isEnabled,
    required this.hasPrompted,
    required this.permissionDenied,
  });

  bool get shouldPromptOnFeatureOpen => !hasPrompted;
}

class LocationAssistanceNotifier
    extends StateNotifier<LocationAssistanceState> {
  LocationAssistanceNotifier(this._prefs, this._service)
      : super(_loadInitial(_prefs));

  static const _enabledKey = 'location_suggestions_enabled';
  static const _promptedKey = 'location_suggestions_prompted';
  static const _deniedKey = 'location_suggestions_permission_denied';

  final SharedPreferences _prefs;
  final LocationAssistanceService _service;

  Future<void> declinePrompt() async {
    await _prefs.setBool(_promptedKey, true);
    state = LocationAssistanceState(
      isEnabled: false,
      hasPrompted: true,
      permissionDenied: state.permissionDenied,
    );
  }

  Future<void> enableFromPrompt() async {
    final granted = await _service.requestPermission();
    await _prefs.setBool(_promptedKey, true);
    await _prefs.setBool(_enabledKey, granted);
    await _prefs.setBool(_deniedKey, !granted);
    state = LocationAssistanceState(
      isEnabled: granted,
      hasPrompted: true,
      permissionDenied: !granted,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/location_assistance_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/providers/location_assistance_provider.dart app/lib/services/location_assistance_service.dart app/lib/providers/user_provider.dart app/test/providers/location_assistance_provider_test.dart
git commit -m "feat: add shared location assistance preferences"
```

### Task 2: Add Transaction Prompt and Suggestion Surface

**Files:**
- Create: `app/lib/widgets/location_assistance_prompt_sheet.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/test/screens/transactions/transaction_form_screen_test.dart`

- [ ] **Step 1: Write the failing widget tests**

```dart
testWidgets('transaction form prompts for location assistance on first open', (
  tester,
) async {
  await tester.pumpWidget(buildTransactionFormWithLocationState(
    shouldPrompt: true,
  ));

  await tester.pumpAndSettle();

  expect(find.text('Use your location for smarter suggestions?'), findsOneWidget);
  expect(find.text('You can change this later in Settings.'), findsOneWidget);
});

testWidgets('transaction form shows merchant suggestion UI when enabled', (
  tester,
) async {
  await tester.pumpWidget(buildTransactionFormWithSuggestions(
    merchants: ['Starbucks BGC'],
    categories: ['Coffee'],
  ));

  await tester.pumpAndSettle();

  expect(find.text('Starbucks BGC'), findsOneWidget);
  expect(find.text('Coffee'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart`
Expected: FAIL because the prompt sheet and suggestion UI are not wired into the transaction form.

- [ ] **Step 3: Implement the first-use prompt and visible suggestion row**

```dart
@override
void initState() {
  super.initState();
  _currencyCode = ref.read(userPreferencesProvider).currency;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _maybePromptForLocationAssistance();
    if (_isEditing) {
      _loadEditData();
    }
  });
}

Future<void> _maybePromptForLocationAssistance() async {
  final state = ref.read(locationAssistanceProvider);
  if (!state.shouldPromptOnFeatureOpen || !mounted) return;

  final accepted = await LocationAssistancePromptSheet.show(context);
  if (accepted == true) {
    await ref.read(locationAssistanceProvider.notifier).enableFromPrompt();
  } else {
    await ref.read(locationAssistanceProvider.notifier).declinePrompt();
  }
}
```

```dart
if (locationState.isEnabled && suggestionState.hasSuggestions) ...[
  MerchantSuggestionCard(
    merchants: suggestionState.merchants,
    categories: suggestionState.categories,
    onMerchantSelected: (merchant) {
      setState(() => _merchantController.text = merchant);
    },
    onCategorySelected: (category) {
      setState(() => _selectedCategory = category);
    },
  ),
  const SizedBox(height: 16),
]
```

- [ ] **Step 4: Retire the hidden `Include Location` switch**

```dart
// Remove:
bool _includeLocation = false;

// Replace the More Options location section with note-only copy when needed:
if (locationState.isEnabled)
  Text(
    'Smart location suggestions are on. You can change this later in Settings.',
  ),
```

- [ ] **Step 5: Run tests and analyze**

Run: `flutter test test/screens/transactions/transaction_form_screen_test.dart`
Expected: PASS

Run: `flutter analyze lib/screens/transactions/transaction_form_screen.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add app/lib/widgets/location_assistance_prompt_sheet.dart app/lib/screens/transactions/transaction_form_screen.dart app/test/screens/transactions/transaction_form_screen_test.dart
git commit -m "feat: prompt and suggest location help in transaction form"
```

### Task 3: Pre-Purchase Assistant Reuse and Usability Lift

**Files:**
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Create: `app/test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 1: Write the failing pre-purchase tests**

```dart
testWidgets('pre-purchase shows first-use location prompt only when needed', (
  tester,
) async {
  await tester.pumpWidget(buildPrePurchaseScreen(shouldPrompt: true));
  await tester.pumpAndSettle();

  expect(find.text('Use your location for smarter suggestions?'), findsOneWidget);
});

testWidgets('pre-purchase can suggest merchant and category when enabled', (
  tester,
) async {
  await tester.pumpWidget(buildPrePurchaseScreenWithSuggestions(
    merchants: ['Watami'],
    categories: ['Dining'],
  ));
  await tester.pumpAndSettle();

  expect(find.text('Watami'), findsOneWidget);
  expect(find.text('Dining'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/assistant/pre_purchase_screen_test.dart`
Expected: FAIL because pre-purchase does not currently know about the shared prompt or suggestion state.

- [ ] **Step 3: Implement the shared prompt trigger and guided suggestion UX**

```dart
@override
void initState() {
  super.initState();
  _currencyCode = ref.read(userPreferencesProvider).currency;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _maybePromptForLocationAssistance();
    _loadLocationSuggestionsIfEnabled();
  });
}
```

```dart
if (locationState.isEnabled && suggestionState.merchants.isNotEmpty) ...[
  Text('Nearby suggestions'),
  Wrap(
    spacing: 8,
    children: suggestionState.merchants.map((merchant) {
      return ActionChip(
        label: Text(merchant),
        onPressed: () => setState(() {
          _descriptionController.text = merchant;
        }),
      );
    }).toList(),
  ),
]
```

- [ ] **Step 4: Run tests and analyze**

Run: `flutter test test/screens/assistant/pre_purchase_screen_test.dart`
Expected: PASS

Run: `flutter analyze lib/screens/assistant/pre_purchase_screen.dart test/screens/assistant/pre_purchase_screen_test.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/assistant/pre_purchase_screen.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: reuse location assistance in pre-purchase"
```

### Task 4: Settings Control and Budget Nudge Alert

**Files:**
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Create: `app/test/screens/settings/settings_screen_location_test.dart`
- Modify: `app/lib/providers/alert_provider.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/providers/budget_providers.dart`

- [ ] **Step 1: Write the failing tests for settings and budget nudge**

```dart
testWidgets('settings can toggle smart location suggestions', (tester) async {
  await tester.pumpWidget(buildSettingsScreenWithLocation(enabled: false));
  await tester.pumpAndSettle();

  expect(find.text('Smart location suggestions'), findsOneWidget);
  await tester.tap(find.byType(SwitchListTile));
  await tester.pumpAndSettle();

  expect(fakeNotifier.enableCalls, 1);
});

testWidgets('saving an unbudgeted expense creates a local budget alert', (
  tester,
) async {
  await tester.pumpWidget(buildTransactionFormWithoutBudgetFor('Dining'));
  await tester.enterText(find.byType(TextField).first, '100');
  await tester.tap(find.text('Dining'));
  await tester.tap(find.text('Save Transaction'));
  await tester.pumpAndSettle();

  expect(find.textContaining('no budget'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/settings/settings_screen_location_test.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: FAIL because settings has no location toggle and transaction save does not emit a budget nudge alert.

- [ ] **Step 3: Add the Settings control**

```dart
SwitchListTile(
  secondary: const Icon(Icons.my_location_outlined),
  title: const Text('Smart location suggestions'),
  subtitle: Text(
    locationState.permissionDenied
        ? 'Use your current location to suggest merchants and categories. System permission may also need to be enabled.'
        : 'Use your current location to suggest merchants and categories.',
  ),
  value: locationState.isEnabled,
  onChanged: (value) async {
    if (value) {
      await ref.read(locationAssistanceProvider.notifier).enableFromSettings();
    } else {
      await ref.read(locationAssistanceProvider.notifier).disableFromSettings();
    }
  },
),
```

- [ ] **Step 4: Emit the in-app budget nudge after unbudgeted expenses**

```dart
if (!_isEditing && _isExpense && _selectedCategory != null) {
  final budgets = ref.read(budgetListProvider).budgets;
  final hasBudget = budgets.any(
    (budget) => budget.category.toLowerCase() == _selectedCategory!.toLowerCase(),
  );

  if (!hasBudget) {
    ref.read(localAlertsProvider.notifier).pushBudgetSuggestion(
      category: _selectedCategory!,
    );
  }
}
```

```dart
class LocalAlertsNotifier extends StateNotifier<List<AppAlert>> {
  LocalAlertsNotifier() : super(const []);

  void pushBudgetSuggestion({required String category}) {
    state = [
      AppAlert(
        id: 'budget-$category',
        type: 'budget_nudge',
        title: 'Add a budget for $category?',
        message: 'You logged an expense in $category without a matching budget.',
        isDismissed: false,
        createdAt: DateTime.now(),
      ),
      ...state.where((alert) => alert.id != 'budget-$category'),
    ];
  }
}
```

- [ ] **Step 5: Run tests and analyze**

Run: `flutter test test/screens/settings/settings_screen_location_test.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: PASS

Run: `flutter analyze lib/screens/settings/settings_screen.dart lib/providers/alert_provider.dart lib/screens/transactions/transaction_form_screen.dart test/screens/settings/settings_screen_location_test.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/settings/settings_screen.dart app/test/screens/settings/settings_screen_location_test.dart app/lib/providers/alert_provider.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/providers/budget_providers.dart
git commit -m "feat: add location settings and budget nudges"
```

### Task 5: Docs Refresh and Final Verification

**Files:**
- Modify: `docs/README.md`
- Modify: `docs/implementation-tasks.md`

- [ ] **Step 1: Write the doc updates**

```md
## Current Status

- Phase 1-3 core implementation is present in the app branch
- Onboarding profiling wizard is implemented
- Location-aware assistance is now part of the transaction-entry experience
```

```md
## Phase 2: Friction Reduction

- [x] Replace hidden location-only affordances with explicit smart suggestions
- [x] Reuse smart suggestions in Add Transaction and Pre-Purchase Assistant
- [x] Add first-use privacy prompt with Settings fallback
```

- [ ] **Step 2: Run targeted verification**

Run: `flutter test test/providers/location_assistance_provider_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/settings/settings_screen_location_test.dart`
Expected: `All tests passed!`

Run: `flutter analyze lib/providers/location_assistance_provider.dart lib/services/location_assistance_service.dart lib/screens/transactions/transaction_form_screen.dart lib/screens/assistant/pre_purchase_screen.dart lib/screens/settings/settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add docs/README.md docs/implementation-tasks.md
git commit -m "docs: refresh roadmap and location assistance status"
```

## Self-Review

- Spec coverage: prompt model, shared suggestions, settings control, budget nudge, and docs refresh each have a dedicated task.
- Placeholder scan: all tasks include concrete file paths, commands, and implementation/test snippets.
- Type consistency: the plan consistently uses `locationAssistanceProvider`, `LocationAssistanceService`, `LocationAssistancePromptSheet`, and `localAlertsProvider` names across tasks.

