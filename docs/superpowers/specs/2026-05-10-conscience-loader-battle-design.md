# Conscience Loader Battle Design

Date: 2026-05-10

## Goal

Refresh the Flutter conscience loaders so they use the stronger sprite-script battle language while staying readable at loader size.

The new direction is:

- `Pre-purchase` uses a dramatic spend-vs-save fight loop.
- `Reflection` uses a calmer protection-and-recovery loop.
- `Idle` remains simple and non-combat.

## Why

The current loader motion is serviceable, but it only uses a small subset of the mascot language and does not take advantage of the expanded sprite sheets. The new script gives us clearer storytelling:

- the devil tempts and pressures
- the angel notices, intercepts, and protects
- the money visibly shifts between stress, risk, and safety

This should make pre-purchase feel more alive and make reflection feel more intentional without becoming visually noisy.

## Product Direction

### Pre-purchase

Pre-purchase should feel like an active internal debate. Each cycle escalates from temptation into conflict, then resolves into one of two outcomes:

- `saved`
- `spent`

The loader should not feel predetermined. It should branch between the two endings so repeated use feels less mechanical. The branch should be chosen once per cycle, not per frame.

### Reflection

Reflection should feel calmer and more restorative. It should still show the angel intervening, but it should avoid full panic, defeat, or loss. The emotional read should be:

- awareness
- intercept
- shield
- settle

### Idle

Idle remains a soft brand-presence state. It should not inherit the fight choreography.

## Recommended Technical Approach

Use `preset-authored phase tracks`.

This means each preset gets an explicit list of authored phases rather than deriving the entire sequence from a few thresholds and a handful of motion variables.

Why this approach:

- It matches the storyboard nature of the requested animation.
- It keeps `ConsciaAlterEgoMotion` understandable and tunable.
- It avoids introducing a heavier simulation system for a loader.
- It fits the existing widget and test structure better than a generic battle engine.

Alternatives considered:

- `Rule-driven battle simulator`
  Too flexible for the current need and likely harder to tune.
- `Frame-script sequencer only`
  Simpler, but too rigid if we want richer offsets, glow, shake, and branching behavior.

## Phase Design

### Pre-purchase phase track

Use an 8-step cycle:

1. `idle`
2. `tempt`
3. `driftLeft`
4. `clash`
5. `pressure`
6. `tug`
7. `resolve`
8. `settle`

#### Phase mapping

`idle`

- Devil: `neutral`
- Angel: `neutral`
- Money: `neutral`

`tempt`

- Devil: `whisper` or `coin`
- Angel: `neutral`
- Money: `neutral`

`driftLeft`

- Devil: `coin` or `sneak`
- Angel: `intercept`
- Money: `left`

`clash`

- Devil: `push`
- Angel: `block`
- Money: `squish`

`pressure`

- Devil: `force` or `ragePush`
- Angel: `lastStand`
- Money: `folded` or `afraid`

`tug`

- Devil: `receiptHook` or `tug`
- Angel: `tug`
- Money sequence: `left -> squish -> right -> squish`

`resolve`

Saved branch:

- Angel: `shield` or `holyBurst`
- Devil: `block` or `slip`
- Money: `burst -> right -> save`

Spent branch:

- Devil: `win`
- Angel: `lose`
- Money: `left` or `folded`

`settle`

Saved branch:

- Angel: `win` or `numberOne`
- Devil: `frustrated` or `lose`
- Money: `save`

Spent branch:

- Devil: `win`
- Angel: `lose`
- Money: `left` or `afraid`

### Reflection phase track

Use a 5-step cycle:

1. `idle`
2. `awareness`
3. `intercept`
4. `shield`
5. `settle`

#### Phase mapping

`idle`

- Devil: `neutral`
- Angel: `neutral`
- Money: `neutral`

`awareness`

- Devil: `whisper`
- Angel: `focusPray`
- Money: `neutral`

`intercept`

- Devil: `sneak` or `coin`
- Angel: `intercept`
- Money: slight `left`

`shield`

- Devil: `push` or `force`
- Angel: `shield` or `coinShield`
- Money: `save`

`settle`

- Devil: `neutral` or `block`
- Angel: `neutral` or `numberOne`
- Money: `save -> neutral`

Reflection explicitly excludes:

- `spent` ending
- angel defeat
- devil victory
- full panic climax

## Motion System Changes

Keep the work inside `ConsciaAlterEgoMotion`, but replace the current minimal threshold logic with authored phase-track data.

### Structure

Introduce richer pose enums:

- devil poses should include `neutral`, `push`, `block`, `force`, `tug`, `whisper`, `coin`, `receiptHook`, `sneak`, `ragePush`, `slip`, `frustrated`, `win`, `lose`
- angel poses should include `neutral`, `block`, `push`, `force`, `tug`, `shield`, `coinShield`, `intercept`, `focusPray`, `holyBurst`, `lastStand`, `wingBlock`, `numberOne`, `win`, `lose`
- money poses should include `neutral`, `left`, `right`, `save`, `afraid`, `squish`, `burst`, `folded`

Define a phase model per preset with fields such as:

- `durationSlice`
- `devilPose`
- `angelPose`
- `moneyPose`
- `devilOffsetBias`
- `angelOffsetBias`
- `moneyOffsetBias`
- `rotationBias`
- `glowBias`
- `shakeMode`
- `effectFlags`
- `outcomeBranch`

### Loop behavior

For `assistantLoading`:

- choose `saved` or `spent` once at the beginning of each cycle
- keep that branch fixed through `resolve` and `settle`
- restart with a fresh branch when the next cycle begins

For `reflectionLoading`:

- no branch selection
- always resolve to protection and calm

### Visual effects

Use small authored effects rather than a physics simulation:

- `tempt`: subtle devil slide-in and money wobble left
- `clash`: impact bounce and small shake
- `pressure`: tighter squeeze and stronger red pressure glow
- `tug`: lateral money oscillation
- `shield`: blue-gold pulse around angel and money
- `burst`: quick outward flash and release
- `settle`: gentler breathing and reduced motion

These effects should remain readable at current loader sizes.

## Randomness and Brand Tone

Pre-purchase should alternate endings, but the behavior should remain controlled.

Rules:

- randomness is selected once per cycle
- no mid-cycle branch flipping
- branch selection should be testable and injectable

Default product stance:

- allow both `saved` and `spent`
- keep timing and composition emotionally supportive rather than punitive

Implementation can bias toward `saved` slightly if tuning later suggests that equal branching feels too harsh, but initial implementation does not require a bias.

## Testing Strategy

Update the existing widget tests rather than introducing pixel-based animation tests.

### Required test coverage

- `assistantLoading` can render a saved-ending branch deterministically
- `assistantLoading` can render a spent-ending branch deterministically
- `reflectionLoading` never renders defeat or spent poses
- `idle` remains non-combat and stable

### Test mechanism

Add a deterministic branch-selection hook to `ConsciaAlterEgoMotion` for tests. Production can default to internal random branch selection, but tests must be able to force:

- `saved`
- `spent`

Tests should assert:

- rendered pose keys
- presence of core loader effects such as the ring where relevant
- absence of forbidden branches in reflection

Avoid snapshot-heavy or pixel-diff testing.

## Files Expected To Change

- `app/lib/widgets/conscience_mark.dart`
- `app/test/widgets/conscience_loader_test.dart`
- `app/test/screens/assistant/pre_purchase_screen_test.dart`
- any additional helper file if phase-track definitions become too large for `conscience_mark.dart`

If the authored phase data makes `conscience_mark.dart` too crowded, extracting loader phase definitions into a focused helper file is in scope.

## Non-Goals

- No Flame migration
- No physics engine
- No change to onboarding illustration choreography
- No change to the static brand mark painter
- No new asset generation

## Risks

### Loader readability

The expanded sprite set could make the loaders feel messy at small sizes. The mitigation is to use condensed authored tracks rather than full exhaustive scene playback.

### Reflection tone drift

Reflection could become too aggressive if it borrows too much from pre-purchase. The mitigation is the explicit calm-shield loop and the ban on defeat/loss endings there.

### Test brittleness

Branching animation can make tests flaky if randomness leaks into test runs. The mitigation is deterministic branch injection.

## Success Criteria

- Pre-purchase clearly reads as a dramatic internal battle with alternate endings.
- Reflection clearly reads as calm intervention and protection.
- Idle remains restrained.
- The implementation stays understandable inside the current Flutter widget structure.
- Tests remain deterministic and green.
