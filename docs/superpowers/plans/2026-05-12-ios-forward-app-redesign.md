# iOS-Forward App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Flutter app UI around the approved iOS-forward Conscia v2 design system without inventing new product behavior or silently expanding backend scope.

**Architecture:** Add a small set of reusable UI primitives first, then migrate the navigation shell, forms, grouped-card lists, overlays, and screen families onto those primitives in batches. Keep existing routing, providers, and product logic intact; limit data-model changes to wording and presentation only, explicitly deferring name/profile-photo work.

**Tech Stack:** Flutter, Material 3 theme extensions, Riverpod, GoRouter, Flutter widget tests

---

## File Structure

### Core theme and primitives

- Modify: `app/lib/core/theme/app_colors.dart`
- Modify: `app/lib/core/theme/app_theme.dart`
- Create: `app/lib/widgets/floating_dock_nav.dart`
- Create: `app/lib/widgets/grouped_list_card.dart`
- Create: `app/lib/widgets/floating_label_text_field.dart`
- Create: `app/lib/widgets/inline_notice.dart`
- Create: `app/lib/widgets/selection_card_group.dart`

### Shell and shared scaffolding

- Modify: `app/lib/widgets/main_shell.dart`
- Modify: `app/lib/widgets/hero_screen_scaffold.dart`
- Modify: `app/lib/widgets/empty_state.dart`
- Modify: `app/lib/widgets/scope_selector.dart`
- Modify: `app/lib/widgets/selection_chip_group.dart`

### Onboarding and auth

- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_up_screen.dart`
- Modify: `app/lib/screens/onboarding/verify_email_screen.dart`
- Modify: `app/lib/screens/onboarding/setup_screen.dart`
- Modify: `app/lib/screens/onboarding/spending_profile_screen.dart`
- Modify: `app/lib/screens/onboarding/about_you_screen.dart`
- Modify: `app/lib/screens/onboarding/suggested_budgets_screen.dart`

### Core screens

- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/receipts/receipt_scanner_screen.dart`
- Modify: `app/lib/screens/receipts/receipt_review_screen.dart`
- Modify: `app/lib/screens/insights/insights_screen.dart`
- Modify: `app/lib/screens/journey/conscience_journey_screen.dart`

### Settings, family, and utility screens

- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/settings/profile_screen.dart`
- Modify: `app/lib/screens/settings/category_management_screen.dart`
- Modify: `app/lib/screens/settings/service_status_screen.dart`
- Modify: `app/lib/screens/settings/widgets/subscription_sheet.dart`
- Modify: `app/lib/screens/budgets/budgets_screen.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Modify: `app/lib/screens/family/family_space_screen.dart`
- Modify: `app/lib/screens/family/family_setup_screen.dart`
- Modify: `app/lib/screens/family/family_invites_screen.dart`
- Modify: `app/lib/screens/family/family_members_screen.dart`
- Modify: `app/lib/screens/family/family_space_settings_screen.dart`
- Modify: `app/lib/widgets/currency_picker_sheet.dart`
- Modify: `app/lib/widgets/locale_picker_sheet.dart`

### Tests

- Modify: `app/test/widgets/main_shell_test.dart`
- Create: `app/test/widgets/floating_label_text_field_test.dart`
- Create: `app/test/widgets/grouped_list_card_test.dart`
- Create: `app/test/widgets/selection_card_group_test.dart`
- Modify: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_list_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_detail_screen_test.dart`
- Modify: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Modify: `app/test/screens/insights/insights_screen_test.dart`
- Modify: `app/test/screens/journey/conscience_journey_screen_test.dart`
- Modify: `app/test/screens/settings/settings_screen_location_test.dart`
- Modify: `app/test/screens/settings/profile_screen_test.dart`
- Modify: `app/test/screens/settings/category_management_screen_test.dart`
- Modify: `app/test/screens/settings/subscription_sheet_test.dart`
- Modify: `app/test/screens/family/family_space_screen_test.dart`
- Modify: `app/test/screens/family/family_invites_screen_test.dart`
- Modify: `app/test/screens/family/family_members_screen_test.dart`
- Modify: `app/test/screens/receipts/receipt_scanner_screen_test.dart`
- Modify: `app/test/screens/receipts/receipt_review_screen_test.dart`

## Task 1: Build The Shared Design Foundation

**Files:**
- Create: `app/lib/widgets/floating_label_text_field.dart`
- Create: `app/lib/widgets/grouped_list_card.dart`
- Create: `app/lib/widgets/inline_notice.dart`
- Create: `app/lib/widgets/selection_card_group.dart`
- Modify: `app/lib/core/theme/app_colors.dart`
- Modify: `app/lib/core/theme/app_theme.dart`
- Test: `app/test/widgets/floating_label_text_field_test.dart`
- Test: `app/test/widgets/grouped_list_card_test.dart`
- Test: `app/test/widgets/selection_card_group_test.dart`

- [ ] **Step 1: Write the failing widget tests for the new primitives**

```dart
testWidgets('FloatingLabelTextField shows raised label when text is present',
    (tester) async {
  final controller = TextEditingController(text: 'PHP 350');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FloatingLabelTextField(
          controller: controller,
          label: 'Amount',
        ),
      ),
    ),
  );

  expect(find.text('Amount'), findsOneWidget);
  expect(find.text('PHP 350'), findsOneWidget);
});

