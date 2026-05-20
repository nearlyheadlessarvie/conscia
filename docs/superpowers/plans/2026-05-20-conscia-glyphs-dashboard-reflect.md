# Conscia Glyphs And Dashboard Reflect Facelift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modularize and expand the Conscia glyph system, then use it to redesign the dashboard `Reflect` section into a richer featured editorial card with a gentle subtitle and stacked queue hint.

**Architecture:** Keep `ConsciaGlyph` as the stable public API while splitting kinds, mapping, and painter logic into focused files under a new `widgets/glyphs` structure. Then evolve `RegretPromptCard` into the featured reflection card and update `DashboardScreen` to render one featured prompt plus a subtle queued-moments hint.

**Tech Stack:** Flutter, Dart, CustomPainter, Flutter widget tests, golden tests, Riverpod, existing dashboard widgets

---

## File Structure

### Create

- `app/lib/widgets/glyphs/conscia_glyph_kind.dart`
- `app/lib/widgets/glyphs/conscia_glyph_mapper.dart`
- `app/lib/widgets/glyphs/conscia_glyph.dart`
- `app/lib/widgets/glyphs/painters/glyph_painter_primitives.dart`
- `app/lib/widgets/glyphs/painters/journey_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/money_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/category_glyph_painter.dart`
- `app/lib/widgets/glyphs/painters/utility_glyph_painter.dart`
- `app/test/widgets/glyphs/conscia_glyph_mapper_test.dart`
- `app/test/widgets/glyphs/conscia_glyph_golden_test.dart`

### Modify

- `app/lib/widgets/conscia_glyph.dart`
- `app/lib/screens/dashboard/dashboard_screen.dart`
- `app/lib/screens/dashboard/widgets/regret_prompt_card.dart`
- `app/test/screens/dashboard/regret_prompt_card_test.dart`
- `app/test/screens/dashboard/dashboard_alerts_test.dart`

### Existing Files To Read During Implementation

- `app/lib/widgets/feeling_choice_button.dart`
- `app/lib/core/constants/category_icons.dart`
- `app/lib/screens/dashboard/widgets/recent_transaction_tile.dart`
- `app/test/screens/dashboard/dashboard_alerts_test.dart`
- `app/test/screens/dashboard/regret_prompt_card_test.dart`

---

### Task 1: Baseline Glyph Tests Before Refactor

**Files:**
- Create: `app/test/widgets/glyphs/conscia_glyph_mapper_test.dart`
- Modify: `app/test/screens/dashboard/regret_prompt_card_test.dart`
- Test: `app/test/widgets/glyphs/conscia_glyph_mapper_test.dart`

- [ ] **Step 1: Write the failing glyph mapping tests**

```dart
import 'package:conscia_app/widgets/glyphs/conscia_glyph_mapper.dart';
import 'package:conscia_app/widgets/glyphs/conscia_glyph_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsciaGlyphMapper.category', () {
    test('maps category core inputs to curated glyphs', () {
      expect(
        ConsciaGlyphMapper.category('Dining'),
        ConsciaGlyphKind.dining,
      );
      expect(
        ConsciaGlyphMapper.category('Coffee'),
        ConsciaGlyphKind.coffee,
      );
      expect(
        ConsciaGlyphMapper.category('Groceries'),
        ConsciaGlyphKind.groceries,
      );
      expect(
        ConsciaGlyphMapper.category('Travel'),
        ConsciaGlyphKind.travel,
      );
    });

    test('uses semantic custom fallbacks for unknown categories', () {
      expect(
        ConsciaGlyphMapper.category('Bank fees'),
        ConsciaGlyphKind.wallet,
      );
      expect(
        ConsciaGlyphMapper.category('Paper trail item'),
        ConsciaGlyphKind.receipt,
      );
      expect(
        ConsciaGlyphMapper.category('Unmapped thing'),
        ConsciaGlyphKind.more,
      );
    });
  });

  group('ConsciaGlyphMapper.quest and milestone', () {
    test('maps known quest and milestone keys', () {
      expect(
        ConsciaGlyphMapper.quest('reflect-three-purchases'),
        ConsciaGlyphKind.reflect,
      );
      expect(
        ConsciaGlyphMapper.milestone('family-founder'),
        ConsciaGlyphKind.family,
      );
      expect(
        ConsciaGlyphMapper.level('money-monk'),
        ConsciaGlyphKind.monk,
      );
    });
  });
}
```

