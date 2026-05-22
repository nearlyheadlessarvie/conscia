# Level Up Confetti Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a continuous, upper-half-only confetti celebration to the level-up screen using paper pieces and streamers, without reducing readability of the ceremony content.

**Architecture:** Add a focused animated confetti widget for the journey level-up screen, driven by a single repeating animation controller and a custom painter with seeded particle specs. Integrate it into the existing level-up `Stack` behind the content column and clip it to the upper half of the screen so the CTA and lower copy stay clean.

**Tech Stack:** Flutter, Dart, custom painter, animation controller, widget tests

---

## File Structure

- Create: `app/lib/screens/journey/level_up_confetti.dart`
  - Own the confetti widget, particle data model, animation controller wiring, and painter.
- Modify: `app/lib/screens/journey/level_up_screen.dart`
  - Insert the confetti layer into the ceremony stack and expose a stable key for tests.
- Modify: `app/test/screens/journey/level_up_screen_test.dart`
  - Add assertions for confetti presence and keep existing layout expectations intact.

---

### Task 1: Add the Confetti Widget With Test-First Coverage

**Files:**
- Create: `app/lib/screens/journey/level_up_confetti.dart`
- Modify: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Extend the level-up screen test to assert the confetti layer exists**

Add this assertion to `app/test/screens/journey/level_up_screen_test.dart` inside the existing test:

```dart
    expect(
      find.byKey(const ValueKey('journey-level-up-confetti')),
      findsOneWidget,
    );
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: FAIL because the confetti widget/key does not exist yet.

- [ ] **Step 3: Create the confetti widget file with a minimal test-passing shell**

Create `app/lib/screens/journey/level_up_confetti.dart`:

```dart
import 'package:flutter/material.dart';

class LevelUpConfetti extends StatelessWidget {
  const LevelUpConfetti({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        key: const ValueKey('journey-level-up-confetti'),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test again and confirm it still fails because the screen does not render the widget**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: FAIL because `LevelUpScreen` is not using `LevelUpConfetti` yet.

- [ ] **Step 5: Commit the test-first shell**

```bash
git add app/lib/screens/journey/level_up_confetti.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "test(app): add level up confetti coverage"
```

---

### Task 2: Integrate the Confetti Layer Into the Level-Up Screen

**Files:**
- Modify: `app/lib/screens/journey/level_up_screen.dart`
- Use: `app/lib/screens/journey/level_up_confetti.dart`

- [ ] **Step 1: Import the confetti widget into the level-up screen**

Add:

```dart
import 'level_up_confetti.dart';
```

to `app/lib/screens/journey/level_up_screen.dart`.

- [ ] **Step 2: Insert the confetti layer between the atmosphere painter and the content column**

Inside the `Stack` in `LevelUpScreen`, add:

```dart
                          Positioned.fill(
                            child: LevelUpConfetti(compact: compact),
                          ),
```

so the stack order becomes:

```dart
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LevelUpAtmospherePainter(appColors),
                            ),
                          ),
                          Positioned.fill(
                            child: LevelUpConfetti(compact: compact),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
```

- [ ] **Step 3: Run the level-up test and confirm it passes with the screen integration**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: PASS, with existing content still present and the confetti key found.

- [ ] **Step 4: Commit the screen integration**

```bash
git add app/lib/screens/journey/level_up_screen.dart
git commit -m "feat(app): place confetti layer in level up screen"
```

---

### Task 3: Implement Continuous Upper-Half Confetti Motion

**Files:**
- Modify: `app/lib/screens/journey/level_up_confetti.dart`

- [ ] **Step 1: Replace the stateless shell with a stateful animated confetti widget**

Update `LevelUpConfetti` to use an animation controller:

```dart
class LevelUpConfetti extends StatefulWidget {
  const LevelUpConfetti({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  State<LevelUpConfetti> createState() => _LevelUpConfettiState();
}

class _LevelUpConfettiState extends State<LevelUpConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox.expand(
            key: const ValueKey('journey-level-up-confetti'),
            child: CustomPaint(
              painter: _LevelUpConfettiPainter(
                progress: _controller.value,
                colors: _confettiColors(context),
                compact: widget.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Add seeded particle specifications and palette helpers**

Add local private types and helpers in `level_up_confetti.dart`:

```dart
enum _ConfettiShape { paper, streamer }

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.seed,
    required this.lane,
    required this.size,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.delay,
    required this.opacity,
    required this.shape,
    required this.colorIndex,
  });