testWidgets('GroupedListCard inserts separators between children',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GroupedListCard(
          children: const [
            Text('One'),
            Text('Two'),
            Text('Three'),
          ],
        ),
      ),
    ),
  );

  expect(find.text('One'), findsOneWidget);
  expect(find.text('Two'), findsOneWidget);
  expect(find.byType(Divider), findsNWidgets(2));
});

testWidgets('SelectionCardGroup shows radio dots for radio semantics',
    (tester) async {
  String? value = 'saver';

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionCardGroup<String>(
          value: value,
          options: const ['saver', 'balanced'],
          semantics: SelectionCardSemantics.radio,
          titleBuilder: (option) => option,
          subtitleBuilder: (_) => 'subtitle',
          onChanged: (next) => value = next,
        ),
      ),
    ),
  );

  expect(find.byKey(const ValueKey('selection-indicator-saver')), findsOneWidget);
});
```

- [ ] **Step 2: Run the widget tests to verify they fail**

Run:

```bash
flutter test app/test/widgets/floating_label_text_field_test.dart app/test/widgets/grouped_list_card_test.dart app/test/widgets/selection_card_group_test.dart -r compact
```

Expected:

```text
00:00 +0 -3: Some tests failed.
Error: Target of URI doesn't exist: 'package:conscia_app/widgets/floating_label_text_field.dart'
```

- [ ] **Step 3: Add the new widgets and wire the v2 tokens into theme**

```dart
// app/lib/widgets/floating_label_text_field.dart
class FloatingLabelTextField extends StatelessWidget {
  const FloatingLabelTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.keyboardType,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = controller.text.trim().isNotEmpty;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 8),
          decoration: BoxDecoration(
            color: hasError ? theme.colorScheme.surface : const Color.fromRGBO(118, 118, 128, 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? const Color(0xFFE53935) : const Color(0xFFE1E3EF),
              width: hasError ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasError
                            ? const Color(0xFFE53935)
                            : hasValue
                                ? const Color(0xFF6F687A)
                                : const Color(0xFF9B94A8),
                      ),
                    ),
                    if (hasValue) ...[
                      const SizedBox(height: 6),
                      Text(controller.text, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            '⚠ $errorText',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFE53935)),
          ),
        ],
      ],
    );
  }
}

// app/lib/widgets/grouped_list_card.dart
class GroupedListCard extends StatelessWidget {
  const GroupedListCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Padding(
                padding: padding.add(const EdgeInsets.symmetric(vertical: 14)),
                child: children[i],
              ),
              if (i < children.length - 1)
                const Divider(height: 1, thickness: 1),
            ],
          ],
        ),
      ),
    );
  }
}

