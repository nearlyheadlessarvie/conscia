# Conscience Loader Battle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the Flutter conscience loaders so pre-purchase uses an alternate-ending battle loop and reflection uses a calmer shield-and-settle loop, both driven by sprite-sheet phase tracks.

**Architecture:** Keep the loader inside `ConsciaAlterEgoMotion`, but replace the current threshold-based pose selection with authored phase tracks. Use small helper types for battle phases, motion targets, and branch selection so assistant and reflection presets can share one rendering pipeline while tests force deterministic outcomes.

**Tech Stack:** Flutter, Dart, `flutter_test`, sprite-sheet-backed `MascotSpriteFrame`

---

## File Structure

- Modify: `app/lib/core/assets/mascot_sprite_sheet.dart`
  Add the newly needed devil, angel, and money frame definitions so the loader can use the richer battle vocabulary.
- Create: `app/lib/widgets/conscience_loader_tracks.dart`
  Hold loader-specific enums, phase models, authored phase tracks, and branch-selection helpers so `conscience_mark.dart` does not become a giant data blob.
- Modify: `app/lib/widgets/conscience_mark.dart`
  Replace the current minimal pose logic with phase-track playback and deterministic branch support for tests.
- Modify: `app/test/widgets/conscience_loader_test.dart`
  Add test-first coverage for assistant saved/spent branches and reflection exclusions.
- Modify: `app/test/screens/assistant/pre_purchase_screen_test.dart`
  Keep the pre-purchase screen aligned with the updated loader keys and branch forcing.

---

### Task 1: Expand Sprite Atlas Coverage

**Files:**
- Modify: `app/lib/core/assets/mascot_sprite_sheet.dart`
- Test: `app/test/widgets/conscience_loader_test.dart`

- [ ] **Step 1: Write the failing test for new sprite-sheet frames**

Add a focused widget test that expects the assistant loader to be able to render a saved-ending pose we do not currently expose, such as angel `shield` and money `save`.

```dart
testWidgets(
  'ConscienceLoader can render assistant saved branch poses from the sprite sheet',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConscienceLoader(
            size: 90,
            preset: ConscienceLoaderPreset.assistant,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('conscience-angel-shield')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
  },
);
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/conscience_loader_test.dart --plain-name "ConscienceLoader can render assistant saved branch poses from the sprite sheet"`

Expected: FAIL because `conscience-angel-shield` and `conscience-money-save` are not reachable yet.

- [ ] **Step 3: Add the missing sprite frame definitions**

Extend `app/lib/core/assets/mascot_sprite_sheet.dart` with the exact additional entries needed by the design:

```dart
const devilMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/devil/sprite_sheet.png',
  sheetWidth: 6270,
  sheetHeight: 3762,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_push.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_block.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '4_lose.png': MascotSpriteRect(x: 3762, y: 0, width: 1254, height: 1254),
    '5_win.png': MascotSpriteRect(x: 5016, y: 0, width: 1254, height: 1254),
    '6_force.png': MascotSpriteRect(x: 0, y: 1254, width: 1254, height: 1254),
    '7_tug.png': MascotSpriteRect(x: 1254, y: 1254, width: 1254, height: 1254),
    '8_whisper.png': MascotSpriteRect(x: 2508, y: 1254, width: 1254, height: 1254),
    '9_coin.png': MascotSpriteRect(x: 3762, y: 1254, width: 1254, height: 1254),
    '10_receipthook.png': MascotSpriteRect(x: 5016, y: 1254, width: 1254, height: 1254),
    '11_sneak.png': MascotSpriteRect(x: 0, y: 2508, width: 1254, height: 1254),
    '12_ragepush.png': MascotSpriteRect(x: 1254, y: 2508, width: 1254, height: 1254),
    '13_slip.png': MascotSpriteRect(x: 2508, y: 2508, width: 1254, height: 1254),
    '14_frustrated.png': MascotSpriteRect(x: 3762, y: 2508, width: 1254, height: 1254),
  },
);
```