- [ ] **Step 2: Run the new glyph mapper tests to verify they fail**

Run:

```bash
cd app
flutter test test/widgets/glyphs/conscia_glyph_mapper_test.dart
```

Expected:

- FAIL because `widgets/glyphs/conscia_glyph_mapper.dart` and the new API do not exist yet

- [ ] **Step 3: Add a reflect subtitle test to protect the facelift target**

```dart
testWidgets('dashboard reflect section shows the gentle subtitle', (
  tester,
) async {
  // Use the existing dashboard harness from dashboard_alerts_test.dart
  // and assert:
  expect(
    find.text('A small pause can show whether this moment fit your rhythm.'),
    findsOneWidget,
  );
});
```

- [ ] **Step 4: Run the dashboard reflect test to verify it fails**

Run:

```bash
cd app
flutter test test/screens/dashboard/dashboard_alerts_test.dart --plain-name "dashboard reflect section shows the gentle subtitle"
```

Expected:

- FAIL because the subtitle is not rendered yet

- [ ] **Step 5: Commit the failing test scaffold**

```bash
git add app/test/widgets/glyphs/conscia_glyph_mapper_test.dart app/test/screens/dashboard/regret_prompt_card_test.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "test: add glyph mapper and reflect subtitle coverage"
```

### Task 2: Split ConsciaGlyph Into Modular Files

**Files:**
- Create: `app/lib/widgets/glyphs/conscia_glyph_kind.dart`
- Create: `app/lib/widgets/glyphs/conscia_glyph_mapper.dart`
- Create: `app/lib/widgets/glyphs/conscia_glyph.dart`
- Create: `app/lib/widgets/glyphs/painters/glyph_painter_primitives.dart`
- Create: `app/lib/widgets/glyphs/painters/journey_glyph_painter.dart`
- Create: `app/lib/widgets/glyphs/painters/money_glyph_painter.dart`
- Create: `app/lib/widgets/glyphs/painters/category_glyph_painter.dart`
- Create: `app/lib/widgets/glyphs/painters/utility_glyph_painter.dart`
- Modify: `app/lib/widgets/conscia_glyph.dart`
- Test: `app/test/widgets/glyphs/conscia_glyph_mapper_test.dart`

- [ ] **Step 1: Move the enum into the new kind file**

```dart
enum ConsciaGlyphKind {
  trail,
  receipt,
  reflect,
  pause,
  insight,
  signal,
  shield,
  family,
  recurring,
  income,
  salary,
  freelance,
  business,
  investment,
  rentalIncome,
  bonus,
  dining,
  groceries,
  transport,
  entertainment,
  shopping,
  health,
  bills,
  education,
  travel,
  coffee,
  subscription,
  home,
  gift,
  trophy,
  lock,
  sprout,
  compass,
  crown,
  monk,
  wallet,
  card,
  cash,
  bank,
  transfer,
  refund,
  fee,
  debt,
  savings,
  calendar,
  alert,
  check,
  more,
}
```

- [ ] **Step 2: Create the mapper with normalization and fallback logic**

```dart
class ConsciaGlyphMapper {
  static ConsciaGlyphKind category(String category) {
    final normalized = _normalize(category);
    return switch (normalized) {
      'dining' => ConsciaGlyphKind.dining,
      'coffee' => ConsciaGlyphKind.coffee,
      'groceries' => ConsciaGlyphKind.groceries,
      'transport' || 'fuel' || 'parking' => ConsciaGlyphKind.transport,
      'entertainment' || 'events' => ConsciaGlyphKind.entertainment,
      'shopping' || 'clothing' || 'beauty' => ConsciaGlyphKind.shopping,
      'health' || 'fitness' || 'pharmacy' => ConsciaGlyphKind.health,
      'bills' || 'utilities' || 'phone' || 'internet' => ConsciaGlyphKind.bills,
      'education' || 'books' => ConsciaGlyphKind.education,
      'travel' => ConsciaGlyphKind.travel,
      'subscriptions' => ConsciaGlyphKind.subscription,
      'salary' => ConsciaGlyphKind.salary,
      'freelance' => ConsciaGlyphKind.freelance,
      'business' => ConsciaGlyphKind.business,
      'investment' => ConsciaGlyphKind.investment,
      'rental-income' => ConsciaGlyphKind.rentalIncome,
      'bonus' => ConsciaGlyphKind.bonus,
      'home' || 'repairs' => ConsciaGlyphKind.home,
      'gift' || 'charity' || 'pets' || 'childcare' => ConsciaGlyphKind.gift,
      'insurance' => ConsciaGlyphKind.shield,
      'bank-fees' || 'fees' || 'fee' => ConsciaGlyphKind.wallet,
      _ => ConsciaGlyphKind.more,
    };
  }

  static ConsciaGlyphKind quest(String key) { /* migrated switch */ }
  static ConsciaGlyphKind milestone(String key) { /* migrated switch */ }
  static ConsciaGlyphKind level(String key) { /* migrated switch */ }
}
```

