# Marketing Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mascot-led Conscia marketing page with an app-screenshot-driven design that mirrors the app's Journey atmosphere, and add a `/account-deletion` page for Google Play.

**Architecture:** Swap mascot scene components for simulated app-screen components (`screens/`). A new `HeroPhone.astro` replaces `HeroBattleScene.astro`. `StoryScene.astro` is rewritten to render a phone frame around the appropriate screen component based on a `screenId` string from the chapter data. `HowItWorks.astro` is rewritten as a 3-step horizontal grid. All mascot files, utilities, and CSS are deleted.

**Tech Stack:** Astro 4, Tailwind CSS 3, static output, Node.js `--test` runner for marketing page integration tests.

---

## Working directory

All paths are relative to `web/`. Run all commands from `web/`.

---

## Task 1: Update marketing-page.test.mjs for the new design

Update the integration test so it encodes the new design. The tests run against `dist/index.html` (built output), so they will **fail** until the build is updated in later tasks — that failure is expected and intentional.

**Files:**
- Modify: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Replace the test file content**

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../dist/index.html', import.meta.url), 'utf8');

test('homepage uses the new Journey-tone headline and store-style platform badges', () => {
  assert.match(html, /Your money has a story/);
  assert.match(html, /Personal finance/);
  assert.match(html, /aria-label="Open on iOS"/);
  assert.match(html, /aria-label="Open on Android"/);
  assert.match(html, /Download on the/);
  assert.match(html, /App Store/);
  assert.match(html, /Get it on/);
  assert.match(html, /Google Play/);
  assert.doesNotMatch(html, /Your financial conscience/);
  assert.doesNotMatch(html, /Meet the inner voices/);
});

test('homepage renders the three redesigned chapters in order', () => {
  assert.match(html, /Log the moment/);
  assert.match(html, /Reflect without shame/);
  assert.match(html, /See the patterns/);
  assert.doesNotMatch(html, /Catch the moment/);
  assert.doesNotMatch(html, /Build better habits/);
});

test('homepage includes How it works section', () => {
  assert.match(html, /How it works/);
  assert.match(html, /Pause before you spend/);
  assert.match(html, /Log every moment/);
  assert.match(html, /Reflect and notice/);
});

test('homepage contains no mascot references', () => {
  assert.doesNotMatch(html, /aria-label="Devil mascot"/);
  assert.doesNotMatch(html, /aria-label="Angel mascot"/);
  assert.doesNotMatch(html, /aria-label="Receipt mascot"/);
  assert.doesNotMatch(html, /mascot-sprite/);
  assert.doesNotMatch(html, /hero-battle-scene/);
});

test('footer uses dark navy design with tagline', () => {
  assert.match(html, /Small choices, big freedom/);
  assert.match(html, /\/privacy/);
  assert.match(html, /\/terms/);
});
```

- [ ] **Step 2: Confirm the tests currently fail (expected — dist is still old)**

```bash
npm run build && node --test tests/marketing-page.test.mjs
```

Expected: tests 1–5 FAIL with assertion errors about missing/present strings. If `dist/` doesn't exist yet, `npm run build` will create it with the old code first.

---

## Task 2: Update copy and data in marketingChapters.js

Replace the `heroContent` and `storyChapters` exports. The `scene` prop (mascot data) is replaced with `screenId` (a string the new `StoryScene` will use to pick the right screen component).

**Files:**
- Modify: `web/src/data/marketingChapters.js`

- [ ] **Step 1: Replace the file**

```js
export const heroContent = {
  kicker: 'Personal finance · reimagined',
  title: 'Your money has a story. Start reading it.',
  body:
    'Conscia helps you pause before a purchase, log every moment, and reflect on what your spending is actually telling you. One calm app. A steadier relationship with money.',
};