// app/lib/widgets/selection_card_group.dart
enum SelectionCardSemantics { radio, check }
```

- [ ] **Step 4: Re-run the widget tests and the existing shell scaffold tests**

Run:

```bash
flutter test app/test/widgets/floating_label_text_field_test.dart app/test/widgets/grouped_list_card_test.dart app/test/widgets/selection_card_group_test.dart app/test/widgets/hero_screen_scaffold_test.dart -r compact
```

Expected:

```text
00:00 +4: All tests passed!
```

- [ ] **Step 5: Commit the foundation layer**

```bash
git add app/lib/core/theme/app_colors.dart app/lib/core/theme/app_theme.dart app/lib/widgets/floating_label_text_field.dart app/lib/widgets/grouped_list_card.dart app/lib/widgets/inline_notice.dart app/lib/widgets/selection_card_group.dart app/test/widgets/floating_label_text_field_test.dart app/test/widgets/grouped_list_card_test.dart app/test/widgets/selection_card_group_test.dart
git commit -m "feat: add ios-forward design primitives"
```

## Task 2: Replace The Bottom Shell With The Floating Dock

**Files:**
- Create: `app/lib/widgets/floating_dock_nav.dart`
- Modify: `app/lib/widgets/main_shell.dart`
- Test: `app/test/widgets/main_shell_test.dart`

- [ ] **Step 1: Add failing tests for the icon-only floating dock**

```dart
testWidgets('MainShell renders floating dock without text labels',
    (tester) async {
  await _pumpShell(tester);

  expect(find.text('Home'), findsNothing);
  expect(find.text('Transactions'), findsNothing);
  expect(find.byKey(const ValueKey('floating-dock-nav')), findsOneWidget);
});

testWidgets('MainShell keeps the scan action centered and emphasized',
    (tester) async {
  await _pumpShell(tester);

  expect(find.byKey(const ValueKey('floating-dock-scan-action')), findsOneWidget);
});
```

- [ ] **Step 2: Run the shell tests and confirm the current label-based nav fails**

Run:

```bash
flutter test app/test/widgets/main_shell_test.dart -r compact
```

Expected:

```text
Expected: no matching candidates
Actual: _TextWidgetFinder:<Found 1 widget with text "Home">
```

- [ ] **Step 3: Implement the new dock widget and swap MainShell to use it**

```dart
// app/lib/widgets/floating_dock_nav.dart
class FloatingDockNav extends StatelessWidget {
  const FloatingDockNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      key: const ValueKey('floating-dock-nav'),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E3EF)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(24, 36, 92, 0.12),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DockIcon(index: 0, currentIndex: currentIndex, icon: AppIcons.home, onTap: onDestinationSelected),
          _DockIcon(index: 1, currentIndex: currentIndex, icon: AppIcons.transactions, onTap: onDestinationSelected),
          _ScanDockButton(currentIndex: currentIndex, onTap: () => onDestinationSelected(2)),
          _DockIcon(index: 3, currentIndex: currentIndex, icon: AppIcons.assistant, onTap: onDestinationSelected),
          _DockIcon(index: 4, currentIndex: currentIndex, icon: AppIcons.settings, onTap: onDestinationSelected),
        ],
      ),
    );
  }
}

// app/lib/widgets/main_shell.dart
bottomNavigationBar: FloatingDockNav(
  currentIndex: currentIndex,
  onDestinationSelected: (i) {
    if (i == _mobileScanIndex) {
      _onDestinationSelected(context, i);
      return;
    }
    _onDestinationSelected(context, i);
  },
),
```

- [ ] **Step 4: Run the dock tests and confirm route switching still works**

Run:

```bash
flutter test app/test/widgets/main_shell_test.dart -r compact
```

Expected:

```text
00:00 +5: All tests passed!
```

- [ ] **Step 5: Commit the shell migration**

```bash
git add app/lib/widgets/floating_dock_nav.dart app/lib/widgets/main_shell.dart app/test/widgets/main_shell_test.dart
git commit -m "feat: redesign app shell with floating dock"
```

## Task 3: Migrate Auth And Onboarding To v2 Form Semantics

**Files:**
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_up_screen.dart`
- Modify: `app/lib/screens/onboarding/verify_email_screen.dart`
- Modify: `app/lib/screens/onboarding/setup_screen.dart`
- Modify: `app/lib/screens/onboarding/spending_profile_screen.dart`
- Modify: `app/lib/screens/onboarding/about_you_screen.dart`
- Modify: `app/lib/screens/onboarding/suggested_budgets_screen.dart`
- Modify: `app/lib/widgets/locale_picker_sheet.dart`
- Test: `app/test/screens/onboarding/sign_in_screen_test.dart`
- Test: `app/test/screens/onboarding/sign_up_screen_test.dart`
- Test: `app/test/screens/onboarding/verify_email_screen_test.dart`

