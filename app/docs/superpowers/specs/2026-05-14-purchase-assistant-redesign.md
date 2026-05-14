# Purchase Assistant Redesign

**Date:** 2026-05-14
**Status:** Approved for implementation

## Overview

Redesign three states of `PrePurchaseScreen` — Input, Conscience Check loader, and Verdict — to fix CTA visibility, replace the awkward sprite-brawl loader with a meaningful insight slideshow, and upgrade the verdict to a conversational bubble layout with chibi avatars.

---

## Screen 1 — Input

### Goal
Mirror the dashboard's bleed-edge hero structure so the assistant entry point feels cohesive with the rest of the app.

### Layout
- **Hero section**: full-width bleed (no horizontal margins), `borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))`, gradient `navySoft → amberSoft` (same tokens as the dashboard hero, `begin: Alignment.topLeft, end: Alignment.bottomRight`)
- **Inside hero**:
  - Identity row at the top: avatar (`ConscienceAlterEgo`, compact size), "Welcome back" greeting + display name, notification bell — pulled from existing `userProvider` / `alertsCount`
  - Mascot + tagline below: `ConsciaAlterEgoMotion(preset: idle, size: 56)`, `headlineSmall` "Let's think this through" in `deepNavy`, `bodySmall` subtitle in `mutedInk`