```dart
const angelMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/angel/sprite_sheet.png',
  sheetWidth: 6270,
  sheetHeight: 3762,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_block.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_push.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '4_win.png': MascotSpriteRect(x: 3762, y: 0, width: 1254, height: 1254),
    '5_lose.png': MascotSpriteRect(x: 5016, y: 0, width: 1254, height: 1254),
    '6_force.png': MascotSpriteRect(x: 0, y: 1254, width: 1254, height: 1254),
    '7_tug.png': MascotSpriteRect(x: 1254, y: 1254, width: 1254, height: 1254),
    '8_shield.png': MascotSpriteRect(x: 2508, y: 1254, width: 1254, height: 1254),
    '9_coinshield.png': MascotSpriteRect(x: 3762, y: 1254, width: 1254, height: 1254),
    '10_intercept.png': MascotSpriteRect(x: 5016, y: 1254, width: 1254, height: 1254),
    '11_focuspray.png': MascotSpriteRect(x: 0, y: 2508, width: 1254, height: 1254),
    '12_holyburst.png': MascotSpriteRect(x: 1254, y: 2508, width: 1254, height: 1254),
    '13_laststand.png': MascotSpriteRect(x: 2508, y: 2508, width: 1254, height: 1254),
    '14_wingblock.png': MascotSpriteRect(x: 3762, y: 2508, width: 1254, height: 1254),
    '15_numberone.png': MascotSpriteRect(x: 5016, y: 2508, width: 1254, height: 1254),
  },
);
```

```dart
const moneyMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/money/sprite_sheet.png',
  sheetWidth: 5016,
  sheetHeight: 2508,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_right.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_left.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '4_save.png': MascotSpriteRect(x: 3762, y: 0, width: 1254, height: 1254),
    '5_afraid.png': MascotSpriteRect(x: 0, y: 1254, width: 1254, height: 1254),
    '6_squish.png': MascotSpriteRect(x: 1254, y: 1254, width: 1254, height: 1254),
    '7_burst.png': MascotSpriteRect(x: 2508, y: 1254, width: 1254, height: 1254),
    '8_folded.png': MascotSpriteRect(x: 3762, y: 1254, width: 1254, height: 1254),
  },
);
```

- [ ] **Step 4: Run the targeted test again**

Run: `flutter test test/widgets/conscience_loader_test.dart --plain-name "ConscienceLoader can render assistant saved branch poses from the sprite sheet"`

Expected: still FAIL, but now only because the loader logic cannot yet select the saved branch poses.

- [ ] **Step 5: Commit the atlas-only expansion**

```bash
git add app/lib/core/assets/mascot_sprite_sheet.dart app/test/widgets/conscience_loader_test.dart
git commit -m "add loader sprite atlas coverage"
```

---

### Task 2: Introduce Loader Track Models And Branch Selection

**Files:**
- Create: `app/lib/widgets/conscience_loader_tracks.dart`
- Modify: `app/lib/widgets/conscience_mark.dart`
- Test: `app/test/widgets/conscience_loader_test.dart`

- [ ] **Step 1: Write the failing test for deterministic branch forcing**

Add a test that mounts `ConsciaAlterEgoMotion` directly and forces the assistant loader into the spent branch.

```dart
testWidgets(
  'ConsciaAlterEgoMotion can force the assistant spent branch in tests',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.assistantLoading,
            forcedOutcome: ConscienceBattleOutcome.spent,
            size: 90,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-devil-win')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-lose')), findsOneWidget);
  },
);
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/conscience_loader_test.dart --plain-name "ConsciaAlterEgoMotion can force the assistant spent branch in tests"`

Expected: FAIL because `forcedOutcome` and `ConscienceBattleOutcome` do not exist.

- [ ] **Step 3: Create the phase-track helper file**

Create `app/lib/widgets/conscience_loader_tracks.dart` with the enums and models the loader needs:

```dart
enum DevilBattlePose {
  neutral,
  push,
  block,
  force,
  tug,
  whisper,
  coin,
  receiptHook,
  sneak,
  ragePush,
  slip,
  frustrated,
  win,
  lose,
}

enum AngelBattlePose {
  neutral,
  block,
  push,
  force,
  tug,
  shield,
  coinShield,
  intercept,
  focusPray,
  holyBurst,
  lastStand,
  wingBlock,
  numberOne,
  win,
  lose,
}

enum MoneyBattlePose {
  neutral,
  left,
  right,
  save,
  afraid,
  squish,
  burst,
  folded,
}

enum ConscienceBattleOutcome { saved, spent }

enum LoaderShakeMode { none, light, impact, panic, tug }

class LoaderBattlePhase {
  const LoaderBattlePhase({
    required this.start,
    required this.end,
    required this.devilPose,
    required this.angelPose,
    required this.moneyPose,
    this.devilX = 0,
    this.angelX = 0,
    this.moneyX = 0,
    this.moneyY = 0,
    this.shake = LoaderShakeMode.none,
    this.shieldPulse = false,
    this.burstFlash = false,
    this.outcome,
  });

  final double start;
  final double end;
  final DevilBattlePose devilPose;
  final AngelBattlePose angelPose;
  final MoneyBattlePose moneyPose;
  final double devilX;
  final double angelX;
  final double moneyX;
  final double moneyY;
  final LoaderShakeMode shake;
  final bool shieldPulse;
  final bool burstFlash;
  final ConscienceBattleOutcome? outcome;

  bool contains(double t) => t >= start && t < end;
}
```

- [ ] **Step 4: Add authored assistant and reflection phase tracks**

In `app/lib/widgets/conscience_loader_tracks.dart`, define the fixed tracks from the design:

```dart
const assistantCommonPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.00,
    end: 0.12,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    moneyY: 0.16,
  ),
  LoaderBattlePhase(
    start: 0.12,
    end: 0.24,
    devilPose: DevilBattlePose.whisper,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    devilX: 0.05,
    moneyX: -0.04,
  ),
  LoaderBattlePhase(
    start: 0.24,
    end: 0.38,
    devilPose: DevilBattlePose.coin,
    angelPose: AngelBattlePose.intercept,
    moneyPose: MoneyBattlePose.left,
    devilX: 0.09,
    angelX: -0.08,
    moneyX: -0.12,
  ),
  LoaderBattlePhase(
    start: 0.38,
    end: 0.52,
    devilPose: DevilBattlePose.push,
    angelPose: AngelBattlePose.block,
    moneyPose: MoneyBattlePose.squish,
    shake: LoaderShakeMode.impact,
  ),
  LoaderBattlePhase(
    start: 0.52,
    end: 0.68,
    devilPose: DevilBattlePose.ragePush,
    angelPose: AngelBattlePose.lastStand,
    moneyPose: MoneyBattlePose.folded,
    moneyX: -0.08,
    shake: LoaderShakeMode.panic,
  ),
  LoaderBattlePhase(
    start: 0.68,
    end: 0.80,
    devilPose: DevilBattlePose.receiptHook,
    angelPose: AngelBattlePose.tug,
    moneyPose: MoneyBattlePose.right,
    moneyX: 0.10,
    shake: LoaderShakeMode.tug,
  ),
];
```

```dart
const assistantSavedPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.80,
    end: 0.92,
    devilPose: DevilBattlePose.slip,
    angelPose: AngelBattlePose.shield,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.12,
    shieldPulse: true,
    outcome: ConscienceBattleOutcome.saved,
  ),
  LoaderBattlePhase(
    start: 0.92,
    end: 1.01,
    devilPose: DevilBattlePose.frustrated,
    angelPose: AngelBattlePose.numberOne,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.14,
    outcome: ConscienceBattleOutcome.saved,
  ),
];
```

```dart
const assistantSpentPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.80,
    end: 0.92,
    devilPose: DevilBattlePose.win,
    angelPose: AngelBattlePose.lose,
    moneyPose: MoneyBattlePose.left,
    moneyX: -0.14,
    outcome: ConscienceBattleOutcome.spent,
  ),
  LoaderBattlePhase(
    start: 0.92,
    end: 1.01,
    devilPose: DevilBattlePose.win,
    angelPose: AngelBattlePose.lose,
    moneyPose: MoneyBattlePose.afraid,
    moneyX: -0.10,
    shake: LoaderShakeMode.panic,
    outcome: ConscienceBattleOutcome.spent,
  ),
];
```

```dart
const reflectionPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.00,
    end: 0.22,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    moneyY: 0.16,
  ),
  LoaderBattlePhase(
    start: 0.22,
    end: 0.42,
    devilPose: DevilBattlePose.whisper,
    angelPose: AngelBattlePose.focusPray,
    moneyPose: MoneyBattlePose.neutral,
  ),
  LoaderBattlePhase(
    start: 0.42,
    end: 0.64,
    devilPose: DevilBattlePose.sneak,
    angelPose: AngelBattlePose.intercept,
    moneyPose: MoneyBattlePose.left,
    moneyX: -0.05,
  ),
  LoaderBattlePhase(
    start: 0.64,
    end: 0.84,
    devilPose: DevilBattlePose.push,
    angelPose: AngelBattlePose.coinShield,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.04,
    shieldPulse: true,
  ),
  LoaderBattlePhase(
    start: 0.84,
    end: 1.01,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.save,
  ),
];
```