- [ ] **Step 1: Add failing tests for inline auth errors and region-format wording**

```dart
testWidgets('SignInScreen shows inline auth error note instead of dismissible banner',
    (tester) async {
  await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

  final state = tester.state(find.byType(SignInScreen)) as dynamic;
  state.setState(() => state._errorMessage = 'Invalid username or password.');
  await tester.pump();

  expect(find.text('Dismiss'), findsNothing);
  expect(find.text('Invalid username or password.'), findsOneWidget);
});

testWidgets('SetupScreen describes locale as region format', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SetupScreen())));

  expect(find.text('Region Format'), findsWidgets);
  expect(find.textContaining('App language stays in English'), findsOneWidget);
});
```

- [ ] **Step 2: Run the onboarding tests and verify current banner wording fails**

Run:

```bash
flutter test app/test/screens/onboarding/sign_in_screen_test.dart app/test/screens/onboarding/sign_up_screen_test.dart app/test/screens/onboarding/verify_email_screen_test.dart -r compact
```

Expected:

```text
Expected: no matching candidates
Actual: _TextWidgetFinder:<Found 1 widget with text "Dismiss">
```

- [ ] **Step 3: Replace banners with InlineNotice and convert profile questions to radio-card groups**

```dart
// app/lib/screens/onboarding/sign_in_screen.dart
if (_errorMessage != null) ...[
  InlineNotice.error(
    message: _errorMessage!,
    icon: Icons.lock_outline_rounded,
  ),
  const SizedBox(height: 16),
],

FloatingLabelTextField(
  controller: _emailController,
  label: 'Email',
  errorText: _emailFieldError,
  prefix: const Icon(Icons.email_outlined),
),

// app/lib/screens/onboarding/spending_profile_screen.dart
SelectionCardGroup<String>(
  value: _selectedProfile,
  semantics: SelectionCardSemantics.radio,
  options: const ['saver', 'balanced', 'free_spender'],
  titleBuilder: _titleForProfile,
  subtitleBuilder: _subtitleForProfile,
  trailingBuilder: SelectionCardIndicators.radio,
  onChanged: (value) => setState(() => _selectedProfile = value),
)

// app/lib/screens/onboarding/setup_screen.dart
Text('Region Format', style: theme.textTheme.titleSmall),
Text(
  'Changes how numbers and dates are shown. App language stays in English.',
  style: theme.textTheme.bodySmall,
)
```

- [ ] **Step 4: Re-run onboarding tests plus the setup screen widget tests**

Run:

```bash
flutter test app/test/screens/onboarding/sign_in_screen_test.dart app/test/screens/onboarding/sign_up_screen_test.dart app/test/screens/onboarding/verify_email_screen_test.dart app/test/screens/onboarding/onboarding_flow_test.dart -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 5: Commit the onboarding/auth migration**

```bash
git add app/lib/screens/onboarding/sign_in_screen.dart app/lib/screens/onboarding/sign_up_screen.dart app/lib/screens/onboarding/verify_email_screen.dart app/lib/screens/onboarding/setup_screen.dart app/lib/screens/onboarding/spending_profile_screen.dart app/lib/screens/onboarding/about_you_screen.dart app/lib/screens/onboarding/suggested_budgets_screen.dart app/lib/widgets/locale_picker_sheet.dart app/test/screens/onboarding/sign_in_screen_test.dart app/test/screens/onboarding/sign_up_screen_test.dart app/test/screens/onboarding/verify_email_screen_test.dart
git commit -m "feat: migrate onboarding and auth to ios-forward forms"
```

## Task 4: Migrate Utility Screens To Grouped Cards And Floating Fields

**Files:**
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/receipts/receipt_scanner_screen.dart`
- Modify: `app/lib/screens/receipts/receipt_review_screen.dart`
- Modify: `app/lib/screens/budgets/budgets_screen.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Modify: `app/lib/screens/settings/category_management_screen.dart`
- Modify: `app/lib/screens/settings/service_status_screen.dart`
- Modify: `app/lib/widgets/currency_picker_sheet.dart`
- Modify: `app/lib/widgets/locale_picker_sheet.dart`
- Test: `app/test/screens/transactions/transaction_list_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/receipts/receipt_scanner_screen_test.dart`
- Test: `app/test/screens/receipts/receipt_review_screen_test.dart`
- Test: `app/test/screens/budgets/widgets/budget_form_sheet_test.dart`
- Test: `app/test/screens/settings/category_management_screen_test.dart`
- Test: `app/test/screens/settings/service_status_screen_test.dart`

- [ ] **Step 1: Add failing tests for grouped transaction/date cards, budget category select, and region-format check rows**

```dart
testWidgets('TransactionListScreen groups rows under date sections', (tester) async {
  await pumpTransactionListScreen(tester);
  expect(find.byType(GroupedListCard), findsWidgets);
});

