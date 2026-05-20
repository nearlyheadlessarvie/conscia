# Conscia Category Icon Font Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a tight first batch of category SVG icons, add an in-repo preview surface, and prepare the category picker/inline rail to trial a curated icon-font-ready set before wider rollout.

**Architecture:** The trial stays deliberately narrow. SVG files become the editable source of truth under a dedicated assets folder, a lightweight preview surface is added for inspection before font generation, and the category icon catalog is reduced to a curated first set. Existing picker components continue to render through `CategoryIcons`, but the data source and preview path are tightened so the later font hookup can slot in cleanly.

**Tech Stack:** Flutter, Dart, existing category picker UI, asset-backed SVG source files, widget tests

---

## File Structure

- Create: `app/assets/icons/conscia-font-src/`
  - Source-of-truth SVG files for the first curated category icon set.
- Create: `app/lib/dev/category_icon_font_preview_screen.dart`
  - Lightweight preview surface for reviewing the curated SVG batch in-app before font generation.
- Create: `app/test/dev/category_icon_font_preview_screen_test.dart`
  - Coverage that the preview surface renders the expected curated set and labels.
- Modify: `app/pubspec.yaml`
  - Register the new SVG source asset folder for app/dev preview access.
- Modify: `app/lib/core/constants/category_icons.dart`
  - Reduce `iconOptions` to the curated trial set and add stable metadata/helpers for the trial batch.
- Modify: `app/lib/screens/settings/category_management_screen.dart`
  - Ensure both inline rail and full picker sheet use the curated set cleanly and are ready for the future font swap.
- Modify: `app/test/core/constants/category_icons_test.dart`
  - Update expectations from broad catalog to curated trial set.
- Modify: `app/test/screens/settings/category_management_screen_test.dart`
  - Assert both picker surfaces show the curated set behavior.

## Curated Trial Set

The initial trial set is:

- groceries
- dining
- transport
- shopping
- health
- bills
- education
- travel
- coffee
- subscriptions
- salary
- freelance
- business
- investment
- gift
- home
- utilities
- phone
- pets
- other

## Task 1: Add The SVG Source Batch

**Files:**
- Create: `app/assets/icons/conscia-font-src/groceries.svg`
- Create: `app/assets/icons/conscia-font-src/dining.svg`
- Create: `app/assets/icons/conscia-font-src/transport.svg`
- Create: `app/assets/icons/conscia-font-src/shopping.svg`
- Create: `app/assets/icons/conscia-font-src/health.svg`
- Create: `app/assets/icons/conscia-font-src/bills.svg`
- Create: `app/assets/icons/conscia-font-src/education.svg`
- Create: `app/assets/icons/conscia-font-src/travel.svg`
- Create: `app/assets/icons/conscia-font-src/coffee.svg`
- Create: `app/assets/icons/conscia-font-src/subscriptions.svg`
- Create: `app/assets/icons/conscia-font-src/salary.svg`
- Create: `app/assets/icons/conscia-font-src/freelance.svg`
- Create: `app/assets/icons/conscia-font-src/business.svg`
- Create: `app/assets/icons/conscia-font-src/investment.svg`
- Create: `app/assets/icons/conscia-font-src/gift.svg`
- Create: `app/assets/icons/conscia-font-src/home.svg`
- Create: `app/assets/icons/conscia-font-src/utilities.svg`
- Create: `app/assets/icons/conscia-font-src/phone.svg`
- Create: `app/assets/icons/conscia-font-src/pets.svg`
- Create: `app/assets/icons/conscia-font-src/other.svg`

- [ ] **Step 1: Create the source SVG directory**

Use `apply_patch` to create the icon source folder and the first SVG file placeholders with real content. Use a consistent monochrome SVG format and stable filenames. Each icon should use a fixed square viewBox and rounded stroke styling.

- [ ] **Step 2: Create the first 20 SVG files**

Create one SVG per curated icon. Each file should:

- use a square artboard such as `viewBox="0 0 24 24"`
- be monochrome
- use rounded joins/caps
- avoid tiny interior details
- prefer strong silhouettes

Use the existing painted glyphs only as references; do not attempt automated conversion.

- [ ] **Step 3: Sanity-check the file list**

Run:

```bash
Get-ChildItem app/assets/icons/conscia-font-src/*.svg | Select-Object -ExpandProperty Name
```

Expected:

- exactly the 20 curated SVG filenames

- [ ] **Step 4: Commit**

```bash
git add app/assets/icons/conscia-font-src
git commit -m "feat(app): add curated category icon svg sources"
```

## Task 2: Register Assets And Add Preview Surface

**Files:**
- Modify: `app/pubspec.yaml`
- Create: `app/lib/dev/category_icon_font_preview_screen.dart`
- Create: `app/test/dev/category_icon_font_preview_screen_test.dart`

- [ ] **Step 1: Write the failing preview test**

Create `app/test/dev/category_icon_font_preview_screen_test.dart` with a focused test that renders the preview screen and asserts:

- the preview title is present
- the curated icon labels are present
- the number of preview entries matches the curated trial set

Use a test like:

```dart
testWidgets('category icon font preview shows the curated trial set', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: CategoryIconFontPreviewScreen(),
    ),
  );

  expect(find.text('Category Icon Font Trial'), findsOneWidget);
  expect(find.text('Groceries'), findsOneWidget);
  expect(find.text('Dining'), findsOneWidget);
  expect(find.byKey(const ValueKey('category-icon-font-preview-grid')), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/dev/category_icon_font_preview_screen_test.dart
```

Expected:

- FAIL because `CategoryIconFontPreviewScreen` does not exist yet

- [ ] **Step 3: Register the new asset folder**

Modify `app/pubspec.yaml` to include:

```yaml
  assets:
    - assets/
    - assets/images/
    - assets/images/sprites/angel/
    - assets/images/sprites/devil/
    - assets/images/sprites/money/
    - assets/icons/conscia-font-src/
```

- [ ] **Step 4: Implement the preview screen**

Create `app/lib/dev/category_icon_font_preview_screen.dart` with:

- a simple `Scaffold`
- title `Category Icon Font Trial`
- short subtitle explaining that these are the SVG source files for the picker font trial
- a grid keyed as `category-icon-font-preview-grid`
- each cell showing:
  - a soft circular chip
  - an `SvgPicture.asset(...)` for the source SVG
  - the display label
  - the filename key

Prefer a simple static list derived from a helper in `CategoryIcons`, so the preview and picker share the same curated set metadata.

- [ ] **Step 5: Run the preview test to verify it passes**

Run:

```bash
flutter test test/dev/category_icon_font_preview_screen_test.dart
```

Expected:

- PASS

- [ ] **Step 6: Commit**

```bash
git add app/pubspec.yaml app/lib/dev/category_icon_font_preview_screen.dart app/test/dev/category_icon_font_preview_screen_test.dart
git commit -m "feat(app): add category icon font trial preview"
```

## Task 3: Curate The Category Icon Catalog

**Files:**
- Modify: `app/lib/core/constants/category_icons.dart`
- Modify: `app/test/core/constants/category_icons_test.dart`

- [ ] **Step 1: Write the failing category icon constant tests**

Update `app/test/core/constants/category_icons_test.dart` so it verifies:

- `CategoryIcons.iconOptions.length` is exactly `20`
- the curated keys are present
- removed broad-catalog keys like `gaming`, `beauty`, and `parking` are no longer present

Add a test like:

```dart
test('iconOptions is reduced to the curated font-trial set', () {
  final keys = CategoryIcons.iconOptions.map((option) => option.key).toList();

  expect(keys.length, 20);
  expect(keys, containsAll(<String>[
    'groceries',
    'dining',
    'transport',
    'shopping',
    'health',
    'bills',
    'education',
    'travel',
    'coffee',
    'subscriptions',
    'salary',
    'freelance',
    'business',
    'investment',
    'gift',
    'home',
    'utilities',
    'phone',
    'pets',
    'other',
  ]));
  expect(keys, isNot(contains('gaming')));
  expect(keys, isNot(contains('beauty')));
  expect(keys, isNot(contains('parking')));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/core/constants/category_icons_test.dart
```

