# Web Screenshot Storytelling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the simulated homepage app visuals with real emulator screenshots presented in polished device-frame compositions, while keeping the approved system-first story, app-like atmosphere, icon asset swap, and production store links.

**Architecture:** Keep the existing Astro homepage structure, but swap the hand-built screen components for screenshot-driven media components. Treat the approved mockup as the source of truth for section rhythm and story shape, keep the wordmark structure intact, and preserve the shared metadata/store-link work already landed on the branch.

**Tech Stack:** Astro, Tailwind utility classes in `web/src/styles/global.css`, static image assets under `web/public/images`, Node test runner (`node:test`)

---

## File Structure

**Create**
- `web/public/images/marketing/hero-transactions.png`
- `web/public/images/marketing/hero-budgets.png`
- `web/public/images/marketing/hero-assistant.png`
- `web/public/images/marketing/hero-insights.png`
- `web/public/images/marketing/section-transactions.png`
- `web/public/images/marketing/section-assistant.png`
- `web/public/images/marketing/section-budgets.png`
- `web/public/images/marketing/section-insights.png`
- `web/public/images/marketing/section-household.png`
  - Copies of the chosen emulator screenshots with stable marketing filenames.
- `web/src/components/marketing/DeviceShot.astro`
  - Reusable framed screenshot component.
- `web/src/components/marketing/HeroShots.astro`
  - Layered hero screenshot collage matching the approved mockup.

**Modify**
- `web/src/components/Hero.astro`
  - Replace `HeroPhone` usage with `HeroShots` and tune copy/button layout to the mockup.
- `web/src/components/marketing/StoryChapter.astro`
  - Render a screenshot-based media composition instead of the old `StoryScene` simulation.
- `web/src/components/Footer.astro`
  - Optionally add screenshot-aware CTA composition only if needed for the approved mockup shape.
- `web/src/pages/index.astro`
  - Keep section order aligned to the approved story, adjust composition if the screenshot-driven layout needs it.
- `web/src/data/marketingChapters.js`
  - Replace `screenId`-driven entries with screenshot asset references and mockup-aligned copy.
- `web/src/styles/global.css`
  - Add screenshot frame styles, hero collage positioning, and section panel treatments.
- `web/src/layouts/Layout.astro`
  - Keep icon metadata aligned if any minimal title/description edits are needed for the final story wording.
- `web/tests/marketing-page.test.mjs`
  - Update assertions so they fit the mockup-driven copy and still verify the production links/icon surfaces.

**Likely obsolete after this pass**
- `web/src/components/marketing/HeroPhone.astro`
- `web/src/components/marketing/StoryScene.astro`
- `web/src/components/screens/AssistantScreen.astro`
- `web/src/components/screens/BudgetsScreen.astro`
- `web/src/components/screens/HouseholdScreen.astro`
- `web/src/components/screens/InsightsScreen.astro`
- `web/src/components/screens/JourneyScreen.astro`
- `web/src/components/screens/ReflectScreen.astro`
- `web/src/components/screens/TransactionsScreen.astro`
  - Remove only if no longer referenced after the screenshot migration.

**Screenshot source inventory**
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537741.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537744.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537757.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537760.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537772.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537787.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537798.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537801.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537819.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537829.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537839.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537843.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537849.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537854.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537860.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537871.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537876.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537885.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537889.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537902.png`
- `c:/Users/nearl/OneDrive/Pictures/Emulator Screenshots/Screenshot_1779537911.png`

---

### Task 1: Stabilize The Story Copy And Test Around The Approved Mockup

**Files:**
- Modify: `web/src/data/marketingChapters.js`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/layouts/Layout.astro`
- Modify: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Write the failing homepage test for the mockup-led story copy**

Update `web/tests/marketing-page.test.mjs` so it expects the approved storytelling phrasing:

```js
test('homepage follows the approved all-in-one money system story', () => {
  assert.match(html, /Your all-in-one money system\./);
  assert.match(html, /Track spending, reflect on purchases, manage budgets, scan receipts/i);
  assert.match(html, /Transactions that tell your story\./);
  assert.match(html, /Pause\. Reflect\. Decide with clarity\./);
  assert.match(html, /Budgets that keep you in control\./);
  assert.match(html, /Money is better together\./);
});
```

- [ ] **Step 2: Run the build and test to verify the current copy still fails**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- test FAIL on one or more new copy assertions

