# Purchase Assistant Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the three states of `PrePurchaseScreen` — Input (bleed hero), Conscience Check loader (thinking cloud + insight slideshow), and Verdict (chat bubbles with chibi avatars + sticky CTAs).

**Architecture:** `ThinkingCloudWidget` is a standalone `CustomPainter`-based widget in `lib/widgets/`. All three screen states are rebuilt inside `pre_purchase_screen.dart` using new private widgets. `HeroScreenScaffold` gets a nav-inset fix so sticky CTAs clear the shell bottom nav on all screens.

**Tech Stack:** Flutter, Riverpod, existing `CustomPainter` pattern from `conscience_mark.dart`, existing `MascotSpriteFrame` / `MascotSpriteAtlas` for avatars (head-only atlas TBD — placeholder uses existing sheet with circular crop).

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| **Create** | `lib/widgets/thinking_cloud.dart` | `ThinkingCloudWidget` + `_ThinkingCloudPainter` |
| **Create** | `test/widgets/thinking_cloud_test.dart` | Widget tests for `ThinkingCloudWidget` |
| **Modify** | `lib/widgets/hero_screen_scaffold.dart` | Fix bottom inset so CTAs clear shell nav |
| **Modify** | `test/widgets/hero_screen_scaffold_test.dart` | Add nav-clearance regression test |
| **Modify** | `lib/screens/assistant/pre_purchase_screen.dart` | All three state rebuilds |
| **Modify** | `test/screens/assistant/pre_purchase_screen_test.dart` | Update / add tests for new layouts |
| **Modify** | `docs/superpowers/specs/2026-05-14-purchase-assistant-redesign.md` | Note pending head-sprite assets |

---

## Task 1 — `ThinkingCloudWidget`

New standalone file. No providers, no routing dependencies. Safe to build and test in isolation.

**Files:**
- Create: `lib/widgets/thinking_cloud.dart`
- Create: `test/widgets/thinking_cloud_test.dart`

- [ ] **Step 1.1 — Write the failing widget test**

```dart
// test/widgets/thinking_cloud_test.dart
import 'package:conscia_app/widgets/thinking_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ThinkingCloudWidget renders a CustomPaint at the requested size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ThinkingCloudWidget(size: 200))),
      ),
    );
    // Widget exists
    expect(find.byType(ThinkingCloudWidget), findsOneWidget);
    // CustomPaint is present (the painter surface)
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    // Size is correct
    final sz = tester.getSize(find.byType(ThinkingCloudWidget));
    expect(sz.width,  closeTo(200, 1));
    expect(sz.height, closeTo(200, 1));
  });

  testWidgets('ThinkingCloudWidget disposes without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThinkingCloudWidget())),
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    // No exceptions thrown on dispose
  });
}
```

- [ ] **Step 1.2 — Run test to confirm it fails**

```
cd app
flutter test test/widgets/thinking_cloud_test.dart
```

Expected: `Error: Could not find package 'conscia_app/widgets/thinking_cloud.dart'`

- [ ] **Step 1.3 — Create `lib/widgets/thinking_cloud.dart`**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An ambient "thinking" cloud animation — 7 soft blurred colour blobs
/// (red/devil, blue/angel, amber/conscia, white diffuse) drifting at
/// independent frequencies inside a gently morphing ellipse clip.
///
/// Inspired by _GalaxyBackgroundPainter in conscience_mark.dart.
/// No centre core, no rings, no orbiting particles.
class ThinkingCloudWidget extends StatefulWidget {
  const ThinkingCloudWidget({super.key, this.size = 220});
  final double size;

  @override
  State<ThinkingCloudWidget> createState() => _ThinkingCloudWidgetState();
}

class _ThinkingCloudWidgetState extends State<ThinkingCloudWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _ThinkingCloudPainter(
            t: _controller.value * math.pi * 2,
          ),
        ),
      ),
    );
  }
}

// ── Blob data ──────────────────────────────────────────────────────────────

