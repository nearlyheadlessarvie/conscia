# Web System Atmosphere Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reframe the marketing homepage around Conscia as an all-in-one money system, tune the web visual system to match the current app atmosphere, and wire the new icon assets and production store links without changing the existing text lockup structure.

**Architecture:** Keep the Astro homepage structure component-based, but replace the current story-led sequence with a broader system-first sequence driven by homepage data and updated marketing components. Leave the nav/footer wordmark pattern intact, update only icon asset surfaces and shared metadata, and keep verification centered on the existing static marketing test plus a fresh production build.

**Tech Stack:** Astro, Tailwind utility classes in `web/src/styles/global.css`, static component composition, Node test runner (`node:test`)

---

## File Structure

**Modify**
- `web/src/pages/index.astro`
  - Restage the homepage composition around the new system-first sections.
- `web/src/components/Hero.astro`
  - Rewrite hero copy, update badge targets, and shift product imagery direction.
- `web/src/components/HowItWorks.astro`
  - Convert the section away from the old “three moments” framing into system-level orientation or replace it with broader product structure.
- `web/src/components/marketing/StoryChapter.astro`
  - Reuse or retune the alternating section shell for the new system-first sections.
- `web/src/components/marketing/HeroPhone.astro`
  - Refresh the hero mock to reflect the current app more closely.
- `web/src/components/screens/TransactionsScreen.astro`
- `web/src/components/screens/ReflectScreen.astro`
- `web/src/components/screens/InsightsScreen.astro`
- `web/src/components/screens/JourneyScreen.astro`
  - Update existing screens that still appear in homepage imagery.
- `web/src/components/Footer.astro`
  - Point store badges at production URLs while keeping the lockup structure intact.
- `web/src/components/icons/PlatformBadge.astro`
  - Centralize production App Store / Google Play URLs.
- `web/src/data/marketingChapters.js`
  - Replace story-led content with system-first section data.
- `web/src/layouts/Layout.astro`
  - Swap favicon / OG / Twitter image surfaces to the new icon assets.
- `web/src/styles/global.css`
  - Tune the shared landing palette, surfaces, gradients, and component feel to match the app screenshots.
- `web/tests/marketing-page.test.mjs`
  - Update assertions to reflect the new hero copy, section order, store links, and footer expectations.

**Check during implementation**
- `web/src/components/icons/Logo.astro`
- `web/src/components/icons/LogoWithText.astro`
  - Confirm these stay structurally unchanged unless icon-asset-only surfaces require source updates.

**Inputs from current app icon worktree**
- `app/assets/images/app_icon.png`
- `app/assets/images/app_icon.svg`
- `app/assets/images/app_icon_ios.png`
  - Use the intended icon assets on the web without restructuring the wordmark components.

---

### Task 1: Wire Shared Metadata And Production Store Links

**Files:**
- Modify: `web/src/layouts/Layout.astro`
- Modify: `web/src/components/icons/PlatformBadge.astro`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/components/Footer.astro`
- Test: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Write the failing test for production store links and icon metadata**

Add or replace assertions in `web/tests/marketing-page.test.mjs` so the test expects the new positioning surfaces:

```js
test('homepage metadata and badges use production icon and store links', () => {
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6771674327/);
  assert.match(html, /https:\/\/play\.google\.com\/store\/apps\/details\?id=com\.getconscia\.app\.ai/);
  assert.match(html, /rel="icon" type="image\/svg\+xml" href="\/images\/app_icon\.svg"/);
  assert.match(html, /rel="icon" type="image\/png" href="\/images\/app_icon\.png"/);
  assert.match(html, /property="og:image" content="\/images\/app_icon\.png"/);
});
```

- [ ] **Step 2: Run the marketing test to verify it fails before the link swap**

Run: `npm --prefix web test -- marketing-page.test.mjs`

Expected: FAIL because the homepage still reflects older copy and may not yet guarantee the production badge targets in a single assertion set.

- [ ] **Step 3: Update the shared metadata and badge link source**

Set production links in `web/src/components/icons/PlatformBadge.astro` so every badge surface shares one source of truth:

```astro
---
const urls = {
  ios: 'https://apps.apple.com/app/id6771674327',
  android: 'https://play.google.com/store/apps/details?id=com.getconscia.app.ai',
};