testWidgets('BudgetFormSheet shows category as a field-owned select label', (tester) async {
  await tester.pumpWidget(testBudgetFormSheet());
  expect(find.text('Category'), findsOneWidget);
  expect(find.text('Chosen category'), findsNothing);
});

testWidgets('LocalePickerSheet marks the selected row with a check', (tester) async {
  await tester.pumpWidget(testLocalePickerSheet(selectedLocale: 'en_US'));
  expect(find.text('Philippines / US'), findsOneWidget);
  expect(find.text('✓'), findsOneWidget);
});
```

- [ ] **Step 2: Run the utility screen tests to verify current layouts fail**

Run:

```bash
flutter test app/test/screens/transactions/transaction_list_screen_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/receipts/receipt_scanner_screen_test.dart app/test/screens/receipts/receipt_review_screen_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/settings/category_management_screen_test.dart app/test/screens/settings/service_status_screen_test.dart -r compact
```

Expected:

```text
Some tests failed because GroupedListCard and field-owned labels are not present yet.
```

- [ ] **Step 3: Refactor utility screens onto grouped cards and field-owned labels**

```dart
// app/lib/screens/transactions/transaction_list_screen.dart
GroupedListCard(
  children: transactionsForDate.map((tx) {
    return TransactionRowTile(
      transaction: tx,
      showBadgeMeta: true,
    );
  }).toList(),
)

// app/lib/screens/budgets/widgets/budget_form_sheet.dart
FloatingLabelTextField(
  controller: _categoryDisplayController,
  label: 'Category',
  readOnly: true,
  suffix: const Icon(Icons.expand_more_rounded),
  onTap: _openCategoryPicker,
)

// app/lib/widgets/locale_picker_sheet.dart
static const _formats = [
  ('en_US', 'Philippines / US', '1,234,567.89'),
  ('de_DE', 'European', '1.234.567,89'),
  ('fr_FR', 'French / Swiss', '1 234 567,89'),
  ('en_IN', 'Indian', '12,34,567.89'),
];
```

- [ ] **Step 4: Re-run the utility test suite**

Run:

```bash
flutter test app/test/screens/transactions/transaction_list_screen_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/receipts/receipt_scanner_screen_test.dart app/test/screens/receipts/receipt_review_screen_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/settings/category_management_screen_test.dart app/test/screens/settings/service_status_screen_test.dart -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 5: Commit the utility screen migration**

```bash
git add app/lib/screens/transactions/transaction_list_screen.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/receipts/receipt_scanner_screen.dart app/lib/screens/receipts/receipt_review_screen.dart app/lib/screens/budgets/budgets_screen.dart app/lib/screens/budgets/widgets/budget_form_sheet.dart app/lib/screens/settings/category_management_screen.dart app/lib/screens/settings/service_status_screen.dart app/lib/widgets/currency_picker_sheet.dart app/lib/widgets/locale_picker_sheet.dart app/test/screens/transactions/transaction_list_screen_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/receipts/receipt_scanner_screen_test.dart app/test/screens/receipts/receipt_review_screen_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/settings/category_management_screen_test.dart app/test/screens/settings/service_status_screen_test.dart
git commit -m "feat: redesign utility screens with grouped cards"
```

## Task 5: Apply The Emotion-Tier Treatment To Home, Assistant, And Transaction Detail

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Add failing tests for hero-tier surfaces and mascot preservation**