- [ ] **Step 5: Add branch forcing and phase lookup in `conscience_mark.dart`**

Update `ConsciaAlterEgoMotion` to accept a test-only override and resolve a phase from authored tracks:

```dart
class ConsciaAlterEgoMotion extends StatefulWidget {
  const ConsciaAlterEgoMotion({
    super.key,
    required this.preset,
    this.size = 96,
    this.forcedOutcome,
  });

  final ConsciaAlterEgoPreset preset;
  final double size;
  final ConscienceBattleOutcome? forcedOutcome;
}
```

```dart
late ConscienceBattleOutcome _activeOutcome;

ConscienceBattleOutcome _pickOutcome() {
  if (widget.forcedOutcome case final forced?) return forced;
  return math.Random().nextBool()
      ? ConscienceBattleOutcome.saved
      : ConscienceBattleOutcome.spent;
}
```

```dart
LoaderBattlePhase _phaseForPreset(ConsciaAlterEgoPreset preset, double t) {
  final phases = switch (preset) {
    ConsciaAlterEgoPreset.idle => reflectionPhases,
    ConsciaAlterEgoPreset.assistantLoading => [
        ...assistantCommonPhases,
        ...(_activeOutcome == ConscienceBattleOutcome.saved
            ? assistantSavedPhases
            : assistantSpentPhases),
      ],
    ConsciaAlterEgoPreset.reflectionLoading => reflectionPhases,
  };

  return phases.firstWhere((phase) => phase.contains(t));
}
```

- [ ] **Step 6: Run the deterministic spent-branch test**

Run: `flutter test test/widgets/conscience_loader_test.dart --plain-name "ConsciaAlterEgoMotion can force the assistant spent branch in tests"`

Expected: PASS.

- [ ] **Step 7: Commit the track-model and branch-selection scaffolding**

```bash
git add app/lib/widgets/conscience_loader_tracks.dart app/lib/widgets/conscience_mark.dart app/test/widgets/conscience_loader_test.dart
git commit -m "add loader phase tracks and branch forcing"
```

---

### Task 3: Replace Loader Rendering With Authored Battle Poses