  final double seed;
  final double lane;
  final double size;
  final double speed;
  final double drift;
  final double rotation;
  final double delay;
  final double opacity;
  final _ConfettiShape shape;
  final int colorIndex;
}

List<Color> _confettiColors(BuildContext context) {
  final appColors = Theme.of(context).extension<dynamic>();
  final colors = Theme.of(context).colorScheme;
  return [
    colors.primary,
    colors.secondary,
    const Color(0xFFE9A93B),
    const Color(0xFF5AA7E8),
    const Color(0xFF7B7FE8),
    const Color(0xFF3EAD74),
  ];
}
```

Then add a deterministic particle list builder inside the file, with fewer particles for compact mode and more for normal mode.

- [ ] **Step 3: Implement the custom painter with upper-half clipping and continuous reseeded motion**

Add `_LevelUpConfettiPainter` that:
- clips drawing to the upper half
- draws rectangles for paper pieces
- draws short bezier ribbon strokes for streamers
- computes per-particle local progress using `delay`
- wraps particles independently so the loop does not visibly reset all at once

Use this structure:

```dart
class _LevelUpConfettiPainter extends CustomPainter {
  const _LevelUpConfettiPainter({
    required this.progress,
    required this.colors,
    required this.compact,
  });

  final double progress;
  final List<Color> colors;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final clipHeight = size.height * 0.56;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));

    for (final particle in _particlesFor(compact)) {
      final local = (progress + particle.delay) % 1.0;
      final y = lerpDouble(-40, clipHeight + 36, local * particle.speed)!;
      final x = size.width *
          (0.1 + particle.lane * 0.8) +
          sin((local + particle.seed) * 6.28318) * particle.drift;
      final angle = (local * particle.rotation * 6.28318) + particle.seed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      if (particle.shape == _ConfettiShape.paper) {
        // draw rounded paper piece
      } else {
        // draw short curved streamer
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LevelUpConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.compact != compact ||
        oldDelegate.colors != colors;
  }
}
```

- [ ] **Step 4: Run the screen test and a focused analyzer pass**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
flutter analyze lib/screens/journey/level_up_screen.dart lib/screens/journey/level_up_confetti.dart test/screens/journey/level_up_screen_test.dart
```

Expected: PASS / no issues found.

- [ ] **Step 5: Commit the animated confetti implementation**

```bash
git add app/lib/screens/journey/level_up_confetti.dart
git commit -m "feat(app): add looping confetti to level up screen"
```

---

### Task 4: Add Compact-Screen Regression Coverage

**Files:**
- Modify: `app/test/screens/journey/level_up_screen_test.dart`

- [ ] **Step 1: Add a compact-height test that still finds key content and the confetti layer**

Append this test:

```dart
  testWidgets('level up screen keeps confetti and core copy on compact height',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpScreen(summary: _summary()),
      ),
    );

    expect(find.byKey(const ValueKey('journey-level-up-confetti')), findsOneWidget);
    expect(find.text('Budget Guardian'), findsOneWidget);
    expect(find.text('Continue your journey'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the focused test file**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
```

Expected: PASS.

- [ ] **Step 3: Commit the compact regression test**

```bash
git add app/test/screens/journey/level_up_screen_test.dart
git commit -m "test(app): cover compact level up confetti layout"
```

---

### Task 5: Final Verification

**Files:**
- Verify only

- [ ] **Step 1: Run the final focused verification commands**

Run:

```bash
flutter test test/screens/journey/level_up_screen_test.dart
flutter analyze lib/screens/journey/level_up_screen.dart lib/screens/journey/level_up_confetti.dart test/screens/journey/level_up_screen_test.dart
```

Expected:
- tests pass
- no analyzer issues

- [ ] **Step 2: Manual preview verification**

Run:

```bash
flutter run -d chrome
```

Then open a level preview route such as:

```text
/debug/journey/level-up/money-monk
```

Check manually:
- confetti stays in the upper half
- motion feels continuous, not burst-reset
- button and XP pill remain readable
- medallion remains visually dominant

- [ ] **Step 3: Commit if any final tuning was needed during manual review**

```bash
git add app/lib/screens/journey/level_up_screen.dart app/lib/screens/journey/level_up_confetti.dart app/test/screens/journey/level_up_screen_test.dart
git commit -m "refactor(app): tune level up confetti motion"
```

Only do this step if the manual review produced actual code changes.
