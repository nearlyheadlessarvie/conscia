# Alter Ego Loader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current creepy AI loader with a shared, image-based alter-ego animation used by both Pre-Purchase Assistant and Reflection loading states.

**Architecture:** Keep the loader code-native in Flutter, but switch the centerpiece from the vector `ConscienceMark` to a raster alter-ego image asset. Build one reusable `ConscienceLoader` scene with restrained aura/ring/pulse animation, then wire it into the existing assistant and reflection loading surfaces without changing their higher-level flow.

**Tech Stack:** Flutter, `AnimationController`, `AnimatedBuilder`, custom layout/transform widgets, Flutter widget tests

---

## File Structure

- `app/lib/widgets/conscience_mark.dart`
  - Keep `ConscienceMark` for brand-mark usage
  - Replace `ConscienceLoader` internals with the new alter-ego scene
- `app/lib/screens/assistant/pre_purchase_screen.dart`
  - Continue using the shared loader in the assistant loading state
  - Update label/copy only if needed
- `app/lib/screens/transactions/transaction_detail_screen.dart`
  - Continue using the shared loader in reflection loading
  - Update label/copy only if needed
- `app/pubspec.yaml`
  - Ensure the alter-ego asset is available under the already-included `assets/images/` path
- `app/test/widgets/conscience_loader_test.dart`
  - New focused widget coverage for the shared loader structure
- `app/test/screens/assistant/pre_purchase_screen_test.dart`
  - Confirm the assistant loading state still renders the loader and label
- `app/test/screens/transactions/transaction_detail_screen_test.dart`
  - Confirm reflection loading still renders the loader and label

---

### Task 1: Add Shared Loader Test Coverage

**Files:**
- Create: `app/test/widgets/conscience_loader_test.dart`
- Modify: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Modify: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Write the failing shared-loader widget tests**

Add `app/test/widgets/conscience_loader_test.dart`:

```dart
import 'package:conscia_app/widgets/conscience_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConscienceLoader renders alter ego scene and label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(
            size: 90,
            label: 'Your conscience is weighing both sides...',
          ),
        ),
      ),
    );

    expect(find.text('Your conscience is weighing both sides...'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-ring')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-loader-flash')), findsOneWidget);
  });

  testWidgets('ConscienceLoader supports no-label mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(size: 72),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
```

Update `app/test/screens/assistant/pre_purchase_screen_test.dart` by adding:

```dart
testWidgets('shows shared loader while AI response is pending', (tester) async {
  // Reuse existing fake AI service override that delays the response.
  await tester.pumpWidget(buildPrePurchaseAppWithDelayedAi());

  await tester.enterText(find.byType(TextField).first, 'Coffee');
  await tester.enterText(find.byType(TextField).at(1), '180');
  await tester.tap(find.text('Dining'));
  await tester.pump();

  await tester.tap(find.text('Ask Conscia'));
  await tester.pump();

  expect(find.text('Your conscience is weighing both sides...'), findsOneWidget);
  expect(find.byType(ConscienceLoader), findsOneWidget);
});
```

Update `app/test/screens/transactions/transaction_detail_screen_test.dart` by adding:

```dart
testWidgets('shows shared loader while reflection is loading', (tester) async {
  await tester.pumpWidget(buildTransactionDetailAppWithDelayedReflection());

  await tester.tap(find.text('Ask AI to Reflect'));
  await tester.pump();

  expect(find.byType(ConscienceLoader), findsOneWidget);
  expect(find.text('Reflection is making sense of the moment...'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
flutter test test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
```

Expected:
- FAIL because the current loader does not render a real `Image`
- FAIL because the keyed ring/flash layers do not exist yet

- [ ] **Step 3: Commit the failing tests**

```bash
git add app/test/widgets/conscience_loader_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "test: cover alter ego loader states"
```

---

### Task 2: Replace ConscienceLoader With Alter Ego Scene

**Files:**
- Modify: `app/lib/widgets/conscience_mark.dart`
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Replace the loader internals with an image-based animation**

In `app/lib/widgets/conscience_mark.dart`, keep `ConscienceMark` unchanged and replace the current `_ConscienceLoaderState.build` scene with a new layered animation. Add a private asset constant near the loader:

```dart
const _alterEgoAsset = 'assets/images/conscia_alterego.png';
```

Replace the current `AnimatedBuilder` body in `_ConscienceLoaderState.build` with:

```dart
return AnimatedBuilder(
  animation: _controller,
  builder: (context, _) {
    final t = _controller.value;
    final clash = math.sin(t * math.pi * 8).abs();
    final breathe = 1 + math.sin(t * math.pi * 2) * 0.018;
    final ringRotation = t * math.pi * 2;
    final flashSize = 20 + clash * 22;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size * 2.8,
          height: widget.size * 2.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-widget.size * 0.18 - clash * 4, 0),
                child: _AuraGlow(
                  color: const Color(0x66FF4B3A),
                  size: widget.size * (1.75 + clash * 0.12),
                ),
              ),
              Transform.translate(
                offset: Offset(widget.size * 0.18 + clash * 4, 0),
                child: _AuraGlow(
                  color: const Color(0x6656D6FF),
                  size: widget.size * (1.75 + clash * 0.12),
                ),
              ),
              Transform.rotate(
                angle: ringRotation,
                child: Container(
                  key: const ValueKey('conscience-loader-ring'),
                  width: widget.size * 1.72,
                  height: widget.size * 1.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.outlineVariant.withValues(
                        alpha: 0.22 + clash * 0.14,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: breathe + clash * 0.01,
                child: ClipOval(
                  child: Image.asset(
                    _alterEgoAsset,
                    width: widget.size * 1.45,
                    height: widget.size * 1.45,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                key: const ValueKey('conscience-loader-flash'),
                width: flashSize,
                height: flashSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: clash * 0.10),
                ),
              ),
              Positioned(
                bottom: widget.size * 0.08 + math.sin(t * math.pi * 2) * 4,
                child: Text(
                  '\$',
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFFFC94D).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(
                        color: Color(0x99FFB300),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  },
);
```

Also add a small reusable private glow widget under the loader state:

```dart
class _AuraGlow extends StatelessWidget {
  const _AuraGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.24,
            spreadRadius: size * 0.03,
          ),
        ],
      ),
    );
  }
}
```

Do not reintroduce `_MiniDevilBadge` or `_MiniAngelBadge`.

- [ ] **Step 2: Remove the old mini-badge loader helpers**

Delete these classes entirely from `app/lib/widgets/conscience_mark.dart`:

```dart
class _MiniDevilBadge extends StatelessWidget { ... }
class _MiniAngelBadge extends StatelessWidget { ... }
```

The new loader should no longer depend on them.

- [ ] **Step 3: Verify the asset path remains valid**

Confirm `app/pubspec.yaml` still includes the image folder:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
    - assets/images/
```

No new dependency should be added.

- [ ] **Step 4: Run the tests to verify the new loader passes**

Run:

```bash
flutter test test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 5: Run analyzer on the touched files**

Run:

```bash
flutter analyze lib/widgets/conscience_mark.dart lib/screens/assistant/pre_purchase_screen.dart lib/screens/transactions/transaction_detail_screen.dart test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
```

Expected:
- `No issues found!`

- [ ] **Step 6: Commit the loader implementation**

```bash
git add app/lib/widgets/conscience_mark.dart app/pubspec.yaml app/test/widgets/conscience_loader_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "feat: replace ai loader with alter ego animation"
```

---

### Task 3: Tune Surface Copy and Layout

**Files:**
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`

- [ ] **Step 1: Update assistant and reflection labels only if they drifted during implementation**

Ensure `PrePurchaseScreen._buildLoading()` uses:

```dart
const TypingIndicator(
  label: 'Your conscience is weighing both sides...',
),
```

Ensure `_ReflectionSheet.build()` uses:

```dart
const Center(
  child: ConscienceLoader(
    size: 90,
    label: 'Reflection is making sense of the moment...',
  ),
)
```

Do not change the higher-level screen flow or replace the loader with a generic spinner.

- [ ] **Step 2: Run focused regression tests**

Run:

```bash
flutter test test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 3: Commit the surface polish if there were file changes**

```bash
git add app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart
git commit -m "fix: keep alter ego loader labels consistent"
```

If no file changes were needed in this task, skip this commit.

---

## Self-Review

### Spec coverage
- Replace creepy drifting mini-badge effect: covered by Task 2
- Use alter-ego image asset: covered by Task 2
- Reuse same loader in assistant + reflection: covered by Tasks 1 and 3
- Keep motion premium and stable: covered by Task 2 scene design
- No new animation package: enforced in Task 2

### Placeholder scan
- No TODO/TBD placeholders
- Exact files, commands, and expected outcomes included

### Type consistency
- `ConscienceLoader` remains the shared public widget name
- helper widget names (`_AuraGlow`) are introduced only in the loader task
- test references (`ValueKey('conscience-loader-ring')`, `ValueKey('conscience-loader-flash')`) match implementation names