**Files:**
- Modify: `app/lib/widgets/conscience_mark.dart`
- Test: `app/test/widgets/conscience_loader_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 1: Write the failing tests for saved, spent, and calm reflection states**

Expand `app/test/widgets/conscience_loader_test.dart` to cover all required branches:

```dart
testWidgets(
  'ConscienceLoader renders assistant saved branch poses',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.assistantLoading,
            forcedOutcome: ConscienceBattleOutcome.saved,
            size: 90,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-angel-shield')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
  },
);
```

```dart
testWidgets(
  'ConscienceLoader renders assistant spent branch poses',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.assistantLoading,
            forcedOutcome: ConscienceBattleOutcome.spent,
            size: 90,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-devil-win')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-lose')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-afraid')), findsOneWidget);
  },
);
```

```dart
testWidgets(
  'ConscienceLoader reflection stays in calm protection poses',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.reflectionLoading,
            size: 90,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-angel-coinShield')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-money-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('conscience-angel-lose')), findsNothing);
    expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
  },
);
```

- [ ] **Step 2: Run the loader test file**

Run: `flutter test test/widgets/conscience_loader_test.dart`

Expected: FAIL because the widget still maps only the old reduced pose set.

- [ ] **Step 3: Replace the reduced pose mapping with authored battle-pose maps**

In `app/lib/widgets/conscience_mark.dart`, replace `_CharacterPose` and `_MoneyPose` with the richer pose enums and maps imported from `conscience_loader_tracks.dart`:

```dart
const _devilPoseFrames = <DevilBattlePose, String>{
  DevilBattlePose.neutral: '1_neutral.png',
  DevilBattlePose.push: '2_push.png',
  DevilBattlePose.block: '3_block.png',
  DevilBattlePose.lose: '4_lose.png',
  DevilBattlePose.win: '5_win.png',
  DevilBattlePose.force: '6_force.png',
  DevilBattlePose.tug: '7_tug.png',
  DevilBattlePose.whisper: '8_whisper.png',
  DevilBattlePose.coin: '9_coin.png',
  DevilBattlePose.receiptHook: '10_receipthook.png',
  DevilBattlePose.sneak: '11_sneak.png',
  DevilBattlePose.ragePush: '12_ragepush.png',
  DevilBattlePose.slip: '13_slip.png',
  DevilBattlePose.frustrated: '14_frustrated.png',
};
```

```dart
const _angelPoseFrames = <AngelBattlePose, String>{
  AngelBattlePose.neutral: '1_neutral.png',
  AngelBattlePose.block: '2_block.png',
  AngelBattlePose.push: '3_push.png',
  AngelBattlePose.win: '4_win.png',
  AngelBattlePose.lose: '5_lose.png',
  AngelBattlePose.force: '6_force.png',
  AngelBattlePose.tug: '7_tug.png',
  AngelBattlePose.shield: '8_shield.png',
  AngelBattlePose.coinShield: '9_coinshield.png',
  AngelBattlePose.intercept: '10_intercept.png',
  AngelBattlePose.focusPray: '11_focuspray.png',
  AngelBattlePose.holyBurst: '12_holyburst.png',
  AngelBattlePose.lastStand: '13_laststand.png',
  AngelBattlePose.wingBlock: '14_wingblock.png',
  AngelBattlePose.numberOne: '15_numberone.png',
};
```

```dart
const _moneyPoseFrames = <MoneyBattlePose, String>{
  MoneyBattlePose.neutral: '1_neutral.png',
  MoneyBattlePose.right: '2_right.png',
  MoneyBattlePose.left: '3_left.png',
  MoneyBattlePose.save: '4_save.png',
  MoneyBattlePose.afraid: '5_afraid.png',
  MoneyBattlePose.squish: '6_squish.png',
  MoneyBattlePose.burst: '7_burst.png',
  MoneyBattlePose.folded: '8_folded.png',
};
```

- [ ] **Step 4: Drive motion from the authored phase data**

Replace `_frameForPreset` and `_motionForPreset` with a single phase-driven rendering path:

```dart
final battlePhase = _phaseForPreset(widget.preset, t);

final devilOffset = Offset(
  -widget.size * (0.42 - battlePhase.devilX),
  -widget.size * 0.05,
);

final angelOffset = Offset(
  widget.size * (0.46 + battlePhase.angelX),
  -widget.size * 0.15,
);

final moneyShake = switch (battlePhase.shake) {
  LoaderShakeMode.none => Offset.zero,
  LoaderShakeMode.light => Offset(math.sin(t * math.pi * 12) * widget.size * 0.004, 0),
  LoaderShakeMode.impact => Offset(math.sin(t * math.pi * 24) * widget.size * 0.007, 0),
  LoaderShakeMode.panic => Offset(math.sin(t * math.pi * 30) * widget.size * 0.01, 0),
  LoaderShakeMode.tug => Offset(math.sin(t * math.pi * 18) * widget.size * 0.012, 0),
};

final moneyOffset = Offset(
  widget.size * battlePhase.moneyX,
  widget.size * battlePhase.moneyY,
) + moneyShake;
```

Use the new pose keys for the switchers:

```dart
child: _PoseAssetImage(
  atlas: devilMascotAtlas,
  frameName: _devilPoseFrames[battlePhase.devilPose]!,
  keyValue: 'conscience-devil-${battlePhase.devilPose.name}',
  width: widget.size * 0.98,
),
```

- [ ] **Step 5: Update the pre-purchase screen test to match the new idle and assistant semantics**

In `app/test/screens/assistant/pre_purchase_screen_test.dart`, keep the screen-level assertion focused on the loader shell and the non-combat idle hero:

```dart
expect(find.byKey(const ValueKey('conscience-alter-ego-idle')), findsOneWidget);
expect(find.byKey(const ValueKey('conscience-devil-neutral')), findsOneWidget);
expect(find.byKey(const ValueKey('conscience-angel-neutral')), findsOneWidget);
expect(find.byKey(const ValueKey('conscience-money-neutral')), findsOneWidget);
```

If the screen test currently inspects assistant-loading poses, move those assertions into `conscience_loader_test.dart` instead.

- [ ] **Step 6: Run the two affected test files**

Run: `flutter test test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit the rendered battle-pose refactor**