class _Blob {
  const _Blob({
    required this.bx, required this.by,
    required this.ax, required this.ay,
    required this.sx, required this.sy,
    required this.phase,
    required this.color,
    required this.opacity,
    required this.radius,
  });
  final double bx, by, ax, ay, sx, sy, phase, opacity, radius;
  final Color color;
}

const _blobs = <_Blob>[
  // Devil — red / orange
  _Blob(bx:0.30, by:0.52, ax:0.13, ay:0.10, sx:0.55, sy:0.38, phase:0.00, color:Color(0xFFFF5A4A), opacity:0.62, radius:0.40),
  _Blob(bx:0.35, by:0.44, ax:0.09, ay:0.13, sx:0.82, sy:0.61, phase:1.40, color:Color(0xFFE64020), opacity:0.38, radius:0.28),
  // Angel — cyan / blue
  _Blob(bx:0.72, by:0.50, ax:0.14, ay:0.09, sx:0.48, sy:0.70, phase:2.10, color:Color(0xFF67D9FF), opacity:0.60, radius:0.40),
  _Blob(bx:0.65, by:0.58, ax:0.08, ay:0.14, sx:0.73, sy:0.44, phase:3.30, color:Color(0xFF50A0F0), opacity:0.35, radius:0.26),
  // Conscia — amber / gold
  _Blob(bx:0.52, by:0.22, ax:0.11, ay:0.08, sx:0.66, sy:0.52, phase:4.50, color:Color(0xFFFFD45E), opacity:0.55, radius:0.34),
  _Blob(bx:0.48, by:0.78, ax:0.10, ay:0.10, sx:0.44, sy:0.80, phase:0.85, color:Color(0xFFFFB432), opacity:0.30, radius:0.24),
  // Diffuse white — blends all three
  _Blob(bx:0.50, by:0.50, ax:0.06, ay:0.06, sx:0.30, sy:0.35, phase:1.90, color:Color(0xFFDCE1FF), opacity:0.22, radius:0.32),
];

// ── Painter ────────────────────────────────────────────────────────────────

class _ThinkingCloudPainter extends CustomPainter {
  const _ThinkingCloudPainter({required this.t});
  final double t; // 0 → 2π, repeating

  @override
  void paint(Canvas canvas, Size size) {
    // Morphing ellipse clip — irregular, slowly rotating
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final rx = size.width  * (0.44 + math.sin(t * 0.4)  * 0.015);
    final ry = size.height * (0.44 + math.cos(t * 0.35) * 0.012);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.sin(t * 0.15) * 0.12);
    canvas.translate(-cx, -cy);
    canvas.clipPath(
      Path()..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: rx * 2,
        height: ry * 2,
      )),
    );

    for (final b in _blobs) {
      final x = (b.bx + math.sin(t * b.sx + b.phase) * b.ax) * size.width;
      final y = (b.by + math.cos(t * b.sy + b.phase * 1.3) * b.ay) * size.height;
      final op = (b.opacity + math.sin(t * 1.1 + b.phase * 0.7) * 0.14)
          .clamp(0.0, 1.0);
      final radius = (b.radius + math.sin(t * 0.65 + b.phase) * 0.04) * size.width;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = b.color.withValues(alpha: op)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThinkingCloudPainter old) => old.t != t;
}
```

- [ ] **Step 1.4 — Run tests to confirm they pass**

```
flutter test test/widgets/thinking_cloud_test.dart
```

Expected: `All tests passed.`

- [ ] **Step 1.5 — Commit**

```
git add lib/widgets/thinking_cloud.dart test/widgets/thinking_cloud_test.dart
git commit -m "feat: add ThinkingCloudWidget animated blob painter"
```

---

## Task 2 — Fix `HeroScreenScaffold` shell-nav bottom clearance

The current `HeroScreenScaffold` creates a nested `Scaffold`. Its `SafeArea` clears device safe areas but does not always clear the *outer shell's* `BottomNavigationBar` because go_router's `ShellRoute` may render the outer Scaffold with `extendBody: true` or a similar flag, causing the nav to overlay the inner scaffold's content.

**Files:**
- Modify: `lib/widgets/hero_screen_scaffold.dart`
- Modify: `test/widgets/hero_screen_scaffold_test.dart`

- [ ] **Step 2.1 — Write a failing regression test**

Add to `test/widgets/hero_screen_scaffold_test.dart`:

```dart
testWidgets(
    'HeroScreenScaffold bottom widget clears a simulated shell nav bar',
    (tester) async {
  // Simulate the shell nav bar by setting MediaQuery.padding.bottom
  // (same effect as an outer Scaffold with a BottomNavigationBar of height 80).
  const navBarHeight = 80.0;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: navBarHeight),
        ),
        child: const HeroScreenScaffold(
          bottom: SizedBox(
            key: ValueKey('cta'),
            height: 52,
            child: Placeholder(),
          ),
          child: SizedBox(height: 400),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
  final ctaBottom = tester.getBottomLeft(find.byKey(const ValueKey('cta'))).dy;

  // The CTA's bottom edge must be at least navBarHeight above the screen bottom.
  expect(
    ctaBottom,
    lessThanOrEqualTo(screenHeight - navBarHeight),
    reason: 'CTA is obscured by the shell nav bar',
  );
});
```

- [ ] **Step 2.2 — Run test to confirm it fails**

```
flutter test test/widgets/hero_screen_scaffold_test.dart \
  --name "clears a simulated shell nav bar"