const isIos = platform === 'ios';
const href = isIos ? urls.ios : urls.android;
---
```

Keep `Layout.astro` on the new icon asset surfaces:

```astro
<meta property="og:image" content="/images/app_icon.png" />
<meta name="twitter:image" content="/images/app_icon.png" />
<link rel="icon" type="image/svg+xml" href="/images/app_icon.svg" />
<link rel="icon" type="image/png" href="/images/app_icon.png" />
```

- [ ] **Step 4: Run the marketing test to verify the metadata/link assertions pass**

Run: `npm --prefix web test -- marketing-page.test.mjs`

Expected: the new metadata / badge-link assertions pass, while later content assertions may still fail until the homepage rewrite lands.

- [ ] **Step 5: Commit the shared metadata and store-link change**

```bash
git add web/src/layouts/Layout.astro web/src/components/icons/PlatformBadge.astro web/src/components/Hero.astro web/src/components/Footer.astro web/tests/marketing-page.test.mjs
git commit -m "feat(web): wire production store links and icon metadata"
```

### Task 2: Rewrite Homepage Information Architecture Around The Full Money System

**Files:**
- Modify: `web/src/pages/index.astro`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/components/HowItWorks.astro`
- Modify: `web/src/data/marketingChapters.js`
- Test: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Write the failing content test for the new hero and section order**

Update the homepage content expectations so they reflect the approved system-first direction:

```js
test('homepage leads with the all-in-one money system message', () => {
  assert.match(html, /all-in-one money system/i);
  assert.match(html, /track spending/i);
  assert.match(html, /manage budgets/i);
  assert.match(html, /scan receipts/i);
  assert.match(html, /shared household/i);
  assert.doesNotMatch(html, /Your money has a story/);
});

test('homepage presents system sections in the new order', () => {
  assert.match(html, /Transactions and filters/);
  assert.match(html, /Reflection and purchase assistant/);
  assert.match(html, /Budgets and categories/);
  assert.match(html, /Insights and merchant signals/);
  assert.match(html, /Shared household and settings/);
});
```

- [ ] **Step 2: Run the marketing test to verify it fails on old homepage messaging**

Run: `npm --prefix web test -- marketing-page.test.mjs`

Expected: FAIL because the homepage still says “Your money has a story” and uses the older chapter framing.

- [ ] **Step 3: Replace the story-led data and restage the homepage composition**

Rewrite `web/src/data/marketingChapters.js` to describe the broader system:

```js
export const heroContent = {
  kicker: 'All-in-one money system',
  title: 'One calm place for your whole money system.',
  body:
    'Track spending, reflect on purchases, manage budgets, scan receipts, surface patterns, and coordinate household planning without stitching five tools together.',
};

export const storyChapters = [
  {
    id: 'transactions-and-filters',
    kicker: 'Transactions and filters',
    title: 'See the trail, not just the total.',
    body:
      'Conscia keeps transactions readable with calm summaries, date filters, category rails, and context that makes repeat moments easier to notice.',
    bullets: [
      'Date-aware filtering and category rails',
      'Grouped moments with reflection cues',
      'Personal and family records in one system',
    ],
    screenId: 'transactions',
  },
  // additional approved sections...
];
```

Restage `web/src/pages/index.astro` around the new sequence:

```astro
<Layout>
  <Hero />
  <HowItWorks />
  <StoryChapter chapter={storyChapters[0]} />
  <StoryChapter chapter={storyChapters[1]} reverse={true} />
  <StoryChapter chapter={storyChapters[2]} />
  <StoryChapter chapter={storyChapters[3]} reverse={true} />
  <StoryChapter chapter={storyChapters[4]} />
  <Footer />
</Layout>
```

Refresh `Hero.astro` headline/body so the hero becomes system-first instead of journey-first.

- [ ] **Step 4: Run the marketing test to verify the new homepage structure passes**