```dart
testWidgets('PrePurchaseScreen keeps mascot-led hero content', (tester) async {
  await pumpPrePurchaseScreen(tester);
  expect(find.byType(ConsciaAlterEgoMotion), findsOneWidget);
});

testWidgets('TransactionDetailScreen still exposes reflection action', (tester) async {
  await pumpTransactionDetailScreen(tester);
  expect(find.textContaining('Reflect'), findsWidgets);
});
```

- [ ] **Step 2: Run the assistant/detail tests and verify the new grouped/hero expectations are missing**

Run:

```bash
flutter test app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart app/test/screens/dashboard/dashboard_alerts_test.dart -r compact
```

Expected:

```text
Some tests failed because the redesigned hero/grouped surfaces are not present yet.
```

- [ ] **Step 3: Refactor these screens without changing their product meaning**

```dart
// app/lib/screens/dashboard/dashboard_screen.dart
Widget _buildHeroSummaryCard(...) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF18245C), Color(0xFF35509C)],
      ),
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    child: ...
  );
}

// app/lib/screens/assistant/pre_purchase_screen.dart
InlineNotice.info(
  icon: MascotSpriteFrame(
    atlas: angelMascotAtlas,
    frameName: '4_win.png',
    width: 40,
  ),
  message: 'Both sides are standing by. What are you thinking of buying?',
)

// app/lib/screens/transactions/transaction_detail_screen.dart
GroupedListCard(
  children: [
    _TransactionMetadataRow(...),
    _TransactionMetadataRow(...),
  ],
)
```

- [ ] **Step 4: Re-run the screen tests plus a broad smoke batch**

Run:

```bash
flutter test app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart app/test/screens/dashboard/dashboard_alerts_test.dart app/test/screens/dashboard/recent_transaction_tile_test.dart -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 5: Commit the first emotion-tier batch**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "feat: redesign home assistant and transaction detail"
```

## Task 6: Migrate Journey, Insights, Profile, Settings, And Shared Conscia

**Files:**
- Modify: `app/lib/screens/journey/conscience_journey_screen.dart`
- Modify: `app/lib/screens/insights/insights_screen.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/settings/profile_screen.dart`
- Modify: `app/lib/screens/family/family_space_screen.dart`
- Modify: `app/lib/screens/family/family_setup_screen.dart`
- Modify: `app/lib/screens/family/family_invites_screen.dart`
- Modify: `app/lib/screens/family/family_members_screen.dart`
- Modify: `app/lib/screens/family/family_space_settings_screen.dart`
- Modify: `app/lib/screens/settings/widgets/subscription_sheet.dart`
- Test: `app/test/screens/journey/conscience_journey_screen_test.dart`
- Test: `app/test/screens/insights/insights_screen_test.dart`
- Test: `app/test/screens/settings/settings_screen_location_test.dart`
- Test: `app/test/screens/settings/profile_screen_test.dart`
- Test: `app/test/screens/settings/subscription_sheet_test.dart`
- Test: `app/test/screens/family/family_space_screen_test.dart`
- Test: `app/test/screens/family/family_invites_screen_test.dart`
- Test: `app/test/screens/family/family_members_screen_test.dart`

- [ ] **Step 1: Add failing tests for achievements strip, non-invented insights framing, and Shared Conscia grouped layout**

```dart
testWidgets('Journey screen shows achievements strip with locked mysteries',
    (tester) async {
  await pumpJourneyScreen(tester);
  expect(find.text('Achievements'), findsOneWidget);
  expect(find.text('All ›'), findsOneWidget);
  expect(find.text('???'), findsWidgets);
});

testWidgets('Insights screen keeps existing sections and adds no fake dashboard metrics',
    (tester) async {
  await pumpInsightsScreen(tester);
  expect(find.text('Merchant spotlight'), findsOneWidget);
  expect(find.text('Your regret pulse'), findsWidgets);
});

testWidgets('Family space groups recent activity in a single card',
    (tester) async {
  await pumpFamilySpaceScreen(tester);
  expect(find.byType(GroupedListCard), findsWidgets);
});
```

- [ ] **Step 2: Run the journey/insights/family/settings tests and capture failures**

Run:

```bash
flutter test app/test/screens/journey/conscience_journey_screen_test.dart app/test/screens/insights/insights_screen_test.dart app/test/screens/settings/settings_screen_location_test.dart app/test/screens/settings/profile_screen_test.dart app/test/screens/family/family_space_screen_test.dart app/test/screens/family/family_invites_screen_test.dart app/test/screens/family/family_members_screen_test.dart -r compact
```