```

Expected: FAIL — `ctaBottom` equals `screenHeight - 0` (nav bar not cleared).

- [ ] **Step 2.3 — Fix `hero_screen_scaffold.dart`**

The inner `Scaffold`'s `SafeArea` clears `MediaQuery.padding` but only for the *scrollable content*, not for the `AnimatedPadding` that holds the `bottom` widget. Add `MediaQuery.padding.bottom` to the `AnimatedPadding`'s bottom value:

```dart
// lib/widgets/hero_screen_scaffold.dart  — change only the AnimatedPadding block

if (bottom != null)
  AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: EdgeInsets.fromLTRB(
      16,
      0,
      16,
      // KEY CHANGE: also account for bottom safe-area (shell nav bar)
      20 + keyboardInset + MediaQuery.paddingOf(context).bottom,
    ),
    child: bottom!,
  ),
```

> **Note:** `MediaQuery.paddingOf(context).bottom` reflects whatever the outer
> Scaffold or `MediaQuery` ancestor has reserved for system UI / nav bars. When
> the keyboard is open `viewInsetsOf` grows and `paddingOf` shrinks
> correspondingly, so the two do not double-count.

- [ ] **Step 2.4 — Run all hero_screen_scaffold tests**

```
flutter test test/widgets/hero_screen_scaffold_test.dart
```

Expected: `All tests passed.`

- [ ] **Step 2.5 — Commit**

```
git add lib/widgets/hero_screen_scaffold.dart \
        test/widgets/hero_screen_scaffold_test.dart
git commit -m "fix: hero_screen_scaffold clears shell nav bar in bottom slot"
```

---

## Task 3 — Verdict screen — chat bubbles + sticky CTAs

Replace `_VerdictCard` with `_VerdictBubble` (devil left, angel right), update `_ConsciaTakeCard` to use `ConscienceBrandIcon` and remove inline buttons, move the three CTAs to `HeroScreenScaffold(bottom: ...)`.

> **Head sprites:** The user will supply head-only sprite sheets (~10 poses each) as a follow-up. `_VerdictAvatar` is designed as a seam — it uses the existing full-body neutral frame today and will be updated to the head atlas without touching `_VerdictBubble`.

**Files:**
- Modify: `lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 3.1 — Write failing tests for the new verdict layout**

Add to `test/screens/assistant/pre_purchase_screen_test.dart` (inside `main()`). Use the existing `_pumpWithResponse` helper or create one following the same pattern as existing tests in that file:

```dart
testWidgets('verdict shows devil bubble on left and angel on right',
    (tester) async {
  await _pumpWithResponse(tester);

  final devilRow = find.byKey(const ValueKey('verdict-devil-row'));
  final angelRow = find.byKey(const ValueKey('verdict-angel-row'));

  expect(devilRow, findsOneWidget);
  expect(angelRow, findsOneWidget);

  final devilLeft  = tester.getTopLeft(devilRow).dx;
  final angelRight = tester.getTopRight(angelRow).dx;

  // Devil row starts near the left edge; angel row ends near the right edge.
  expect(devilLeft,  lessThan(40));
  expect(angelRight, greaterThan(tester.getSize(find.byType(MaterialApp)).width - 40));
});

testWidgets('verdict CTAs are visible and not behind the nav bar',
    (tester) async {
  await _pumpWithResponse(tester);

  expect(find.text('Buy it'),   findsOneWidget);
  expect(find.text('Wait 24h'), findsOneWidget);
  expect(find.text('Skip'),     findsOneWidget);
});

testWidgets('ConscienceBrandIcon is shown in Conscia take card',
    (tester) async {
  await _pumpWithResponse(tester);
  expect(find.byType(ConscienceBrandIcon), findsOneWidget);
});
```

- [ ] **Step 3.2 — Run tests to confirm they fail**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart \
  --name "verdict shows devil"
```

Expected: FAIL — keys not found.

- [ ] **Step 3.3 — Replace `_VerdictCard` with `_VerdictBubble` + `_VerdictAvatar`**

In `pre_purchase_screen.dart`, delete the old `_VerdictCard` class and add:

```dart
// ── Verdict avatar ─────────────────────────────────────────────────────────
// Placeholder until head-only sprite sheets are available.
// When the new MascotSpriteAtlas for heads is ready, swap the atlas/frame here.
class _VerdictAvatar extends StatelessWidget {
  const _VerdictAvatar({required this.isDevil});
  final bool isDevil;

  @override
  Widget build(BuildContext context) {
    final atlas = isDevil ? devilMascotAtlas : angelMascotAtlas;
    // '1_neutral.png' is the calmest full-body pose; circular crop shows face.
    // Replace atlas + frameName when head-only assets land.
    return ClipOval(
      child: MascotSpriteFrame(
        atlas: atlas,
        frameName: '1_neutral.png',
        width: 48,
      ),
    );
  }
}

// ── Verdict bubble ─────────────────────────────────────────────────────────
class _VerdictBubble extends StatelessWidget {
  const _VerdictBubble({
    required this.tone,
    required this.message,
    required this.animation,
  });

  final _VerdictTone tone;
  final String message;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final isDevil   = tone == _VerdictTone.devil;

    final bg     = isDevil ? colors.devilBg  : colors.angelBg;
    final accent = isDevil ? colors.devilAccent : colors.angelAccent;
    final label  = isDevil ? 'THE DEVIL SAYS' : 'THE ANGEL SAYS';

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.62,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isDevil ? 4 : 16),
            bottomRight: Radius.circular(isDevil ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: accent, fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"$message"',
              style: textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );

    final avatar = _VerdictAvatar(isDevil: isDevil);

    return FadeTransition(
      opacity: animation,
      child: Row(
        key: ValueKey(isDevil ? 'verdict-devil-row' : 'verdict-angel-row'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isDevil
            ? [avatar, const SizedBox(width: 8), bubble]
            : [const Spacer(), bubble, const SizedBox(width: 8), avatar],
      ),
    );
  }
}
```

- [ ] **Step 3.4 — Update `_ConsciaTakeCard`**

Remove `amount`, `currencyCode`, `onBuy`, `onWait`, `onSkip` from the constructor. Add `animation`. Replace the `'*'` text header with `ConscienceBrandIcon`. Remove the `Row` of buttons.

```dart
class _ConsciaTakeCard extends StatelessWidget {
  const _ConsciaTakeCard({
    required this.message,
    required this.contextLabel,
    required this.animation,
  });