export const storyChapters = [
  {
    id: 'log-the-moment',
    kicker: 'Log the moment',
    title: 'Every spend captured before the emotion fades.',
    body:
      'Conscia keeps transaction logging fast and thoughtful. Smart category memory, receipt scanning, and voice input keep the experience moving — without turning it into a spreadsheet.',
    bullets: [
      'Fast transaction entry with smart defaults',
      'Scan a receipt and Conscia fills in the rest',
      'Filter by time, category, or sentiment',
    ],
    screenId: 'transactions',
  },
  {
    id: 'reflect-without-shame',
    kicker: 'Reflect without shame',
    title: 'Was it worth it? A small question that changes everything.',
    body:
      'Conscia nudges you to reflect on recent purchases — not to judge, but to notice. Over time the pattern becomes clear: what you regret, what you value, what you want to do differently.',
    bullets: [
      'Quick reflection prompts on recent purchases',
      'Regret memory that builds real signal over time',
      'Journey streak for building consistency',
    ],
    screenId: 'reflect',
  },
  {
    id: 'see-the-patterns',
    kicker: 'See the patterns',
    title: 'Your spending has a signal. Conscia helps you read it.',
    body:
      'Insights go beyond "you overspent." Conscia connects regret, hesitation, and repeated choices into patterns you can actually act on — and budgets that keep you in range.',
    bullets: [
      'Regret rate by category and merchant',
      'Budget pace tracking with calming language',
      'Milestone badges for building habits',
    ],
    screenId: 'insights',
  },
];
```

- [ ] **Step 2: Confirm Astro can still parse the file (no build errors)**

```bash
npm run build 2>&1 | head -20
```

Expected: build succeeds. The old mascot-using components still run but will look broken visually — that's fine; they'll be replaced in later tasks.

- [ ] **Step 3: Commit**

```bash
git add src/data/marketingChapters.js tests/marketing-page.test.mjs
git commit -m "refactor(web): update marketing copy and chapter data for Journey redesign"
```

---

## Task 3: Add phone-frame CSS utilities to global.css

Add the reusable phone shell and screen styles. Also remove the mascot/battle-scene CSS blocks that are about to become dead code.

**Files:**
- Modify: `web/src/styles/global.css`

- [ ] **Step 1: Remove the mascot and battle-scene blocks**

Delete these sections from `global.css` (search for each class name and delete the full rule block including any associated `@keyframes`):

Remove these rules:
- `.hero-battle-scene { … }`
- `.hero-scene-stage, .story-scene-stage { … }`
- `.hero-devil { … }`
- `.hero-money { … }`
- `.hero-angel { … }`
- `.hero-loop-devil { … }`, `.hero-loop-money { … }`, `.hero-loop-angel { … }`
- `@keyframes devilFloat { … }`, `@keyframes moneyPulse { … }`, `@keyframes angelFloat { … }`
- `.chapter-cloud { … }`, `.chapter-cloud-balanced { … }`
- `.mascot-frame { … }`, `.mascot-sprite { … }`
- `.scene-devil { … }`, `.scene-money { … }`, `.scene-angel { … }`
- `.story-scene-card { … }`, `.story-scene-card-left { … }`
- The responsive overrides that reference `.hero-scene-stage`, `.story-scene-stage`, `.hero-devil`, `.hero-money`, `.hero-angel`, `.story-scene-right-card`, `.story-scene-left-card`
- `.chapter-cloud-warm { … }`, `.chapter-cloud-soft { … }`, `.chapter-cloud-cool { … }`

Also update `.story-scene` — change its `min-height` to `auto` and remove the hardcoded backgrounds (the phone renders its own background):

```css
.story-scene {
  position: relative;
  border-radius: 34px;
  border: 1px solid rgba(23, 36, 79, 0.08);
  background: rgba(255, 255, 255, 0.82);
  box-shadow: var(--shadow-soft);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 28px 20px;
}
```

- [ ] **Step 2: Add phone frame utility classes**

Append to the end of `global.css` (before the last `@media` block if any, otherwise at the end):

```css
/* ── Phone frame shells ── */
.phone-outer {
  background: #1a2550;
  border-radius: 34px;
  padding: 8px;
  box-shadow:
    0 40px 80px rgba(23, 36, 79, 0.28),
    inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  position: relative;
}

.phone-outer::before {
  content: '';
  position: absolute;
  top: 12px;
  left: 50%;
  transform: translateX(-50%);
  width: 72px;
  height: 8px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 99px;
  z-index: 5;
}

.phone-inner {
  border-radius: 27px;
  overflow: hidden;
  position: relative;
}

/* phone-outer size variants */
.phone-outer-hero {
  width: 260px;
}

.phone-outer-chapter {
  width: 220px;
}

/* Floating ambient cards for hero section */
.phone-float {
  position: absolute;
  background: rgba(255, 255, 255, 0.96);
  border-radius: 16px;
  padding: 10px 14px;
  box-shadow: 0 12px 30px rgba(23, 36, 79, 0.12);
  border: 1px solid rgba(23, 36, 79, 0.07);
  white-space: nowrap;
  z-index: 10;
}

.phone-float-top-right {
  top: 56px;
  right: -52px;
}

.phone-float-bottom-right {
  bottom: 90px;
  right: -48px;
}