- [ ] **Step 3: Rewrite the homepage copy/data to the approved story**

Update `web/src/data/marketingChapters.js` to use mockup-led story text and screenshot asset refs:

```js
export const heroContent = {
  kicker: 'Finance wellness, made simple',
  title: 'Your all-in-one money system.',
  body:
    'Track spending, reflect on purchases, manage budgets, scan receipts, surface patterns, and coordinate shared household planning — all in one calm place.',
  ctaPrimary: 'Get Conscia',
  ctaSecondary: 'See how it works',
};

export const storyChapters = [
  {
    id: 'transactions-and-filters',
    kicker: 'Track every moment',
    title: 'Transactions that tell your story.',
    body:
      'Capture every expense in seconds. Filter by time or category, and see your money moments in context.',
    bullets: [
      'Smart filters surface what matters fast',
      'Categories keep your records readable',
      'Realtime totals reveal your spending trail',
    ],
    image: '/images/marketing/section-transactions.png',
    imageAlt: 'Conscia transactions screen with spending trail, date filter, and category chips',
  },
  // remaining sections...
];
```

If the final story wording needs a tiny fit adjustment in `Layout.astro` metadata, keep it aligned:

```astro
title = 'Conscia — Your all-in-one money system.'
description = 'Track spending, reflect on purchases, manage budgets, scan receipts, surface patterns, and coordinate shared household planning in one calm place.'
```

- [ ] **Step 4: Run the build and test to verify the story copy now passes**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- updated copy assertions PASS, while image/composition work is still unaffected

- [ ] **Step 5: Commit the story-copy update**

```bash
git add web/src/data/marketingChapters.js web/src/components/Hero.astro web/src/layouts/Layout.astro web/tests/marketing-page.test.mjs
git commit -m "feat(web): align homepage story to approved mockup"
```

### Task 2: Create Stable Marketing Screenshot Assets

**Files:**
- Create: `web/public/images/marketing/hero-transactions.png`
- Create: `web/public/images/marketing/hero-budgets.png`
- Create: `web/public/images/marketing/hero-assistant.png`
- Create: `web/public/images/marketing/hero-insights.png`
- Create: `web/public/images/marketing/section-transactions.png`
- Create: `web/public/images/marketing/section-assistant.png`
- Create: `web/public/images/marketing/section-budgets.png`
- Create: `web/public/images/marketing/section-insights.png`
- Create: `web/public/images/marketing/section-household.png`

- [ ] **Step 1: Choose the screenshot-to-section mapping and document it inline**

Use these source files as the canonical mapping:

```text
hero-transactions      <- Screenshot_1779537798.png
hero-budgets           <- Screenshot_1779537860.png
hero-assistant         <- Screenshot_1779537829.png
hero-insights          <- Screenshot_1779537911.png
section-transactions   <- Screenshot_1779537798.png
section-assistant      <- Screenshot_1779537829.png
section-budgets        <- Screenshot_1779537860.png
section-insights       <- Screenshot_1779537911.png
section-household      <- Screenshot_1779537902.png
```

- [ ] **Step 2: Copy the selected screenshots into stable marketing filenames**

Run:

```powershell
New-Item -ItemType Directory -Force web\public\images\marketing | Out-Null
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537798.png" "web\public\images\marketing\hero-transactions.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537860.png" "web\public\images\marketing\hero-budgets.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537829.png" "web\public\images\marketing\hero-assistant.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537911.png" "web\public\images\marketing\hero-insights.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537798.png" "web\public\images\marketing\section-transactions.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537829.png" "web\public\images\marketing\section-assistant.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537860.png" "web\public\images\marketing\section-budgets.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537911.png" "web\public\images\marketing\section-insights.png" -Force
Copy-Item "c:\Users\nearl\OneDrive\Pictures\Emulator Screenshots\Screenshot_1779537902.png" "web\public\images\marketing\section-household.png" -Force
```

- [ ] **Step 3: Verify the copied marketing assets exist**

Run:

```powershell
Get-ChildItem web\public\images\marketing | Select-Object Name,Length
```

Expected: all nine stable filenames appear

- [ ] **Step 4: Run the build to verify the new static assets don’t break site generation**

Run: `npm --prefix web run build`

Expected: PASS

- [ ] **Step 5: Commit the screenshot asset intake**