```bash
git add app/lib/widgets/conscience_mark.dart app/test/widgets/conscience_loader_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "refactor conscience loader battle rendering"
```

---

### Task 4: Polish Phase Timing, Effects, And Full Verification

**Files:**
- Modify: `app/lib/widgets/conscience_loader_tracks.dart`
- Modify: `app/lib/widgets/conscience_mark.dart`
- Test: `app/test/widgets/conscience_loader_test.dart`

- [ ] **Step 1: Write the failing test for the reflection exclusion rule**

Add one explicit regression test that the reflection preset never produces defeat-state keys at the sampled test point.

```dart
testWidgets(
  'Reflection loader does not expose spent-ending defeat keys',
  (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsciaAlterEgoMotion(
            preset: ConsciaAlterEgoPreset.reflectionLoading,
            size: 72,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conscience-devil-win')), findsNothing);
    expect(find.byKey(const ValueKey('conscience-angel-lose')), findsNothing);
  },
);
```

- [ ] **Step 2: Run the test to verify behavior before final tuning**

Run: `flutter test test/widgets/conscience_loader_test.dart --plain-name "Reflection loader does not expose spent-ending defeat keys"`

Expected: PASS if Task 3 was correct. If it fails, stop and fix the reflection track before further polish.

- [ ] **Step 3: Tune the loader durations and visual effects**

Adjust the preset durations in `app/lib/widgets/conscience_mark.dart` to fit the new choreography:

```dart
Duration get _duration => switch (widget.preset) {
  ConsciaAlterEgoPreset.idle => const Duration(seconds: 5),
  ConsciaAlterEgoPreset.assistantLoading => const Duration(milliseconds: 2800),
  ConsciaAlterEgoPreset.reflectionLoading => const Duration(milliseconds: 2200),
};
```

Use the authored flags when painting effects:

```dart
final shieldGlowBoost = battlePhase.shieldPulse ? 0.12 : 0.0;
final burstBoost = battlePhase.burstFlash ? 0.18 : 0.0;

final blueOpacity = switch (widget.preset) {
      ConsciaAlterEgoPreset.idle => 0.2 + phase * 0.07,
      ConsciaAlterEgoPreset.assistantLoading => 0.25 + phase * 0.14 + shieldGlowBoost,
      ConsciaAlterEgoPreset.reflectionLoading => 0.21 + phase * 0.09 + shieldGlowBoost,
    } + burstBoost;
```

Keep the tuning conservative so the loader stays readable.

- [ ] **Step 4: Run full app tests**

Run: `flutter test`

Expected: `All tests passed!`

- [ ] **Step 5: Format the touched Dart files**

Run: `dart format lib/core/assets/mascot_sprite_sheet.dart lib/widgets/conscience_loader_tracks.dart lib/widgets/conscience_mark.dart test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart`

Expected: formatter completes with no errors.

- [ ] **Step 6: Re-run the targeted verification after formatting**

Run: `flutter test test/widgets/conscience_loader_test.dart test/screens/assistant/pre_purchase_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 7: Commit the final loader polish**

```bash
git add app/lib/core/assets/mascot_sprite_sheet.dart app/lib/widgets/conscience_loader_tracks.dart app/lib/widgets/conscience_mark.dart app/test/widgets/conscience_loader_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "polish conscience loader battle phases"
```

---

## Self-Review

### Spec coverage

- Alternate pre-purchase outcomes are covered in Tasks 2 and 3.
- Calm reflection loop and its exclusions are covered in Tasks 2, 3, and 4.
- Idle staying non-combat is preserved in Task 3 screen-level assertions.
- Test determinism is covered in Task 2 branch forcing and Task 3 branch tests.
- Richer sprite usage is covered in Task 1 atlas expansion and Task 3 pose maps.

No gaps found against the approved spec.

### Placeholder scan

- No `TODO`, `TBD`, or “appropriate handling” placeholders remain.
- Every implementation step includes exact files, code samples, and commands.

### Type consistency

- Branch enum uses `ConscienceBattleOutcome.saved` and `.spent` consistently.
- Pose maps and key names consistently use `.name` values for `ValueKey` construction.
- Helper model names are consistent between creation and consumption steps.