Expected:

```text
Some tests failed because achievements strip, grouped family rows, and settings grouping are not implemented yet.
```

- [ ] **Step 3: Refactor these screens using the approved grouped and hero patterns**

```dart
// app/lib/screens/journey/conscience_journey_screen.dart
Widget _buildAchievementsStrip(List<ConscienceBadge> badges) {
  return SizedBox(
    height: 108,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _AchievementTile.unlocked(...),
        _AchievementTile.locked(),
      ],
    ),
  );
}

// app/lib/screens/insights/insights_screen.dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _InsightsHeroSummary(summary: summary),
    _InsightFeedSection(...),
    _MerchantSpotlightSection(...),
    _CategoryTrendSection(...),
  ],
);

// app/lib/screens/settings/settings_screen.dart
GroupedListCard(
  children: [
    _SettingsRow(title: 'AI Personality', ...),
    _SettingsRow(title: 'Location Assistance', ...),
    _SettingsRow(title: 'Currency & Region Format', ...),
  ],
)
```

- [ ] **Step 4: Re-run the screen family tests**

Run:

```bash
flutter test app/test/screens/journey/conscience_journey_screen_test.dart app/test/screens/insights/insights_screen_test.dart app/test/screens/settings/settings_screen_location_test.dart app/test/screens/settings/profile_screen_test.dart app/test/screens/settings/subscription_sheet_test.dart app/test/screens/family/family_space_screen_test.dart app/test/screens/family/family_invites_screen_test.dart app/test/screens/family/family_members_screen_test.dart -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 5: Commit the emotion-tier/family/settings batch**

```bash
git add app/lib/screens/journey/conscience_journey_screen.dart app/lib/screens/insights/insights_screen.dart app/lib/screens/settings/settings_screen.dart app/lib/screens/settings/profile_screen.dart app/lib/screens/family/family_space_screen.dart app/lib/screens/family/family_setup_screen.dart app/lib/screens/family/family_invites_screen.dart app/lib/screens/family/family_members_screen.dart app/lib/screens/family/family_space_settings_screen.dart app/lib/screens/settings/widgets/subscription_sheet.dart app/test/screens/journey/conscience_journey_screen_test.dart app/test/screens/insights/insights_screen_test.dart app/test/screens/settings/settings_screen_location_test.dart app/test/screens/settings/profile_screen_test.dart app/test/screens/settings/subscription_sheet_test.dart app/test/screens/family/family_space_screen_test.dart app/test/screens/family/family_invites_screen_test.dart app/test/screens/family/family_members_screen_test.dart
git commit -m "feat: redesign journey insights settings and family screens"
```

## Task 7: Finish Overlays, Dialogs, And Cross-Screen State Cleanup

**Files:**
- Modify: `app/lib/widgets/currency_picker_sheet.dart`
- Modify: `app/lib/widgets/locale_picker_sheet.dart`
- Modify: `app/lib/screens/settings/widgets/subscription_sheet.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/settings/category_management_screen.dart`
- Test: `app/test/screens/settings/subscription_sheet_test.dart`
- Test: `app/test/screens/budgets/widgets/budget_form_sheet_test.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Add failing tests for sheet consistency and iOS-ish destructive alerts**

```dart
testWidgets('BudgetFormSheet uses field-owned labels', (tester) async {
  await tester.pumpWidget(testBudgetFormSheet());
  expect(find.text('Monthly Cap'), findsOneWidget);
});

testWidgets('Transaction detail delete dialog uses iOS-style actions',
    (tester) async {
  await pumpTransactionDetailScreen(tester);
  // trigger dialog here
  expect(find.text('Delete this transaction?'), findsOneWidget);
  expect(find.text('Cancel'), findsOneWidget);
  expect(find.text('Delete'), findsOneWidget);
});
```

- [ ] **Step 2: Run the overlay tests and verify the current dialog/sheet patterns fail**

Run:

```bash
flutter test app/test/screens/settings/subscription_sheet_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart -r compact
```

Expected:

```text
Some tests failed because the old sheet and dialog patterns are still present.
```

- [ ] **Step 3: Standardize the remaining overlays and destructive confirmations**