- [ ] **Step 3: Extract shared painter helpers**

```dart
class GlyphPainterPrimitives {
  const GlyphPainterPrimitives(this.size);

  final Size size;

  Offset point(double x, double y) => Offset(size.width * x, size.height * y);

  Rect rect(double x, double y, double w, double h) => Rect.fromLTWH(
        size.width * x,
        size.height * y,
        size.width * w,
        size.height * h,
      );

  RRect rrect(double x, double y, double w, double h, double radius) =>
      RRect.fromRectAndRadius(
        rect(x, y, w, h),
        Radius.circular(size.width * radius),
      );
}
```

- [ ] **Step 4: Move painter methods into grouped files without changing output unnecessarily**

```dart
bool paintJourneyGlyph(
  Canvas canvas,
  GlyphPainterPrimitives g,
  ConsciaGlyphKind kind,
  Paint stroke,
  Paint fill,
) {
  switch (kind) {
    case ConsciaGlyphKind.reflect:
      _reflect(canvas, g, stroke);
      return true;
    case ConsciaGlyphKind.signal:
      _signal(canvas, g, stroke, fill);
      return true;
    default:
      return false;
  }
}
```

- [ ] **Step 5: Keep the public widget API stable and add a compatibility export**

```dart
export 'glyphs/conscia_glyph.dart';
export 'glyphs/conscia_glyph_kind.dart';
```

- [ ] **Step 6: Run the glyph mapper tests**

Run:

```bash
cd app
flutter test test/widgets/glyphs/conscia_glyph_mapper_test.dart
```

Expected:

- PASS

- [ ] **Step 7: Run analyze after the refactor**

Run:

```bash
cd app
flutter analyze
```

Expected:

- `No issues found!`

- [ ] **Step 8: Commit the modular glyph refactor**

```bash
git add app/lib/widgets/conscia_glyph.dart app/lib/widgets/glyphs app/test/widgets/glyphs/conscia_glyph_mapper_test.dart
git commit -m "refactor(app): modularize conscia glyph system"
```

### Task 3: Fill Out The Curated V1 Glyph Set And Add Goldens

**Files:**
- Modify: `app/lib/widgets/glyphs/conscia_glyph_kind.dart`
- Modify: `app/lib/widgets/glyphs/conscia_glyph_mapper.dart`
- Modify: `app/lib/widgets/glyphs/painters/journey_glyph_painter.dart`
- Modify: `app/lib/widgets/glyphs/painters/money_glyph_painter.dart`
- Modify: `app/lib/widgets/glyphs/painters/category_glyph_painter.dart`
- Modify: `app/lib/widgets/glyphs/painters/utility_glyph_painter.dart`
- Create: `app/test/widgets/glyphs/conscia_glyph_golden_test.dart`
- Test: `app/test/widgets/glyphs/conscia_glyph_golden_test.dart`

- [ ] **Step 1: Add any missing curated v1 kinds**

```dart
// Confirm the enum includes at least:
// wallet, card, cash, bank, transfer, refund, fee, debt, savings,
// calendar, alert, check
```

- [ ] **Step 2: Implement missing painter cases only for the approved set**

```dart
case ConsciaGlyphKind.wallet:
  _wallet(canvas, g, stroke);
  return true;
case ConsciaGlyphKind.calendar:
  _calendar(canvas, g, stroke);
  return true;
case ConsciaGlyphKind.alert:
  _alert(canvas, g, stroke);
  return true;
```

- [ ] **Step 3: Write representative golden tests**