Expected:

- FAIL because the catalog is still broad

- [ ] **Step 3: Reduce and structure the catalog**

Modify `app/lib/core/constants/category_icons.dart` to:

- reduce `iconOptions` to the curated trial set only
- keep stable keys and labels
- add a lightweight helper list or metadata structure that can also power the preview screen and later font mapping cleanly

Do not widen the API more than necessary. Keep the change small and trial-focused.

- [ ] **Step 4: Run the category icon tests to verify they pass**

Run:

```bash
flutter test test/core/constants/category_icons_test.dart
```

Expected:

- PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/constants/category_icons.dart app/test/core/constants/category_icons_test.dart
git commit -m "refactor(app): curate category icon font trial catalog"
```

## Task 4: Apply The Curated Set To Both Picker Surfaces

**Files:**
- Modify: `app/lib/screens/settings/category_management_screen.dart`
- Modify: `app/test/screens/settings/category_management_screen_test.dart`

- [ ] **Step 1: Write the failing picker tests**

Update `app/test/screens/settings/category_management_screen_test.dart` to assert:

- the compact rail shows curated icons only
- the full picker sheet shows the same curated set
- removed keys from the old broad catalog are absent from the sheet

Add a focused test like:

```dart
testWidgets('full icon picker uses the curated category icon font trial set', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CategoryManagementScreen()));
  await tester.pumpAndSettle();

  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();

  expect(find.text('Choose icon'), findsOneWidget);
  expect(find.text('Gaming'), findsNothing);
  expect(find.text('Beauty'), findsNothing);
  expect(find.text('Groceries'), findsOneWidget);
  expect(find.text('Dining'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/screens/settings/category_management_screen_test.dart
```

Expected:

- FAIL because the UI still exposes the wider set

- [ ] **Step 3: Keep both picker surfaces aligned to the curated set**

Modify `app/lib/screens/settings/category_management_screen.dart` only as needed so:

- the inline rail uses the curated `CategoryIcons.iconOptions`
- the full sheet uses the same curated set
- both surfaces remain visually stable and do not reference removed options

This task is not for final layout polish. It is only to make the curated trial set the single source for both picker surfaces.

- [ ] **Step 4: Run the picker tests to verify they pass**

Run:

```bash
flutter test test/screens/settings/category_management_screen_test.dart
```

Expected:

- PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/settings/category_management_screen.dart app/test/screens/settings/category_management_screen_test.dart
git commit -m "feat(app): trial curated category icon set in picker"
```

## Task 5: Final Verification

**Files:**
- Verify all modified files from Tasks 1–4

- [ ] **Step 1: Run targeted trial tests**

Run:

```bash
flutter test test/dev/category_icon_font_preview_screen_test.dart test/core/constants/category_icons_test.dart test/screens/settings/category_management_screen_test.dart
```

Expected:

- PASS

- [ ] **Step 2: Run analyzer**

Run:

```bash
flutter analyze
```

Expected:

- `No issues found!`

- [ ] **Step 3: Run full Flutter test suite**

Run:

```bash
flutter test
```

Expected:

- PASS

- [ ] **Step 4: Commit verification-safe final state**

```bash
git status --short
```

Expected:

- clean working tree, or only intentional uncommitted artifacts discussed with the user

## Spec Coverage Check

- SVG source batch: covered by Task 1
- source-of-truth asset folder: covered by Task 1 and Task 2
- preview surface before font packaging: covered by Task 2
- curated trial set only: covered by Task 3 and Task 4
- both picker surfaces using the trial set: covered by Task 4
- later manual FlutterIcon packaging path preserved: enabled by Tasks 1–4 without prematurely wiring a generated font