```bash
git add web/public/images/marketing
git commit -m "feat(web): add marketing screenshot asset set"
```

### Task 3: Replace Hero Simulation With Screenshot Collage

**Files:**
- Create: `web/src/components/marketing/DeviceShot.astro`
- Create: `web/src/components/marketing/HeroShots.astro`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/styles/global.css`

- [ ] **Step 1: Write the failing test for hero composition content**

Add a light test to ensure the hero now references the mockup-led CTA rhythm:

```js
test('homepage hero includes the approved CTA rhythm', () => {
  assert.match(html, /Get Conscia/);
  assert.match(html, /See how it works/);
  assert.match(html, /Record every money moment/i);
});
```

- [ ] **Step 2: Run build and test to verify the current hero still fails that expectation**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- test FAIL on the new hero CTA/supporting-copy assertion

- [ ] **Step 3: Create reusable screenshot frame components and swap the hero media**

Create `web/src/components/marketing/DeviceShot.astro`:

```astro
---
interface Props {
  src: string;
  alt: string;
  widthClass?: string;
  class?: string;
}

const {
  src,
  alt,
  widthClass = 'w-[220px]',
  class: className = '',
} = Astro.props;
---

<div class:list={['device-shot', widthClass, className]}>
  <div class="device-shot-frame">
    <img src={src} alt={alt} class="device-shot-image" loading="eager" />
  </div>
</div>
```

Create `web/src/components/marketing/HeroShots.astro` using the stable hero assets:

```astro
---
import DeviceShot from './DeviceShot.astro';
---

<div class="hero-shots">
  <DeviceShot
    src="/images/marketing/hero-budgets.png"
    alt="Conscia budgets screen"
    widthClass="w-[170px]"
    class="hero-shot hero-shot-left"
  />
  <DeviceShot
    src="/images/marketing/hero-transactions.png"
    alt="Conscia transactions screen"
    widthClass="w-[210px]"
    class="hero-shot hero-shot-center"
  />
  <DeviceShot
    src="/images/marketing/hero-assistant.png"
    alt="Conscia purchase assistant screen"
    widthClass="w-[170px]"
    class="hero-shot hero-shot-right"
  />
</div>
```

Update `web/src/components/Hero.astro` to use `HeroShots` instead of `HeroPhone`, and align CTA copy to the approved mockup.

- [ ] **Step 4: Run the build and test to verify the hero conversion passes**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- hero CTA/content test PASS

- [ ] **Step 5: Commit the hero screenshot collage**

```bash
git add web/src/components/marketing/DeviceShot.astro web/src/components/marketing/HeroShots.astro web/src/components/Hero.astro web/src/styles/global.css web/tests/marketing-page.test.mjs
git commit -m "feat(web): replace hero simulation with screenshot collage"
```

### Task 4: Replace Section Simulations With Screenshot Story Blocks

**Files:**
- Modify: `web/src/components/marketing/StoryChapter.astro`
- Modify: `web/src/data/marketingChapters.js`
- Modify: `web/src/styles/global.css`
- Delete: `web/src/components/marketing/StoryScene.astro`
- Delete: `web/src/components/marketing/HeroPhone.astro`
- Delete: `web/src/components/screens/AssistantScreen.astro`
- Delete: `web/src/components/screens/BudgetsScreen.astro`
- Delete: `web/src/components/screens/HouseholdScreen.astro`
- Delete: `web/src/components/screens/InsightsScreen.astro`
- Delete: `web/src/components/screens/JourneyScreen.astro`
- Delete: `web/src/components/screens/ReflectScreen.astro`
- Delete: `web/src/components/screens/TransactionsScreen.astro`

- [ ] **Step 1: Write the failing test for the mockup-led section story**

Update the section assertions in `web/tests/marketing-page.test.mjs`:

```js
test('homepage presents the approved section story blocks', () => {
  assert.match(html, /Transactions that tell your story\./);
  assert.match(html, /Pause\. Reflect\. Decide with clarity\./);
  assert.match(html, /Budgets that keep you in control\./);
  assert.match(html, /Patterns > reactions\./);
  assert.match(html, /Money is better together\./);
});
```

- [ ] **Step 2: Run build and test to verify the current section copy/layout still fails**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- test FAIL on at least one section story assertion

- [ ] **Step 3: Swap `StoryChapter` to screenshot media and remove dead simulation files**

Update `web/src/components/marketing/StoryChapter.astro` to render `DeviceShot` from chapter data:

```astro
---
import DeviceShot from './DeviceShot.astro';