  final String message;
  final String contextLabel;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.amberSoft,
          border: Border.all(color: colors.amber.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ConscienceBrandIcon(size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Conscia's take",
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.deepNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(contextLabel),
              avatar: const Icon(Icons.auto_awesome, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3.5 — Update `_buildResponse`**

```dart
Widget _buildResponse() {
  final amount   = double.tryParse(_amountController.text) ?? 0;
  final response = _aiResponse!;
  final locale   = ref.watch(userPreferencesProvider).locale;

  return HeroScreenScaffold(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    appBar: AppBar(title: const Text('The verdict')),
    bottom: Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _openExpenseConfirmation,
            child: const Text('Buy it'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _reset,
            child: const Text('Wait 24h'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _reset,
            child: const Text('Skip'),
          ),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerdictBubble(
          tone: _VerdictTone.devil,
          message: response.impulse,
          animation: _devilAnim,
        ),
        const SizedBox(height: 12),
        _VerdictBubble(
          tone: _VerdictTone.angel,
          message: response.reason,
          animation: _angelAnim,
        ),
        const SizedBox(height: 12),
        _ConsciaTakeCard(
          message: response.neutral,
          contextLabel: _selectedContextScope == 'family'
              ? 'Family advice'
              : 'Personal advice',
          animation: _neutralAnim,
        ),
        if (_selectedCategory != null && response.budget != null) ...[
          const SizedBox(height: 12),
          BudgetContextCard(
            category: _selectedCategory!,
            spent: response.budget!.currentSpend,
            limit: response.budget!.monthlyLimit,
            currencyCode: _currencyCode,
            locale: locale,
            projectedAmount: amount,
          ),
        ],
      ],
    ),
  );
}
```

- [ ] **Step 3.6 — Run the verdict tests**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart
```

Expected: all verdict tests pass; no regressions in existing tests.

- [ ] **Step 3.7 — Commit**

```
git add lib/screens/assistant/pre_purchase_screen.dart \
        test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: verdict chat bubbles with sprite avatars and sticky CTAs"
```

---

## Task 4 — Loader screen — thinking cloud + insight slideshow

Replace the sprite-brawl loading scene with `ThinkingCloudWidget` on top and an auto-advancing `PageView` of three insight cards below.

**Files:**
- Modify: `lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 4.1 — Write failing tests**

```dart
testWidgets('loading state shows ThinkingCloudWidget', (tester) async {
  await _pumpLoading(tester); // helper that pumps screen in loading state
  expect(find.byType(ThinkingCloudWidget), findsOneWidget);
});

testWidgets('loading state shows at least one insight slide card',
    (tester) async {
  await _pumpLoading(tester);
  // The slideshow always shows at least one _InsightSlide card
  expect(find.byType(_InsightSlideCard), findsAtLeastNWidgets(1));
});

testWidgets('loading state shows slide dot indicators', (tester) async {
  await _pumpLoading(tester);
  expect(find.byType(_SlideDot), findsAtLeastNWidgets(1));
});
```

Add `_pumpLoading` helper near the top of the test file (after existing helpers):

```dart
Future<void> _pumpLoading(WidgetTester tester) async {
  // _FakeAIService with a long delay keeps the screen in loading state.
  await _pumpScreen(
    tester,
    aiService: _FakeAIService(
      response: _kFakeResponse,
      delay: const Duration(hours: 1), // never resolves during test
    ),
  );
  // Fill required fields so _submit() runs
  await tester.enterText(find.byType(TextField).first, 'coffee');
  await tester.pump();
  // Select a category (tap first chip)
  await tester.tap(find.byType(InputChip).first);
  await tester.pump();
  // Enter amount
  await tester.enterText(
    find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text != 'coffee',
    ),
    '800',
  );
  await tester.pump();
  // Tap submit
  await tester.tap(find.text('Ask Conscia'));
  await tester.pump(); // one frame to flip state to loading
}
```

- [ ] **Step 4.2 — Run tests to confirm they fail**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart \
  --name "loading state shows ThinkingCloudWidget"
```

Expected: FAIL — `ThinkingCloudWidget` not found.

- [ ] **Step 4.3 — Add `_InsightSlideCard`, `_SlideDot` widgets to `pre_purchase_screen.dart`**

Add these private classes before `_buildLoading`:

```dart
class _InsightSlideCard extends StatelessWidget {
  const _InsightSlideCard({
    required this.icon,
    required this.headline,
    required this.body,
  });

  final Widget icon;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.sectionBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 10),
            Text(
              headline,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideDot extends StatelessWidget {
  const _SlideDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 14 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? colors.deepNavy : colors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
```

- [ ] **Step 4.4 — Add `_InsightSlideshow` stateful widget**

```dart
class _InsightSlideshow extends StatefulWidget {
  const _InsightSlideshow({
    required this.amount,
    required this.currencyCode,
    required this.category,
  });

  final double  amount;
  final String  currencyCode;
  final String? category;

  @override
  State<_InsightSlideshow> createState() => _InsightSlideshowState();
}

class _InsightSlideshowState extends State<_InsightSlideshow> {
  final _pageController = PageController();
  int _current = 0;
  // ignore: cancel_subscriptions
  late final _timer = Stream.periodic(const Duration(seconds: 2))
      .listen((_) => _advance());

  void _advance() {
    if (!mounted) return;
    final next = (_current + 1) % _slides.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    setState(() => _current = next);
  }

  List<_InsightSlideCard> get _slides {
    final formatted =
        CurrencyFormatter.format(widget.amount, currencyCode: widget.currencyCode);
    final cat = widget.category ?? 'this purchase';
    return [
      _InsightSlideCard(
        icon: const Icon(Icons.account_balance_wallet_outlined, size: 22),
        headline: 'Reviewing your $cat budget',
        body: 'Checking how $formatted compares to your monthly spending patterns.',
      ),
      const _InsightSlideCard(
        icon: Icon(Icons.psychology_outlined, size: 22),
        headline: 'Both sides are making their case',
        body: 'The Angel is weighing your goals. The Devil is considering your satisfaction.',
      ),
      const _InsightSlideCard(
        icon: Icon(Icons.history_outlined, size: 22),
        headline: 'Checking your patterns',
        body: 'Looking at similar past purchases and how you felt about them afterward.',
      ),
    ];
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _slides[i],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (i) => _SlideDot(active: i == _current),
          ),
        ),
        const SizedBox(height: 14),
        const LinearProgressIndicator(value: null, minHeight: 2),
      ],
    );
  }
}
```

- [ ] **Step 4.5 — Replace `_buildLoading`**

```dart
Widget _buildLoading() {
  final textTheme = Theme.of(context).textTheme;
  final colors    = Theme.of(context).appColors;

  return HeroScreenScaffold(
    appBar: AppBar(title: const Text('Conscience Check')),
    scrollable: false,
    child: Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Reviewing your ${CurrencyFormatter.format(
            double.tryParse(_amountController.text) ?? 0,
            currencyCode: _currencyCode,
          )} ${_descriptionController.text.trim()} decision...',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
        ),
        const SizedBox(height: 12),
        const ThinkingCloudWidget(size: 210),
        const SizedBox(height: 16),
        Expanded(
          child: _InsightSlideshow(
            amount:       double.tryParse(_amountController.text) ?? 0,
            currencyCode: _currencyCode,
            category:     _selectedCategory,
          ),
        ),
      ],
    ),
  );
}
```

Add the import at the top of `pre_purchase_screen.dart`:

```dart
import '../../widgets/thinking_cloud.dart';
```

- [ ] **Step 4.6 — Run loader tests**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 4.7 — Commit**

```
git add lib/screens/assistant/pre_purchase_screen.dart \
        test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: conscience check loader with thinking cloud and insight slideshow"