Run: `npm --prefix web test -- marketing-page.test.mjs`

Expected: Hero/section assertions pass, while any visual-atmosphere-sensitive checks are still unaffected until the next task.

- [ ] **Step 5: Commit the homepage content and structure rewrite**

```bash
git add web/src/pages/index.astro web/src/components/Hero.astro web/src/components/HowItWorks.astro web/src/data/marketingChapters.js web/tests/marketing-page.test.mjs
git commit -m "feat(web): reposition homepage around full money system"
```

### Task 3: Tune The Shared Web Atmosphere To Match The Current App

**Files:**
- Modify: `web/src/styles/global.css`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/components/HowItWorks.astro`
- Modify: `web/src/components/Footer.astro`

- [ ] **Step 1: Write the failing visual-surface expectation in the test file**

Add a lightweight regression that checks for the new section language rather than old phrasing and keeps the footer branding stable:

```js
test('footer keeps the lockup while the homepage atmosphere shifts app-ward', () => {
  assert.match(html, /Small choices, big freedom/);
  assert.doesNotMatch(html, /Meet the inner voices/);
});
```

This is intentionally light because most atmosphere changes are CSS-driven and need build verification rather than brittle string checks.

- [ ] **Step 2: Run the existing web build to capture the current baseline**

Run: `npm --prefix web run build`

Expected: PASS, producing `web/dist/index.html` before the atmosphere tuning.

- [ ] **Step 3: Update the shared landing palette and surface styles**

Tune `web/src/styles/global.css` toward the app palette:

```css
:root {
  --bg-top: #f6f5ff;
  --bg-bottom: #fffbf2;
  --ink-strong: #1b234b;
  --ink-muted: #6a6f8c;
  --navy: #1f2f73;
  --navy-soft: #e9edff;
  --gold: #f6cb68;
  --line: rgba(31, 47, 115, 0.1);
  --shadow-soft: 0 18px 38px rgba(31, 47, 115, 0.08);
}