```dart
// app/lib/screens/transactions/transaction_detail_screen.dart
builder: (ctx) => AlertDialog.adaptive(
  title: const Text('Delete this transaction?'),
  content: const Text('This can’t be undone.'),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(ctx).pop(false),
      child: const Text('Cancel'),
    ),
    TextButton(
      onPressed: () => Navigator.of(ctx).pop(true),
      child: const Text('Delete'),
    ),
  ],
)

// app/lib/widgets/locale_picker_sheet.dart
ListTile(
  title: const Text('European'),
  subtitle: const Text('1.234.567,89'),
  trailing: isSelected ? const Icon(Icons.check) : null,
)
```

- [ ] **Step 4: Run the overlay-focused tests and a final broad smoke suite**

Run:

```bash
flutter test app/test/screens/settings/subscription_sheet_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart app/test/widgets/main_shell_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/insights/insights_screen_test.dart -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 5: Commit the overlay cleanup**

```bash
git add app/lib/widgets/currency_picker_sheet.dart app/lib/widgets/locale_picker_sheet.dart app/lib/screens/settings/widgets/subscription_sheet.dart app/lib/screens/budgets/widgets/budget_form_sheet.dart app/lib/screens/transactions/transaction_detail_screen.dart app/lib/screens/settings/category_management_screen.dart app/test/screens/settings/subscription_sheet_test.dart app/test/screens/budgets/widgets/budget_form_sheet_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "feat: standardize ios-forward sheets and dialogs"
```

## Task 8: Final Regression Sweep And Scope Guardrails

**Files:**
- Modify: `docs/superpowers/specs/2026-05-12-ios-forward-app-redesign-design.md` only if implementation reality forces a minor wording correction
- Modify: any touched tests if golden expectations or semantics changed during final integration

- [ ] **Step 1: Add a final regression checklist comment to the active branch notes**

```md
- Floating dock shows no text labels
- Mascot sprite art is preserved on emotion-tier screens
- Grouped list cards replace fragmented row cards on utility surfaces
- Auth errors are inline, not dismissible banners
- Locale wording never implies app-language switching
- No user-name or profile-photo backend work slipped into the UI branch
```

- [ ] **Step 2: Run the broad Flutter test suite for all touched areas**

Run:

```bash
flutter test app/test/widgets app/test/screens/onboarding app/test/screens/transactions app/test/screens/assistant app/test/screens/insights app/test/screens/journey app/test/screens/settings app/test/screens/family app/test/screens/receipts app/test/screens/budgets -r compact
```

Expected:

```text
00:00 +N: All tests passed!
```

- [ ] **Step 3: Run Flutter analyze**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 4: Manually verify the highest-risk screens**

Run:

```bash
flutter run -d <simulator-or-device>
```

Verify:

```text
Home, Assistant, Journey, Transaction Detail, Shared Conscia, Sign In, Settings, Transactions List, Add Transaction, Scan Receipt
```

- [ ] **Step 5: Commit the final polish and test alignment**

```bash
git add app/lib app/test
git commit -m "test: finalize ios-forward redesign regression coverage"
```

## Spec Coverage Check

- Theme, dock, form semantics, grouped-list rules, mascot preservation, locale wording, and radio-vs-check semantics are covered in Tasks 1-3.
- Utility surfaces, pickers, and grouped-card list conversions are covered in Task 4 and Task 7.
- Emotion-tier screens are covered in Tasks 5 and 6.
- Remaining family/settings/journey/insights screens are covered in Task 6.
- Empty/loading/error/dialog states are covered in Tasks 4, 7, and 8.
- Explicit backend-impacting items (`name`, `profilePhotoUrl`) are intentionally excluded from implementation and guarded in Task 8.

## Placeholder Scan

- No `TBD`, `TODO`, or “implement later” placeholders remain.
- Commands, files, and test targets are explicit.
- The plan does not rely on unspecified backend changes.

## Type Consistency Check

- `FloatingLabelTextField` is the field primitive used across form tasks.
- `GroupedListCard` is the grouped-row container used across utility tasks.
- `SelectionCardGroup` plus `SelectionCardSemantics.radio` handles radio-card surfaces.
- Locale UI wording consistently uses `Region Format` while still mapping to the existing locale contract.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-12-ios-forward-app-redesign.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