/* Screen background gradients */
.screen-journey {
  background: linear-gradient(175deg, #f7f2ea 0%, #fffdf7 40%, #f8f5ff 100%);
}

.screen-transactions {
  background: linear-gradient(175deg, #f0f5ff 0%, #ffffff 35%);
}

.screen-reflect {
  background: linear-gradient(175deg, #f7f2ea 0%, #fffdf7 55%);
}

.screen-insights {
  background: linear-gradient(175deg, #f0f5ff 0%, #ffffff 40%);
}
```

- [ ] **Step 3: Verify build still passes**

```bash
npm run build 2>&1 | tail -5
```

Expected: `…built in Xms` with no errors.

- [ ] **Step 4: Commit**

```bash
git add src/styles/global.css
git commit -m "style(web): replace mascot CSS with phone-frame utilities"
```

---

## Task 4: Create the four simulated app screen components

These are Astro components that render scaled-down versions of the real app screens. They receive no props — the data is hardcoded to match the story-demo data from the spec.

**Files:**
- Create: `web/src/components/screens/JourneyScreen.astro`
- Create: `web/src/components/screens/TransactionsScreen.astro`
- Create: `web/src/components/screens/ReflectScreen.astro`
- Create: `web/src/components/screens/InsightsScreen.astro`

- [ ] **Step 1: Create JourneyScreen.astro**

```astro
---
---

<div class="screen-journey p-5 pt-9" style="min-height: 480px;">
  <p class="text-[9px] text-[var(--ink-muted)]">Welcome back</p>
  <p class="text-[11px] font-extrabold text-[var(--navy)] mb-4">story-demo</p>

  <h2 class="font-heading text-[22px] font-extrabold leading-none text-[var(--navy)]">Journey</h2>
  <p class="text-[9px] text-[var(--ink-muted)] mb-4">Small choices, big freedom.</p>

  <p class="text-[7px] font-bold uppercase tracking-[1.5px] text-[var(--gold)] mb-1">Momentum</p>
  <p class="text-[11px] font-extrabold text-[var(--navy)] mb-1">🔥 7 day streak</p>
  <p class="text-[8px] text-[var(--ink-muted)] mb-4">2 more days to strengthen your stride.</p>

  <div class="rounded-[12px] bg-[var(--navy)] p-3 mb-4">
    <p class="text-[6px] font-bold uppercase tracking-[1.5px] text-white/50 mb-1">Next Step</p>
    <p class="text-[10px] font-extrabold text-white mb-1">Reflect on 3 purchases</p>
    <p class="text-[7px] text-white/50">2 min · Turn recent decisions into useful signal.</p>
  </div>

  <p class="text-[10px] font-extrabold text-[var(--navy)] mb-1">This Week</p>
  <p class="text-[7px] text-[var(--ink-muted)] mb-3">A gentle arc for building consistency.</p>

  <div class="flex gap-2">
    <div class="flex-1 rounded-[9px] border border-[rgba(23,36,79,0.07)] bg-white p-2 shadow-[var(--shadow-soft)]">
      <p class="text-[14px] mb-1">📋</p>
      <p class="text-[7px] font-extrabold text-[var(--navy)]">Reflect</p>
      <p class="text-[6px] text-[var(--ink-muted)] leading-tight">Turn decisions into signal.</p>
    </div>
    <div class="flex-1 rounded-[9px] border border-[rgba(23,36,79,0.07)] bg-white p-2 shadow-[var(--shadow-soft)]">
      <p class="text-[14px] mb-1">⏸️</p>
      <p class="text-[7px] font-extrabold text-[var(--navy)]">Hold a pause</p>
      <p class="text-[6px] text-[var(--ink-muted)] leading-tight">Check before spending.</p>
    </div>
    <div class="flex-1 rounded-[9px] border border-[rgba(23,36,79,0.07)] bg-white p-2 shadow-[var(--shadow-soft)]">
      <p class="text-[14px] mb-1">🔍</p>
      <p class="text-[7px] font-extrabold text-[var(--navy)]">Review</p>
      <p class="text-[6px] text-[var(--ink-muted)] leading-tight">Spot patterns.</p>
    </div>
  </div>
</div>
```

- [ ] **Step 2: Create TransactionsScreen.astro**

```astro
---
---

<div class="screen-transactions p-4 pt-8" style="min-height: 420px;">
  <p class="text-[11px] font-extrabold text-[var(--navy)] text-center mb-4">Transactions</p>

  <p class="text-[7px] font-bold uppercase tracking-[1.5px] text-[var(--gold)] mb-1">Spending Trail</p>
  <p class="font-heading text-[20px] font-extrabold text-[var(--navy)] mb-3">₱51,615.00</p>

  <div class="flex items-center gap-2 rounded-[8px] bg-[rgba(23,36,79,0.05)] px-2 py-1.5 mb-3">
    <span class="text-[9px] text-[var(--ink-muted)]">⚙</span>
    <span class="text-[8px] text-[var(--ink-muted)]">Any time</span>
  </div>

  <div class="flex flex-wrap gap-1.5 mb-4">
    <span class="chip-gold text-[7px]">Bills</span>
    <span class="chip-angel text-[7px]">Dining</span>
    <span class="chip-gold text-[7px]">Gift</span>
  </div>

  <p class="text-[8px] font-semibold text-[var(--ink-muted)] mb-1.5">Today · May 23</p>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-[8px] bg-pink-100 text-[11px]">🏥</span>
    <div class="flex-1 min-w-0">
      <p class="text-[8px] font-bold text-[var(--navy)] truncate">Asian Hospital</p>
      <p class="text-[7px] text-[var(--ink-muted)]">Health</p>
    </div>
    <p class="text-[8px] font-extrabold text-red-600 shrink-0">-₱5,000</p>
  </div>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-[8px] bg-blue-100 text-[11px]">✈️</span>
    <div class="flex-1 min-w-0">
      <p class="text-[8px] font-bold text-[var(--navy)] truncate">Disneyland</p>
      <p class="text-[7px] text-[var(--ink-muted)]">Travel</p>
    </div>
    <p class="text-[8px] font-extrabold text-red-600 shrink-0">-₱30,000</p>
  </div>

  <p class="text-[8px] font-semibold text-[var(--ink-muted)] mb-1.5 mt-2">Yesterday · May 22</p>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-[8px] bg-red-100 text-[11px]">📋</span>
    <div class="flex-1 min-w-0">
      <p class="text-[8px] font-bold text-[var(--navy)] truncate">Wildflour</p>
      <p class="text-[7px] text-[var(--ink-muted)]">Bills</p>
    </div>
    <p class="text-[8px] font-extrabold text-red-600 shrink-0">-₱3,000</p>
  </div>

  <p class="text-[8px] font-semibold text-[var(--ink-muted)] mb-1.5 mt-2">Tue · May 19</p>

  <div class="flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-[8px] bg-green-100 text-[11px]">🏦</span>
    <div class="flex-1 min-w-0">
      <p class="text-[8px] font-bold text-[var(--navy)] truncate">Freelance Client</p>
      <p class="text-[7px] text-[var(--ink-muted)]">Salary</p>
    </div>
    <p class="text-[8px] font-extrabold text-green-600 shrink-0">+₱3,500</p>
  </div>
</div>
```

- [ ] **Step 3: Create ReflectScreen.astro**

```astro
---
---

<div class="screen-reflect p-4 pt-8" style="min-height: 420px;">
  <p class="text-[11px] font-extrabold text-[var(--navy)] mb-4">Reflect</p>

  <div class="rounded-[14px] border border-[rgba(23,36,79,0.07)] bg-white p-3 shadow-[var(--shadow-soft)] mb-4">
    <div class="flex items-start justify-between mb-1">
      <p class="text-[10px] font-extrabold text-[var(--navy)]">Asian Hospital</p>
      <p class="text-[10px] font-extrabold text-red-600">PHP5,000.00</p>
    </div>
    <p class="text-[7px] text-[var(--ink-muted)] mb-3">10h ago</p>

    <p class="text-[11px] font-extrabold text-[var(--navy)] mb-1">Was it worth it?</p>
    <p class="text-[7px] text-[var(--ink-muted)] leading-relaxed mb-3">
      Notice what this moment gave you before you decide how it felt.
    </p>

    <div class="flex gap-1.5">
      <div class="flex-1 rounded-[9px] bg-green-50 p-2 text-center">
        <p class="text-[10px]">👍</p>
        <p class="text-[7px] font-bold text-green-700">Worth It</p>
      </div>
      <div class="flex-1 rounded-[9px] bg-amber-50 p-2 text-center">
        <p class="text-[10px]">❓</p>
        <p class="text-[7px] font-bold text-amber-700">Not Sure</p>
      </div>
      <div class="flex-1 rounded-[9px] bg-red-50 p-2 text-center">
        <p class="text-[10px]">👎</p>
        <p class="text-[7px] font-bold text-red-700">Regret</p>
      </div>
    </div>
  </div>

  <p class="text-[9px] font-extrabold text-[var(--navy)] mb-2">Recent transactions</p>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-[7px] bg-pink-100 text-[10px]">🏥</span>
    <div class="flex-1 min-w-0">
      <p class="text-[7px] font-bold text-[var(--navy)]">Asian Hospital</p>
      <p class="text-[6px] text-[var(--ink-muted)]">Health</p>
    </div>
    <p class="text-[7px] font-extrabold text-red-600">-₱5,000</p>
  </div>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-[7px] bg-blue-100 text-[10px]">✈️</span>
    <div class="flex-1 min-w-0">
      <p class="text-[7px] font-bold text-[var(--navy)]">Disneyland</p>
      <p class="text-[6px] text-[var(--ink-muted)]">Travel</p>
    </div>
    <p class="text-[7px] font-extrabold text-red-600">-₱30,000</p>
  </div>

  <div class="flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-[7px] bg-yellow-100 text-[10px]">☕</span>
    <div class="flex-1 min-w-0">
      <p class="text-[7px] font-bold text-[var(--navy)]">Starbucks</p>
      <p class="text-[6px] text-[var(--ink-muted)]">Dining</p>
    </div>
    <p class="text-[7px] font-extrabold text-red-600">-₱280</p>
  </div>
</div>
```

- [ ] **Step 4: Create InsightsScreen.astro**

```astro
---
---

<div class="screen-insights p-4 pt-8" style="min-height: 420px;">
  <p class="text-[11px] font-extrabold text-[var(--navy)] text-center mb-4">Insights</p>

  <p class="text-[7px] font-bold uppercase tracking-[1.5px] text-[var(--gold)] mb-1">Regret Signal</p>
  <p class="font-heading text-[20px] font-extrabold text-[var(--navy)] mb-1">₱1,890.00</p>
  <p class="text-[8px] text-[var(--ink-muted)] mb-4">Shopping is carrying your strongest regret signal right now.</p>

  <div class="rounded-[12px] bg-[rgba(23,36,79,0.04)] p-3 mb-3">
    <p class="text-[7px] font-extrabold uppercase tracking-[1px] text-[var(--navy)] mb-2">Your Regret Pulse</p>
    <p class="text-[8px] font-bold text-[var(--navy)] mb-2">₱1,890 tied to Shopping lately.</p>
    <div class="flex gap-3">
      <div>
        <p class="text-[10px] font-extrabold text-[var(--navy)]">₱1,890</p>
        <p class="text-[6px] text-[var(--ink-muted)]">Regretted</p>
      </div>
      <div>
        <p class="text-[10px] font-extrabold text-[var(--navy)]">33%</p>
        <p class="text-[6px] text-[var(--ink-muted)]">Avg rate</p>
      </div>
      <div>
        <p class="text-[10px] font-extrabold text-[var(--navy)]">4</p>
        <p class="text-[6px] text-[var(--ink-muted)]">Patterns</p>
      </div>
    </div>
  </div>

  <p class="text-[8px] font-extrabold text-[var(--navy)] mb-2">Regret patterns</p>

  <div class="mb-1.5 flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <div class="flex-1 min-w-0">
      <p class="text-[7px] font-bold text-[var(--navy)]">₱1,890 regretted on Shopping</p>
      <p class="text-[6px] text-[var(--ink-muted)]">4 patterns · Tap to see breakdown</p>
    </div>
    <span class="shrink-0 rounded-[6px] bg-amber-100 px-1.5 py-0.5 text-[7px] font-extrabold text-amber-700">33%</span>
  </div>

  <div class="flex items-center gap-2 rounded-[9px] border border-[rgba(23,36,79,0.06)] bg-white p-2">
    <div class="flex-1 min-w-0">
      <p class="text-[7px] font-bold text-[var(--navy)]">Starbucks keeps showing up</p>
      <p class="text-[6px] text-[var(--ink-muted)]">2 of 6 visits later marked regret</p>
    </div>
    <span class="shrink-0 rounded-[6px] bg-amber-100 px-1.5 py-0.5 text-[7px] font-extrabold text-amber-700">33%</span>
  </div>
</div>
```

- [ ] **Step 5: Verify build passes with new components**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add src/components/screens/
git commit -m "feat(web): add simulated app screen components (Journey, Transactions, Reflect, Insights)"
```

---

## Task 5: Create HeroPhone.astro

The hero phone frame: 260px wide, Journey screen inside, two floating ambient cards.

**Files:**
- Create: `web/src/components/marketing/HeroPhone.astro`

- [ ] **Step 1: Create the component**

```astro
---
import JourneyScreen from '../screens/JourneyScreen.astro';
---

<div class="relative">
  <div class="phone-outer phone-outer-hero">
    <div class="phone-inner">
      <JourneyScreen />
    </div>
  </div>

  <!-- Floating: budget percentage -->
  <div class="phone-float phone-float-top-right">
    <p class="text-[8px] text-[var(--ink-muted)] mb-0.5">This month</p>
    <p class="text-[11px] font-extrabold text-[var(--navy)]">62% of budget used</p>
  </div>

  <!-- Floating: Worth It chip -->
  <div class="phone-float phone-float-bottom-right">
    <span class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-[8px] font-bold text-green-700 mb-1">
      Worth It ✓
    </span>
    <p class="text-[9px] font-bold text-[var(--navy)]">Asian Hospital</p>
    <p class="text-[8px] text-[var(--ink-muted)]">₱5,000 · Health</p>
  </div>
</div>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

---

## Task 6: Update Hero.astro

Swap `HeroBattleScene` for `HeroPhone`. Replace the mascot-era kicker/headline/body with the new copy from `heroContent`. Add two CTA buttons.

**Files:**
- Modify: `web/src/components/Hero.astro`

- [ ] **Step 1: Replace the file**

```astro
---
import LogoWithText from './icons/LogoWithText.astro';
import PlatformBadge from './icons/PlatformBadge.astro';
import HeroPhone from './marketing/HeroPhone.astro';
import { heroContent } from '../data/marketingChapters.js';
---

<section
  class="relative pt-6"
  style="background: radial-gradient(ellipse at 10% 30%, rgba(246,203,104,0.22) 0%, transparent 50%), radial-gradient(ellipse at 90% 70%, rgba(123,208,215,0.18) 0%, transparent 45%), linear-gradient(170deg, #f7f2ea 0%, #fffdf7 45%, #f0f5ff 100%);"
>
  <!-- sticky nav -->
  <div class="hero-nav-shell fixed inset-x-0 top-4 z-50">
    <div class="section-shell">
      <nav class="hero-nav glass-card flex items-center justify-between px-5 py-4 md:px-7">
        <LogoWithText size="38" />
        <div class="flex items-center gap-3">
          <PlatformBadge platform="ios" />
          <PlatformBadge platform="android" />
        </div>
      </nav>
    </div>
  </div>

  <!-- hero body -->
  <div class="section-shell relative pb-16 pt-32 md:pb-20 md:pt-40">
    <div class="grid items-center gap-12 lg:grid-cols-2">

      <!-- copy -->
      <div class="relative z-10">
        <span class="section-kicker">{heroContent.kicker}</span>

        <h1 class="mt-7 max-w-2xl font-heading text-5xl font-extrabold leading-[1.04] tracking-[-0.04em] text-[var(--ink-strong)] md:text-6xl lg:text-7xl">
          {heroContent.title}
        </h1>

        <p class="section-copy mt-6 max-w-xl">{heroContent.body}</p>

        <div class="mt-10 flex flex-wrap gap-3">
          <PlatformBadge platform="ios" />
          <PlatformBadge platform="android" />
        </div>
      </div>

      <!-- phone -->
      <div class="flex justify-center lg:justify-end">
        <HeroPhone />
      </div>

    </div>
  </div>
</section>

<script>
  const navShell = document.querySelector('.hero-nav-shell');
  const dockAtTop = () => {
    if (!navShell) return;
    navShell.classList.toggle('is-docked', window.scrollY > 50);
  };

  dockAtTop();
  window.addEventListener('scroll', dockAtTop, { passive: true });
</script>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds with no reference to `HeroBattleScene`.

- [ ] **Step 3: Commit**

```bash
git add src/components/Hero.astro src/components/marketing/HeroPhone.astro
git commit -m "feat(web): replace mascot hero scene with HeroPhone component"
```

---

## Task 7: Rewrite StoryScene.astro as a phone frame wrapper

`StoryScene` now renders a phone frame around the correct screen component based on the `screenId` prop. The `mood`, `devilPose`, `angelPose`, `moneyPose`, `uiBadge`, `cardTitle`, `cardSide` props are all removed.

**Files:**
- Modify: `web/src/components/marketing/StoryScene.astro`

- [ ] **Step 1: Replace the file**

```astro
---
import TransactionsScreen from '../screens/TransactionsScreen.astro';
import ReflectScreen from '../screens/ReflectScreen.astro';
import InsightsScreen from '../screens/InsightsScreen.astro';

interface Props {
  screenId: 'transactions' | 'reflect' | 'insights';
}

const { screenId } = Astro.props;
---

<div class="story-scene">
  <div class="phone-outer phone-outer-chapter">
    <div class="phone-inner">
      {screenId === 'transactions' && <TransactionsScreen />}
      {screenId === 'reflect' && <ReflectScreen />}
      {screenId === 'insights' && <InsightsScreen />}
    </div>
  </div>
</div>
```

- [ ] **Step 2: Update StoryChapter.astro to pass screenId instead of scene spread**

```astro
---
import StoryScene from './StoryScene.astro';

const { chapter, reverse = false } = Astro.props;
---

<section id={chapter.id} class="py-24 md:py-32">
  <div class="section-shell">
    <div class:list={['chapter-grid', reverse && 'chapter-grid-reverse']}>
      <div>
        <span class="section-kicker">{chapter.kicker}</span>
        <h2 class="section-heading mt-6">{chapter.title}</h2>
        <p class="section-copy mt-6">{chapter.body}</p>
        <ul class="mt-8 space-y-4 text-sm leading-7 text-[var(--ink-muted)]">
          {chapter.bullets.map((item) => (
            <li class="flex items-start gap-3">
              <span class="mt-2 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--gold)]"></span>
              <span>{item}</span>
            </li>
          ))}
        </ul>
      </div>

      <StoryScene screenId={chapter.screenId} />
    </div>
  </div>
</section>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/components/marketing/StoryScene.astro src/components/marketing/StoryChapter.astro
git commit -m "feat(web): replace mascot StoryScene with phone frame using screenId"
```

---

## Task 8: Rewrite HowItWorks.astro as a 3-step horizontal grid

**Files:**
- Modify: `web/src/components/HowItWorks.astro`

- [ ] **Step 1: Replace the file**

```astro
---
---

<section class="py-24 md:py-32 bg-white border-t border-[rgba(23,36,79,0.06)]">
  <div class="section-shell">
    <div class="mx-auto max-w-3xl text-center mb-14">
      <span class="section-kicker">How it works</span>
      <h2 class="section-heading mt-6">Three moments. One loop.</h2>
      <p class="section-copy mt-6">
        Most finance apps start after the money is already gone. Conscia is built around the
        moments that actually matter — before, during, and after each decision.
      </p>
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
      <article class="feature-panel relative">
        <div class="mb-5 inline-flex h-10 w-10 items-center justify-center rounded-[12px] bg-[var(--navy)] text-base font-extrabold text-white">
          1
        </div>
        <h3 class="text-xl font-extrabold tracking-tight text-[var(--ink-strong)]">
          Pause before you spend
        </h3>
        <p class="mt-4 text-sm leading-7 text-[var(--ink-muted)]">
          The pre-purchase assistant weighs your budget context and recent patterns so you can
          decide with more clarity — not just impulse.
        </p>
      </article>

      <article class="feature-panel relative">
        <div class="mb-5 inline-flex h-10 w-10 items-center justify-center rounded-[12px] bg-[var(--gold)] text-base font-extrabold text-[var(--navy)]">
          2
        </div>
        <h3 class="text-xl font-extrabold tracking-tight text-[var(--ink-strong)]">
          Log every moment
        </h3>
        <p class="mt-4 text-sm leading-7 text-[var(--ink-muted)]">
          Fast transaction entry, receipt scanning, and smart category memory keep the friction
          low so nothing disappears into the void.
        </p>
      </article>

      <article class="feature-panel relative">
        <div class="mb-5 inline-flex h-10 w-10 items-center justify-center rounded-[12px] bg-[var(--teal)] text-base font-extrabold text-[var(--navy)]">
          3
        </div>
        <h3 class="text-xl font-extrabold tracking-tight text-[var(--ink-strong)]">
          Reflect and notice
        </h3>
        <p class="mt-4 text-sm leading-7 text-[var(--ink-muted)]">
          Reflection prompts, regret tracking, and pattern signals turn your spending history
          into something you can actually learn from.
        </p>
      </article>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add src/components/HowItWorks.astro
git commit -m "feat(web): rewrite HowItWorks as 3-step horizontal grid"
```

---

## Task 9: Update index.astro — chapter order + HowItWorks

**Files:**
- Modify: `web/src/pages/index.astro`

- [ ] **Step 1: Replace the file**

```astro
---
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
import HowItWorks from '../components/HowItWorks.astro';
import StoryChapter from '../components/marketing/StoryChapter.astro';
import Footer from '../components/Footer.astro';
import { storyChapters } from '../data/marketingChapters.js';
---

<Layout>
  <Hero />
  <HowItWorks />
  <StoryChapter chapter={storyChapters[0]} />
  <StoryChapter chapter={storyChapters[1]} reverse={true} />
  <StoryChapter chapter={storyChapters[2]} />
  <Footer />
</Layout>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/pages/index.astro
git commit -m "feat(web): update index — HowItWorks strip + correct chapter order"
```

---

## Task 10: Rewrite Footer.astro

Replace the glass-card CTA footer with the dark navy design: logo, tagline, nav links left; store badges right. Keep `feedback@getconscia.com` in the footer nav.

**Files:**
- Modify: `web/src/components/Footer.astro`

- [ ] **Step 1: Replace the file**

```astro
---
import LogoWithText from './icons/LogoWithText.astro';
import PlatformBadge from './icons/PlatformBadge.astro';
---

<footer class="bg-[var(--navy)] px-6 py-14">
  <div class="section-shell">
    <div class="flex flex-col gap-10 lg:flex-row lg:items-start lg:justify-between">

      <div>
        <LogoWithText size="36" textClass="text-white" />
        <p class="mt-3 text-sm text-white/50">Small choices, big freedom.</p>
        <nav class="mt-6 flex flex-wrap gap-5 text-sm font-medium text-white/40">
          <a href="/privacy" class="transition hover:text-white/70">Privacy</a>
          <a href="/terms" class="transition hover:text-white/70">Terms</a>
          <a href="/account-deletion" class="transition hover:text-white/70">Account deletion</a>
          <a href="mailto:hello@getconscia.com" class="transition hover:text-white/70">Contact</a>
        </nav>
      </div>

      <div class="flex flex-col gap-3 sm:flex-row lg:flex-col">
        <PlatformBadge platform="ios" />
        <PlatformBadge platform="android" />
      </div>

    </div>
  </div>
</footer>
```

- [ ] **Step 2: Verify logo is visible on dark footer**

```bash
npm run build && npm run preview
```

Open `http://localhost:4321` and scroll to the footer. If the logo is invisible, open `src/components/icons/LogoWithText.astro` and check how color is applied, then adjust accordingly (e.g., add a `class` prop that's forwarded to the SVG).

- [ ] **Step 3: Commit**

```bash
git add src/components/Footer.astro
git commit -m "feat(web): redesign footer to dark navy with store badges"
```

---

## Task 11: Update Layout.astro default title and description

**Files:**
- Modify: `web/src/layouts/Layout.astro`

- [ ] **Step 1: Update the destructured defaults only**

Change lines 10–13 from:
```ts
const {
  title = 'Conscia — A devil, an angel, and your next spending decision',
  description = 'Conscia explains impulse, reason, reflection, budgets, and better habits through one playful financial conscience.',
} = Astro.props;
```

To:
```ts
const {
  title = 'Conscia — Your money has a story. Start reading it.',
  description = 'Conscia helps you pause before a purchase, log every moment, and reflect on what your spending is actually telling you. One calm app. A steadier relationship with money.',
} = Astro.props;
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add src/layouts/Layout.astro
git commit -m "chore(web): update default page title and description"
```

---

## Task 12: Delete mascot files and update package.json

**Files:**
- Delete: `web/src/components/marketing/HeroBattleScene.astro`
- Delete: `web/src/components/mascots/MascotSprite.astro`
- Delete: `web/src/utils/mascotFrames.js`
- Delete: `web/src/data/mascots/angel.json`
- Delete: `web/src/data/mascots/devil.json`
- Delete: `web/src/data/mascots/money.json`
- Delete: `web/tests/mascot-frames.test.mjs`
- Modify: `web/package.json` — remove `test:marketing:frames` script

- [ ] **Step 1: Delete the files**

```bash
rm src/components/marketing/HeroBattleScene.astro
rm src/components/mascots/MascotSprite.astro
rm src/utils/mascotFrames.js
rm src/data/mascots/angel.json
rm src/data/mascots/devil.json
rm src/data/mascots/money.json
rmdir src/components/mascots
rmdir src/data/mascots
rm tests/mascot-frames.test.mjs
```

- [ ] **Step 2: Remove the test script from package.json**

In `web/package.json`, remove the line:
```json
"test:marketing:frames": "node --test tests/mascot-frames.test.mjs",
```

- [ ] **Step 3: Verify build still passes with no dangling imports**

```bash
npm run build 2>&1 | tail -10
```

Expected: build succeeds with no "Cannot find module" or "Unknown file extension" errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(web): delete all mascot files, utilities, and mascot test"
```

---

## Task 13: Create account-deletion.astro

**Files:**
- Create: `web/src/pages/account-deletion.astro`

- [ ] **Step 1: Create the page**

```astro
---
import Layout from '../layouts/Layout.astro';
import Footer from '../components/Footer.astro';
import Logo from '../components/icons/Logo.astro';
---

<Layout
  title="Account Deletion — Conscia"
  description="How to delete your Conscia account and what data is removed."
>
  <header class="bg-[var(--navy)] py-6">
    <div class="mx-auto flex max-w-7xl items-center gap-3 px-6">
      <a href="/" class="flex items-center gap-3 transition hover:opacity-80">
        <Logo size="32" />
        <span class="font-heading text-xl font-bold text-white">Conscia</span>
      </a>
    </div>
  </header>

  <main class="mx-auto max-w-3xl px-6 py-16">
    <h1 class="font-heading text-4xl font-bold text-[var(--navy)]">Account Deletion</h1>
    <p class="mt-2 text-sm text-gray-500">Conscia · getconscia.com</p>

    <div class="mt-10 space-y-10 text-gray-700 leading-relaxed">

      <section>
        <h2 class="font-heading text-xl font-semibold text-gray-900">How to delete your account</h2>
        <p class="mt-3">
          Account deletion is available directly inside the Conscia app. Follow these steps:
        </p>
        <ol class="mt-4 list-decimal space-y-2 pl-6">
          <li>Open <strong>Conscia</strong> on your device.</li>
          <li>Tap the <strong>Settings</strong> icon in the bottom navigation bar (rightmost icon).</li>
          <li>Scroll down to the <strong>Data &amp; privacy</strong> section.</li>
          <li>Tap <strong>Delete account</strong>.</li>
          <li>Read the confirmation message, then tap <strong>Delete account</strong> again to confirm.</li>
        </ol>
        <p class="mt-4">
          Deletion is <strong>permanent and immediate</strong>. There is no waiting period or grace period after confirmation.
        </p>
      </section>

      <section>
        <h2 class="font-heading text-xl font-semibold text-gray-900">What gets deleted</h2>
        <p class="mt-3">When you confirm deletion, the following data is permanently removed from Conscia's servers:</p>
        <ul class="mt-3 list-disc space-y-2 pl-6">
          <li><strong>Account credentials and profile data</strong> — your display name, email address, and authentication records.</li>
          <li><strong>All transactions and receipts</strong> — every transaction you have logged, including any scanned receipt images.</li>
          <li><strong>Budget configurations</strong> — all budget categories, caps, and history.</li>
          <li><strong>AI interaction history</strong> — all pre-purchase advisor queries and responses.</li>
          <li><strong>Reflection and regret data</strong> — all reflection responses, regret markers, and pattern signals.</li>
        </ul>
      </section>

      <section>
        <h2 class="font-heading text-xl font-semibold text-gray-900">Data retention</h2>
        <p class="mt-3">
          <strong>None.</strong> All data listed above is deleted immediately and permanently upon confirmation.
          No personal data is retained after account deletion.
        </p>
        <p class="mt-3">
          Anonymised, non-identifiable aggregate statistics (e.g. total registered user counts) may persist
          in our analytics systems but cannot be linked back to your account.
        </p>
      </section>

      <section>
        <h2 class="font-heading text-xl font-semibold text-gray-900">Export your data first</h2>
        <p class="mt-3">
          Before deleting your account, you can export a full JSON copy of your Conscia history:
        </p>
        <ol class="mt-3 list-decimal space-y-2 pl-6">
          <li>Open <strong>Settings</strong> in the Conscia app.</li>
          <li>Scroll to <strong>Data &amp; privacy</strong>.</li>
          <li>Tap <strong>Download my data</strong>.</li>
        </ol>
      </section>

      <section>
        <h2 class="font-heading text-xl font-semibold text-gray-900">Questions</h2>
        <p class="mt-3">
          If you are unable to access the app or need further help, contact us at
          <a href="mailto:privacy@getconscia.com" class="font-semibold text-[var(--navy)] underline hover:opacity-80">
            privacy@getconscia.com
          </a>.
        </p>
      </section>

    </div>
  </main>

  <Footer />
</Layout>
```

- [ ] **Step 2: Verify build and check the page renders**

```bash
npm run build && npm run preview
```

Open `http://localhost:4321/account-deletion` and confirm:
- Page loads with the correct title
- All 5 steps for deletion are visible
- All 5 data types are listed
- "Permanent and immediate" retention statement is present
- Export instructions are present

- [ ] **Step 3: Commit**

```bash
git add src/pages/account-deletion.astro
git commit -m "feat(web): add /account-deletion page for Google Play data safety requirement"
```

---

## Task 14: Run full test suite and verify all success criteria

- [ ] **Step 1: Run the marketing page integration tests**

```bash
npm run build && node --test tests/marketing-page.test.mjs
```

Expected output: all 5 tests PASS.

If a test fails, read the assertion message, locate the string in `dist/index.html`, and fix the component or copy that produced it.

- [ ] **Step 2: Manual smoke check**

```bash
npm run preview
```

Open `http://localhost:4321` and verify each success criterion from the spec:

| Check | Where to look |
|-------|--------------|
| No mascots anywhere | Scroll entire page — no devil/angel/money characters |
| Hero: Journey phone + 2 floating cards | Hero section, right column |
| "How it works" 3-step grid | Section immediately below hero |
| Chapter 1: Transactions screen | First chapter |
| Chapter 2: Reflect screen (reversed) | Second chapter — phone on left |
| Chapter 3: Insights screen | Third chapter |
| Dark navy footer with badges | Page bottom |
| `/account-deletion` page | `http://localhost:4321/account-deletion` |
| `/privacy` and `/terms` unchanged | Quick scan |

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "test(web): all marketing page integration tests passing after redesign"
```