.landing-body {
  background:
    radial-gradient(circle at 12% 20%, rgba(233, 237, 255, 0.9), transparent 30%),
    radial-gradient(circle at 88% 18%, rgba(246, 203, 104, 0.34), transparent 28%),
    linear-gradient(180deg, var(--bg-top) 0%, #fffdf8 42%, var(--bg-bottom) 100%);
}

.feature-panel,
.mock-card,
.glass-card {
  background: rgba(255, 255, 255, 0.9);
  border-color: rgba(31, 47, 115, 0.08);
}
```

Keep the nav/footer lockup structure intact while letting the shared surfaces feel closer to the screenshots.

- [ ] **Step 4: Run the web build to verify the CSS pass compiles cleanly**

Run: `npm --prefix web run build`

Expected: PASS with no Astro or Tailwind errors.

- [ ] **Step 5: Commit the shared atmosphere tuning**

```bash
git add web/src/styles/global.css web/src/components/Hero.astro web/src/components/HowItWorks.astro web/src/components/Footer.astro
git commit -m "style(web): align landing atmosphere with app surfaces"
```

### Task 4: Refresh Simulated Product Screens To Match The Real App

**Files:**
- Modify: `web/src/components/marketing/HeroPhone.astro`
- Modify: `web/src/components/screens/TransactionsScreen.astro`
- Modify: `web/src/components/screens/ReflectScreen.astro`
- Modify: `web/src/components/screens/InsightsScreen.astro`
- Modify: `web/src/components/screens/JourneyScreen.astro`
- Modify: `web/src/components/marketing/StoryScene.astro`
- Modify: `web/src/components/marketing/StoryChapter.astro`

- [ ] **Step 1: Write the failing content test for the broadened product imagery language**

Replace old chapter expectations in `web/tests/marketing-page.test.mjs` with real-app-facing strings that the updated mocks/copy should expose:

```js
test('homepage references current product surfaces instead of older journey-only framing', () => {
  assert.match(html, /receipt/i);
  assert.match(html, /purchase assistant/i);
  assert.match(html, /shared household/i);
  assert.match(html, /merchant/i);
  assert.doesNotMatch(html, /Three moments\. One loop\./);
});
```

- [ ] **Step 2: Run the marketing test to verify the older mock language still fails**

Run: `npm --prefix web test -- marketing-page.test.mjs`

Expected: FAIL until the screen components and nearby copy are refreshed.

- [ ] **Step 3: Refresh the screen components against the supplied app references**

Retune the simulated screens so they mirror the product screenshots more closely. Example direction for the transactions screen:

```astro
<p class="text-[11px] font-extrabold uppercase tracking-[0.18em] text-[var(--navy)] mb-2">
  Spending trail
</p>
<p class="font-heading text-[20px] font-extrabold text-[var(--navy)] mb-3">₱51,615.00</p>
<div class="rounded-full border border-[rgba(31,47,115,0.08)] bg-[rgba(233,237,255,0.65)] px-4 py-3 text-[var(--navy)]">
  Any time
</div>
```

Use the screenshot set to ground:
- transactions date strip + category rail
- reflection cards and sentiment choices
- receipt scan hero
- purchase assistant
- budgets donut and pacing
- settings / subscription / shared household
- insights and merchant signal views

- [ ] **Step 4: Run the web build and marketing test to verify the revised homepage passes**

Run:
- `npm --prefix web run build`
- `npm --prefix web test -- marketing-page.test.mjs`

Expected:
- build PASS
- test PASS

- [ ] **Step 5: Commit the simulated-screen refresh**

```bash
git add web/src/components/marketing/HeroPhone.astro web/src/components/marketing/StoryScene.astro web/src/components/marketing/StoryChapter.astro web/src/components/screens/TransactionsScreen.astro web/src/components/screens/ReflectScreen.astro web/src/components/screens/InsightsScreen.astro web/src/components/screens/JourneyScreen.astro web/tests/marketing-page.test.mjs
git commit -m "feat(web): refresh marketing screens to match current app"
```

### Task 5: Final Homepage Verification And Cleanup

**Files:**
- Modify: `web/tests/marketing-page.test.mjs` (only if tiny final wording adjustments are still needed)

- [ ] **Step 1: Run the full targeted verification set**

Run:
- `npm --prefix web run build`
- `npm --prefix web test -- marketing-page.test.mjs`

Expected:
- Astro build PASS
- marketing homepage test PASS

- [ ] **Step 2: Inspect the final worktree before the wrap-up commit**

Run: `git status -sb`

Expected: only intended web files plus the already-existing app icon worktree changes should appear.

- [ ] **Step 3: Make only any truly necessary last-mile test text adjustments**

If the test still reflects stale copy, keep the final assertions aligned to the approved direction:

```js
assert.match(html, /all-in-one money system/i);
assert.match(html, /shared household/i);
assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6771674327/);
assert.match(html, /https:\/\/play\.google\.com\/store\/apps\/details\?id=com\.getconscia\.app\.ai/);
```

- [ ] **Step 4: Re-run the targeted verification after any last-mile adjustment**

Run:
- `npm --prefix web run build`
- `npm --prefix web test -- marketing-page.test.mjs`

Expected: PASS / PASS

- [ ] **Step 5: Commit the final verification-aligned polish**

```bash
git add web/tests/marketing-page.test.mjs
git commit -m "test(web): align homepage checks with system-first redesign"
```

---

## Self-Review

### Spec coverage
- Homepage repositioned around full system: covered by Task 2.
- App-like atmosphere tuning: covered by Task 3.
- Updated product imagery from real screenshots: covered by Task 4.
- Icon asset swap without changing lockup structure: covered by Task 1 and guarded in file structure notes.
- Production App Store / Google Play links: covered by Task 1.
- Verification on build and homepage tests: covered by Tasks 1, 3, 4, and 5.

### Placeholder scan
- No `TODO` / `TBD` placeholders remain.
- Every task includes concrete files, commands, expected outcomes, and example code.

### Type consistency
- Store URLs are consistent across tasks.
- Homepage data file remains `web/src/data/marketingChapters.js`.
- Main verification file remains `web/tests/marketing-page.test.mjs`.