- **Scope toggle** (`ScopePillSwitch`): placed immediately below the hero bleed in the scroll area, shown only when `hasFamilySpace`
- **Form fields**: description text field, `AmountHeroField`, `TransactionStyleCategorySelector` — unchanged
- **CTA**: `HeroScreenScaffold(bottom: FilledButton(...))` — already wired; root cause of the current overlap is that `HeroScreenScaffold` creates a nested `Scaffold` whose `SafeArea` does not automatically inherit the shell's `BottomNavigationBar` height. Fix: investigate at implementation time — the root cause is that the nested `Scaffold` inside `HeroScreenScaffold` may not inherit the shell nav's bottom safe area inset. Verify with a debug border and fix whichever layer is responsible (likely an `AnimatedPadding` that needs the shell's bottom inset added).

### Changes to `_buildInputForm`
- Replace the existing `Container(decoration: BoxDecoration(gradient: ...))` hero card (which has side margins and all-corner radius) with a new `_AssistantHeroBleed` widget that bleeds edge-to-edge
- Add identity row inside the hero (reuse `_DashboardIdentityRow` or extract a shared widget)
- Remove `padding: const EdgeInsets.fromLTRB(16, 20, 16, 12)` from `HeroScreenScaffold` — the hero provides its own top space; form padding stays at `fromLTRB(16, 14, 16, 12)`

---

## Screen 2 — Conscience Check Loader

### Goal
Replace the static sprite-brawl scene with a two-part layout: an animated "thinking cloud" on top and an auto-advancing insight slideshow below.

### Thinking Cloud (`ThinkingCloudWidget`)

A new `StatefulWidget` with an `AnimationController` driving a `CustomPainter` extended from the `_GalaxyBackgroundPainter` pattern in `conscience_mark.dart`.

**`_ThinkingCloudPainter` spec:**
- 7 soft-blurred blobs drawn with `Canvas.drawCircle` + `MaskFilter.blur(BlurStyle.normal, sigma)`
- Color groups (matching _GalaxyBackgroundPainter's red/blue/gold scheme — devil, angel, conscia):
  - 2 × red/orange (`0xFFFF5A4A`, `0xFFE64020`) — devil
  - 2 × cyan/blue (`0xFF67D9FF`, `0xFF50A0F0`) — angel
  - 2 × amber/gold (`0xFFFFD45E`, `0xFFFFB432`) — conscia
  - 1 × soft white (`0xFFDCE1FF`) — diffuse mix
- Each blob has an independent `baseOffset`, `driftAmplitude`, `xFrequency`, `yFrequency`, and `phase` — all hardcoded constants
- Position at time `t`: `x = base.x + sin(t × xFreq + phase) × amp.x`, `y = base.y + cos(t × yFreq + phase × 1.3) × amp.y`
- Opacity and radius also oscillate with small amplitude on independent phases
- Clip region: `Path` ellipse whose `rx`/`ry` breathe gently (`sin(t × 0.4) × 0.015 × width`), rotated slightly (`sin(t × 0.15) × 0.12 rad`) — creates the irregular silhouette
- No center core, no rings, no orbiting elements
- `AnimationController` runs 0→1, `duration: 6s`, `repeat()`; painter receives `animation.value * 2π` as `t`
- Widget size: `220 × 220`

### Insight Slideshow

A `PageView` of 3 fixed insight cards that auto-advances every 2 seconds while the AI call is in flight. Cards show pre-computed context that is already fetched before `_submit()` fires:

| Slide | Content | Data source |
|-------|---------|-------------|
| 1 | Category budget impact: current spend vs limit, projected if purchase goes through | `response.budget` prefetch or `BudgetContextCard` data |
| 2 | Monthly overview: total spent vs monthly budget, remaining after purchase | `dashboardInsightSummaryProvider` |
| 3 | Regret pattern: how many recent purchases in this category ended up in regrets | Local transaction history |

If a data source is unavailable, that slide is skipped (minimum 1 slide shown; fallback to a single "weighing both sides..." text card).

Slide indicator dots below the `PageView`. Thin shimmer progress bar at the very bottom of the screen (2dp height, `deepNavy → navySoft → amber → deepNavy` gradient, animated `background-position`).

### AppBar during loading
Keep the existing `AppBar(title: Text('Conscience Check'))` — remove the large headline text and the sprite-brawl Stack entirely. The caption "Reviewing your [amount] [description] decision..." moves to a `bodySmall/mutedInk` subtitle directly above the cloud widget.

---

## Screen 3 — Verdict

### Goal
Conversational bubble layout replacing the stacked card layout, with CTAs extracted to a sticky footer so they're never obscured.

### Layout

```
AppBar: "The verdict"
─────────────────────────────
[devil sprite]  [devil bubble]       ← left-aligned chat row
        [angel bubble] [angel sprite] ← right-aligned chat row
[Conscia card — full width]
[BudgetContextCard — if available]
─────────────────────────────
[Buy it ✓]  [Wait 24h]  [Skip]       ← sticky footer
─────────────────────────────
[nav bar]
```

### Chat Bubble Rows

Each row is a `Row` with `CrossAxisAlignment.end`:
- `_VerdictBubble(tone: devil/angel, message: ..., animation: ...)` — handles its own bubble styling
- `MascotSpriteFrame` avatar (circular clipped, `radius: 24`, `frame: '1_neutral.png'` for both — neutral pose suits conversation)

Devil bubble: `devilSoft` bg, `devilAccent` border/name color, `border-bottom-left-radius: 4`
Angel bubble: `angelSoft` bg, `angelAccent` border/name color, `border-bottom-right-radius: 4`
Bubble max width: `MediaQuery.of(context).size.width * 0.62`

### Conscia Take Card

Same `amberSoft` / `amber` styling as current. Changes:
- Header row: `ConscienceBrandIcon(size: 24)` (the SVG app icon) + "Conscia's take" title — replaces the `'*'` text
- **Remove** the 3 CTA buttons from inside the card
- Keep the `advice-chip` (`Personal advice` / `Family advice`)
- Keep the message text

### Sticky CTA Footer

Move to `HeroScreenScaffold(bottom: ...)`:
```dart
bottom: Row(children: [
  Expanded(child: FilledButton(onPressed: onBuy, child: Text('Buy it'))),
  SizedBox(width: 8),
  Expanded(child: OutlinedButton(onPressed: onWait, child: Text('Wait 24h'))),
  SizedBox(width: 8),
  Expanded(child: OutlinedButton(onPressed: onSkip, child: Text('Skip'))),
])
```

### Entrance animations

Keep existing `FadeTransition` controllers (`_devilAnim`, `_angelAnim`, `_neutralAnim`) but apply them to the bubble rows instead of the old card containers.

---

## Architecture

### New widgets / files

| Widget | File | Notes |
|--------|------|-------|
| `ThinkingCloudWidget` | `lib/widgets/thinking_cloud.dart` | New file — standalone, no providers |
| `_ThinkingCloudPainter` | same file | Private to `thinking_cloud.dart` |
| `_AssistantHeroBleed` | `pre_purchase_screen.dart` | Private widget, replaces the old hero card |
| `_VerdictBubble` | `pre_purchase_screen.dart` | Private widget, replaces `_VerdictCard` |

### Modified files

| File | Change |
|------|--------|
| `pre_purchase_screen.dart` | Rebuild `_buildInputForm`, `_buildLoading`, `_buildResponse`, `_ConsciaTakeCard` |
| `hero_screen_scaffold.dart` | Fix nested-Scaffold bottom inset so CTAs clear the shell nav |

### No new dependencies

The galaxy cloud uses `CustomPainter` — no Flame, no new packages.

---

## Out of scope

- Slide 2 and 3 data fetching wiring (prefetch logic for monthly overview and regret pattern) — placeholder slide shown if data unavailable
- Voice input, location assistance, smart suggestions — unchanged
- Dark mode — existing tokens handle it automatically