const { chapter, reverse = false } = Astro.props;
---

<section id={chapter.id} class="py-24 md:py-32">
  <div class="section-shell">
    <div class:list={['chapter-grid', reverse && 'chapter-grid-reverse']}>
      <div class="story-shot-shell">
        <DeviceShot src={chapter.image} alt={chapter.imageAlt} widthClass="w-[220px]" />
      </div>
      <div>
        <span class="section-kicker">{chapter.kicker}</span>
        <h2 class="section-heading mt-6">{chapter.title}</h2>
        <p class="section-copy mt-6">{chapter.body}</p>
        <ul class="mt-8 grid gap-4 text-sm leading-7 text-[var(--ink-muted)] md:grid-cols-3">
          {chapter.bullets.map((item) => (
            <li class="flex items-start gap-3">
              <span class="mt-2 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--gold)]"></span>
              <span>{item}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  </div>
</section>
```

Then delete the now-unused simulation files listed above once no imports remain.

- [ ] **Step 4: Run build and test to verify the screenshot-driven sections pass**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- section story assertions PASS

- [ ] **Step 5: Commit the section screenshot migration**

```bash
git add web/src/components/marketing/StoryChapter.astro web/src/data/marketingChapters.js web/src/styles/global.css web/tests/marketing-page.test.mjs
git rm web/src/components/marketing/StoryScene.astro web/src/components/marketing/HeroPhone.astro web/src/components/screens/AssistantScreen.astro web/src/components/screens/BudgetsScreen.astro web/src/components/screens/HouseholdScreen.astro web/src/components/screens/InsightsScreen.astro web/src/components/screens/JourneyScreen.astro web/src/components/screens/ReflectScreen.astro web/src/components/screens/TransactionsScreen.astro
git commit -m "feat(web): replace simulated sections with screenshot story blocks"
```

### Task 5: Final Visual Cleanup And Verification

**Files:**
- Modify: `web/src/components/Footer.astro` (only if the lower CTA composition needs final polish)
- Modify: `web/src/styles/global.css`
- Modify: `web/tests/marketing-page.test.mjs` (only if tiny wording adjustments are needed)

- [ ] **Step 1: Run the final verification set**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected:
- build PASS
- marketing test PASS

- [ ] **Step 2: Inspect the worktree and confirm only intended changes remain**

Run: `git status -sb`

Expected:
- web files from this pass
- already-existing app icon worktree changes outside the web scope

- [ ] **Step 3: Make only minimal last-mile polish if needed**

If one final adjustment is needed, keep it small and tied to the approved mockup:

```css
.story-shot-shell {
  min-height: 320px;
  border-radius: 32px;
  background: linear-gradient(180deg, rgba(255,255,255,0.8) 0%, rgba(255,248,223,0.82) 100%);
}
```

Or, if a final wording fit is needed:

```js
assert.match(html, /Your all-in-one money system\./);
assert.match(html, /Money is better together\./);
```

- [ ] **Step 4: Re-run the final verification after any tiny adjustment**

Run:
- `npm --prefix web run build`
- `node --test web/tests/marketing-page.test.mjs`

Expected: PASS / PASS

- [ ] **Step 5: Commit the final screenshot-driven polish**

```bash
git add web/src/components/Footer.astro web/src/styles/global.css web/tests/marketing-page.test.mjs
git commit -m "test(web): verify screenshot-driven homepage story"
```

---

## Self-Review

### Spec coverage
- Mockup story treated as source of truth: Task 1.
- Real screenshots replace simulated UI: Tasks 2, 3, and 4.
- Device-frame compositions like the mockup: Tasks 3 and 4.
- Icon asset swap and store links preserved: maintained through Tasks 1 and 5.
- Lockup structure unchanged: no tasks modify `LogoWithText` or `Logo`.
- App-like atmosphere retained: Tasks 3, 4, and 5.

### Placeholder scan
- No `TODO`, `TBD`, or vague “implement later” language remains.
- Every task contains real file paths, commands, and concrete code/examples.

### Type consistency
- `storyChapters` moves from `screenId` to `image` and `imageAlt`, and later tasks use those same property names.
- Shared verification commands consistently use `npm --prefix web run build` and `node --test web/tests/marketing-page.test.mjs`.