```dart
testGoldens('ConsciaGlyph representative set', (tester) async {
  await tester.pumpWidgetBuilder(
    Wrap(
      spacing: 16,
      children: const [
        ConsciaGlyph(
          kind: ConsciaGlyphKind.family,
          color: Color(0xFF1D2B6B),
        ),
        ConsciaGlyph(
          kind: ConsciaGlyphKind.wallet,
          color: Color(0xFF1D2B6B),
        ),
        ConsciaGlyph(
          kind: ConsciaGlyphKind.calendar,
          color: Color(0xFF1D2B6B),
        ),
        ConsciaGlyph(
          kind: ConsciaGlyphKind.dining,
          color: Color(0xFF1D2B6B),
        ),
      ],
    ),
  );
  await screenMatchesGolden(tester, 'conscia_glyph_representative_set');
});
```

- [ ] **Step 4: Run the golden test**

Run:

```bash
cd app
flutter test test/widgets/glyphs/conscia_glyph_golden_test.dart
```

Expected:

- PASS after golden is generated and checked in

- [ ] **Step 5: Run the full glyph-focused test set**

Run:

```bash
cd app
flutter test test/widgets/glyphs
```

Expected:

- PASS

- [ ] **Step 6: Commit the curated v1 glyph expansion**

```bash
git add app/lib/widgets/glyphs app/test/widgets/glyphs
git commit -m "feat(app): expand conscia glyph v1 set"
```

### Task 4: Redesign RegretPromptCard Into The Featured Editorial Card

**Files:**
- Modify: `app/lib/screens/dashboard/widgets/regret_prompt_card.dart`
- Modify: `app/test/screens/dashboard/regret_prompt_card_test.dart`
- Test: `app/test/screens/dashboard/regret_prompt_card_test.dart`

- [ ] **Step 1: Expand the card API to support queue context**

```dart
final String? queueHint;
final bool showStackedPreview;
```

Add them to the constructor:

```dart
this.queueHint,
this.showStackedPreview = false,
```

- [ ] **Step 2: Update the card layout to richer editorial structure**

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _ReflectHeaderRow(...),
    const SizedBox(height: 16),
    Text(
      'Was it worth it?',
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 6),
    Text(
      'Notice what this moment gave you before you decide how it felt.',
      style: textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 16),
    Row(
      children: [
        Expanded(child: FeelingChoiceButton.worthIt(onPressed: onWorthIt)),
        const SizedBox(width: 8),
        Expanded(child: FeelingChoiceButton.notSure(onPressed: onNotSure)),
        const SizedBox(width: 8),
        Expanded(child: FeelingChoiceButton.regret(onPressed: onRegret)),
      ],
    ),
    if (queueHint != null) ...[
      const SizedBox(height: 14),
      Text(queueHint!, style: textTheme.labelMedium),
    ],
  ],
)
```

- [ ] **Step 3: Add the subtle stacked preview treatment**

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    if (showStackedPreview)
      Positioned(
        top: 10,
        left: 10,
        right: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const SizedBox(height: 24),
        ),
      ),
    Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ...
    ),
  ],
)
```

- [ ] **Step 4: Update the widget tests for the new structure**

```dart
testWidgets('shows queue hint and gentle guidance copy', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RegretPromptCard(
          categoryBadge: CategoryIcons.badge('Dining', size: 16),
          counterparty: 'Starbucks',
          amount: 600,
          currencyCode: 'PHP',
          date: DateTime.now(),
          queueHint: '2 more moments waiting',
          showStackedPreview: true,
        ),
      ),
    ),
  );

  expect(
    find.text('Notice what this moment gave you before you decide how it felt.'),
    findsOneWidget,
  );
  expect(find.text('2 more moments waiting'), findsOneWidget);
});
```

- [ ] **Step 5: Run the card tests**

Run:

```bash
cd app
flutter test test/screens/dashboard/regret_prompt_card_test.dart
```

Expected:

- PASS

- [ ] **Step 6: Commit the reflect card facelift**

```bash
git add app/lib/screens/dashboard/widgets/regret_prompt_card.dart app/test/screens/dashboard/regret_prompt_card_test.dart
git commit -m "feat(app): redesign dashboard reflect card"
```