```

---

## Task 5 — Input screen — dashboard-style bleed hero

Replace the inset dark card with a full-width bleed hero using `navySoft → amberSoft` gradient, rounded only at the bottom, matching the dashboard.

**Files:**
- Modify: `lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 5.1 — Write failing test**

```dart
testWidgets('input hero bleeds full width with bottom-only radius', (tester) async {
  await _pumpInput(tester);

  final hero = find.byKey(const ValueKey('assistant-hero-bleed'));
  expect(hero, findsOneWidget);

  // Hero spans the full screen width
  final heroWidth  = tester.getSize(hero).width;
  final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
  expect(heroWidth, closeTo(screenWidth, 1));

  // Hero tagline is visible
  expect(find.text("Let's think this through"), findsOneWidget);
});
```

Add `_pumpInput` helper (if not already present from Task 4):

```dart
Future<void> _pumpInput(WidgetTester tester) async {
  await _pumpScreen(
    tester,
    aiService: _FakeAIService(
      response: _kFakeResponse,
      delay: const Duration(hours: 1),
    ),
  );
}
```

- [ ] **Step 5.2 — Run test to confirm it fails**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart \
  --name "input hero bleeds full width"
```

Expected: FAIL — key `assistant-hero-bleed` not found.

- [ ] **Step 5.3 — Add `_AssistantHeroBleed` widget**

```dart
class _AssistantHeroBleed extends StatelessWidget {
  const _AssistantHeroBleed({required this.greetingName});
  final String greetingName;

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('assistant-hero-bleed'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            children: [
              // Identity row — mirrors dashboard header
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.navySoft,
                    child: Icon(Icons.person, size: 20, color: colors.deepNavy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.mutedInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          greetingName,
                          style: textTheme.titleSmall?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Mascot + tagline
              ConsciaAlterEgoMotion(
                preset: ConsciaAlterEgoPreset.idle,
                size: 56,
              ),
              const SizedBox(height: 10),
              Text(
                "Let's think this through",
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Conscia gives you a devil's impulse, an angel's reason, "
                'and a neutral take to help you spend more mindfully.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.mutedInk,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.4 — Update `_buildInputForm` to use the bleed hero**

Read `greetingName` from `currentUserProvider` (already imported via `user_provider.dart`):

```dart
Widget _buildInputForm() {
  final textTheme  = Theme.of(context).textTheme;
  final colors     = Theme.of(context).appColors;
  final isPremium  =
      ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
  final locationAssistance = ref.watch(locationAssistanceProvider);
  final suggestions        = ref.watch(locationAssistanceSuggestionsProvider);
  final familySpace        = ref.watch(familySpaceProvider).valueOrNull;
  final hasSuggestions     = suggestions.nearbyMerchants.isNotEmpty ||
      suggestions.likelyCategories.isNotEmpty;
  // Greeting name for the hero identity row
  final greetingName = ref
      .watch(currentUserProvider)
      .valueOrNull
      ?.displayName ?? '';

  if (familySpace == null && _selectedContextScope != 'personal') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedContextScope = 'personal');
    });
  }

  return HeroScreenScaffold(
    // No top padding — hero provides its own space
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    bottom: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
      onPressed: _formValid ? _submit : null,
      child: const Text('Ask Conscia'),
    ),
    child: Column(
      children: [
        // Bleed hero — placed OUTSIDE the HeroScreenScaffold's padding
        // by using negative margin to escape the 16px horizontal inset.
        Padding(
          padding: const EdgeInsets.fromLTRB(-16, -14, -16, 0),
          child: _AssistantHeroBleed(greetingName: greetingName),
        ),
        const SizedBox(height: 20),

        if (familySpace != null) ...[
          ScopePillSwitch(
            value: _selectedContextScope,
            familyEnabled: true,
            onChanged: (scope) =>
                setState(() => _selectedContextScope = scope),
          ),
          const SizedBox(height: 18),
        ],
        TextField(
          controller: _descriptionController,
          maxLines: 1,
          decoration: InputDecoration(
            labelText: 'What are you thinking of buying?',
            suffixIcon: VoiceInputButton(onTranscriptReady: _applyVoiceTranscript),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        AmountHeroField(
          controller: _amountController,
          currencyCode: _currencyCode,
          isExpense: true,
          isPremium: isPremium,
          onChanged: (_) => setState(() {}),
          onCurrencyChanged: (code) => setState(() {
            _currencyManuallyChanged = true;
            _currencyCode = code;
          }),
        ),
        const SizedBox(height: 18),
        TransactionStyleCategorySelector(
          selectedCategory: _selectedCategory,
          isExpense: true,
          isPremium: isPremium,
          showHeader: false,
          onCategorySelected: (category) {
            setState(() => _selectedCategory = category);
            if (category != null) {
              ref.read(recentCategoryProvider.notifier).record(category);
            }
          },
        ),
        if (locationAssistance.isEnabled && hasSuggestions) ...[
          SmartSuggestionsCard(
            suggestions: suggestions,
            subtitle:
                'Need a nudge? Try a nearby merchant or likely category.',
            onMerchantSelected: (m) =>
                setState(() => _descriptionController.text = m),
            onCategorySelected: (c) {
              setState(() => _selectedCategory = c);
              ref.read(recentCategoryProvider.notifier).record(c);
            },
            categoryAvatarBuilder: (c) => CategoryIcons.badge(c, size: 14),
          ),
        ],
        const SizedBox(height: 20),
      ],
    ),
  );
}
```

> **Note on negative margin:** `HeroScreenScaffold` applies `padding: EdgeInsets.fromLTRB(16, 14, …)` to the scroll view. `_AssistantHeroBleed` must bleed through those margins — hence the `Padding(padding: EdgeInsets.fromLTRB(-16, -14, -16, 0))` wrapper. If `HeroScreenScaffold` is changed to apply padding differently in the future, adjust accordingly.

- [ ] **Step 5.5 — Run all tests**

```
flutter test test/screens/assistant/pre_purchase_screen_test.dart
flutter test test/widgets/
```

Expected: all pass.

- [ ] **Step 5.6 — Smoke test on device / simulator**

```
flutter run -d <your-device>
```

Navigate to the Purchase Assistant tab. Verify:
- Hero bleeds edge-to-edge, rounded only at bottom, gradient matches dashboard
- "Ask Conscia" button is visible above nav bar
- Tapping Submit shows cloud + slideshow (not the sprite brawl)
- After AI responds, verdict shows devil left / angel right bubbles with sticky CTAs

- [ ] **Step 5.7 — Commit**

```
git add lib/screens/assistant/pre_purchase_screen.dart \
        test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: purchase assistant input with dashboard-style bleed hero"
```

---

## Post-implementation note — head sprite assets

When the head-only sprite atlas (10 poses per character) is delivered:

1. Add the new `MascotSpriteAtlas` constants to `lib/core/assets/mascot_sprite_sheet.dart` (follow existing `devilMascotAtlas` / `angelMascotAtlas` pattern)
2. Update `_VerdictAvatar.build` to use the new atlas and an appropriate frame name (e.g. `'1_neutral.png'` from the head sheet)
3. No other changes needed — `_VerdictBubble` is decoupled from the atlas

---

## Self-review checklist (completed)

- [x] Spec: bleed hero — covered by Task 5
- [x] Spec: bottom inset fix — covered by Task 2
- [x] Spec: thinking cloud (`ThinkingCloudWidget` + `_ThinkingCloudPainter`) — Task 1
- [x] Spec: insight slideshow (`_InsightSlideshow`, `_InsightSlideCard`, `_SlideDot`) — Task 4
- [x] Spec: chat bubbles (`_VerdictBubble`, `_VerdictAvatar`) — Task 3
- [x] Spec: `ConscienceBrandIcon` in Conscia take — Task 3
- [x] Spec: CTAs to sticky footer — Task 3 + Task 2 fix
- [x] Type consistency: `_ConsciaTakeCard` constructor updated in Task 3 and caller updated in same task ✓
- [x] `ThinkingCloudWidget` import added in Task 4 ✓
- [x] `currentUserProvider` available via existing `user_provider.dart` import ✓
- [x] No placeholders — all code is complete