### Task 5: Update DashboardScreen To Feature One Reflection Moment

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/test/screens/dashboard/dashboard_alerts_test.dart`
- Test: `app/test/screens/dashboard/dashboard_alerts_test.dart`

- [ ] **Step 1: Replace the horizontal prompt rail with one featured prompt**

```dart
final featuredPrompt = regretPrompts.isEmpty ? null : regretPrompts.first;
final remainingPromptCount =
    regretPrompts.isEmpty ? 0 : regretPrompts.length - 1;
```

Render:

```dart
if (featuredPrompt != null) ...[
  _SectionHeading(
    title: 'Reflect',
    subtitle: 'A small pause can show whether this moment fit your rhythm.',
  ),
  const SizedBox(height: 16),
  RegretPromptCard(
    categoryBadge: CategoryIcons.badge(
      featuredPrompt.category ?? 'Uncategorized',
      size: 16,
      filled: false,
    ),
    counterparty: featuredPrompt.description,
    amount: featuredPrompt.amount.abs(),
    currencyCode: featuredPrompt.currencyCode,
    date: featuredPrompt.date,
    queueHint: remainingPromptCount > 0
        ? '$remainingPromptCount more moments waiting'
        : null,
    showStackedPreview: remainingPromptCount > 0,
    onWorthIt: () => _recordReflection(featuredPrompt, 'worth_it'),
    onNotSure: () => _recordReflection(featuredPrompt, 'not_sure'),
    onRegret: () => _recordReflection(featuredPrompt, 'regret'),
  ),
]
```

- [ ] **Step 2: Keep section scope narrow and do not redesign nearby sections**

```dart
// Do not change the budgets block or recent transactions block in this task
// beyond any import or spacing adjustments required by the new reflect card.
```

- [ ] **Step 3: Update dashboard tests to assert the featured-card behavior**

```dart
testWidgets('dashboard reflect section shows one featured prompt and queue hint', (
  tester,
) async {
  expect(find.text('Reflect'), findsOneWidget);
  expect(
    find.text('A small pause can show whether this moment fit your rhythm.'),
    findsOneWidget,
  );
  expect(find.text('2 more moments waiting'), findsOneWidget);
  expect(find.text('Starbucks'), findsOneWidget);
});
```

- [ ] **Step 4: Run the focused dashboard tests**

Run:

```bash
cd app
flutter test test/screens/dashboard/dashboard_alerts_test.dart
```

Expected:

- PASS

- [ ] **Step 5: Commit the dashboard reflect integration**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart app/test/screens/dashboard/dashboard_alerts_test.dart
git commit -m "feat(app): feature editorial reflect section on dashboard"
```

### Task 6: Final Verification And Cleanup

**Files:**
- Modify: any touched files only if verification reveals issues
- Test: full Flutter suite relevant to this pass

- [ ] **Step 1: Run Flutter analyze**

Run:

```bash
cd app
flutter analyze
```

Expected:

- `No issues found!`

- [ ] **Step 2: Run the full Flutter test suite**

Run:

```bash
cd app
flutter test
```

Expected:

- PASS

- [ ] **Step 3: Inspect git diff for unintended dashboard scope creep**

Run:

```bash
git diff --stat main...HEAD
```

Expected:

- glyph files
- regret prompt card
- dashboard screen
- related tests
- no surprise edits to budgets/recent-transactions presentation

- [ ] **Step 4: Commit any last verification fixes**

```bash
git add app
git commit -m "fix(app): polish glyph and reflect facelift verification issues"
```

- [ ] **Step 5: Prepare branch for review**

Run:

```bash
git status --short
```

Expected:

- no output

## Spec Coverage Check

- Modular glyph architecture: covered by Task 2
- Curated v1 glyph set: covered by Task 3
- Semantic Conscia fallbacks: covered by Tasks 1-3
- Featured editorial reflect card: covered by Task 4
- Gentle reflect subtitle: covered by Task 5
- One featured moment plus stacked queue hint: covered by Tasks 4-5
- Small, focused dashboard scope: protected by Task 5 and Task 6

## Notes For Execution

- Reuse the existing `RegretPromptCard` seam rather than creating an entirely new dashboard card type unless execution proves that impossible.
- Prefer compatibility exports or a thin forwarding layer for `app/lib/widgets/conscia_glyph.dart` so call sites do not need a broad import migration immediately.
- Keep goldens representative, not exhaustive.
- If swipe behavior materially hurts the richer editorial feel during implementation, pause and confirm before removing it.
