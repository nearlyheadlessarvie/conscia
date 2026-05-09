# Web Mascot Storytelling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the public Astro marketing site into a playful, mascot-led storytelling page that explains the Conscia concept, builds trust, and drives users into the app instead of asking them to sign up on the web.

**Architecture:** Keep Astro and Tailwind, but replace the current product-marketing sections with a chapter-based page made from small reusable components. Use the app icon as the official brand mark, add a single animated mascot hero driven by sprite-atlas metadata, and keep later sections static so the page stays readable and responsive.

**Tech Stack:** Astro 4, Tailwind CSS, Node built-in test runner, static sprite atlases in `web/public/images/mascots/`

---

## File Structure

### Files to create

- `web/src/data/mascots/angel.json`
  - Build-time copy of the angel sprite metadata so Astro components can resolve atlas frames without reaching into `app/`.
- `web/src/data/mascots/devil.json`
  - Build-time copy of the devil sprite metadata.
- `web/src/data/mascots/money.json`
  - Build-time copy of the money sprite metadata.
- `web/src/utils/mascotFrames.js`
  - Small helper that reads atlas JSON and returns frame coordinates, dimensions, and public image URLs.
- `web/src/data/marketingChapters.js`
  - Single source of truth for hero copy, chapter copy, trust bullets, and CTA labels.
- `web/src/components/mascots/MascotSprite.astro`
  - Sprite-atlas renderer that crops one frame from a sprite sheet using CSS background positioning.
- `web/src/components/marketing/HeroBattleScene.astro`
  - The only animated mascot composition on the page.
- `web/src/components/marketing/StoryChapter.astro`
  - Shared two-column chapter section for “Catch the moment,” “Reflect without shame,” and “Build better habits.”
- `web/src/components/marketing/StoryScene.astro`
  - Static chapter scene renderer that stages devil / angel / money / UI cards with mood-specific cloud intensity.
- `web/src/components/marketing/OpenAppCta.astro`
  - Final trust + CTA chapter that points users into the app.
- `web/tests/mascot-frames.test.mjs`
  - Node test for atlas metadata resolution.
- `web/tests/marketing-page.test.mjs`
  - Build-output smoke test for the new chapter narrative and CTA language.

### Files to modify

- `web/package.json`
  - Add marketing test scripts.
- `web/src/components/Hero.astro`
  - Replace the current faux-device hero with the new mascot storytelling hero.
- `web/src/components/Footer.astro`
  - Update footer CTA language so it supports the “open the app” flow rather than web signup.
- `web/src/layouts/Layout.astro`
  - Refresh title/description metadata to match the new narrative.
- `web/src/pages/index.astro`
  - Replace `Features`, `HowItWorks`, `Pricing`, and `Roadmap` ordering with the chapter-based page flow.
- `web/src/styles/global.css`
  - Add chapter layouts, mascot sprite styling, scene cloud utilities, responsive hero animation, and trust-strip styles.

### Files to leave in place but stop using from `index.astro`

- `web/src/components/Features.astro`
- `web/src/components/HowItWorks.astro`
- `web/src/components/Pricing.astro`
- `web/src/components/Roadmap.astro`

These can stay in the repo during the first pass so we do not mix redesign work with a cleanup-only diff.

### Public assets to copy

- From `app/assets/images/sprites/angel/sprite_sheet.png` to `web/public/images/mascots/angel/sprite_sheet.png`
- From `app/assets/images/sprites/devil/sprite_sheet.png` to `web/public/images/mascots/devil/sprite_sheet.png`
- From `app/assets/images/sprites/money/sprite_sheet.png` to `web/public/images/mascots/money/sprite_sheet.png`

---

### Task 1: Set Up Mascot Atlas Data And Build-Time Tests

**Files:**
- Create: `web/src/data/mascots/angel.json`
- Create: `web/src/data/mascots/devil.json`
- Create: `web/src/data/mascots/money.json`
- Create: `web/src/utils/mascotFrames.js`
- Create: `web/tests/mascot-frames.test.mjs`
- Modify: `web/package.json`

- [ ] **Step 1: Write the failing atlas-resolution test**

```js
// web/tests/mascot-frames.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';

import { getMascotFrame } from '../src/utils/mascotFrames.js';

test('resolves devil whisper frame from sprite metadata', () => {
  const frame = getMascotFrame('devil', '8_whisper.png');

  assert.equal(frame.imagePath, '/images/mascots/devil/sprite_sheet.png');
  assert.equal(frame.x, 2508);
  assert.equal(frame.y, 1254);
  assert.equal(frame.width, 1254);
  assert.equal(frame.height, 1254);
});

test('throws for an unknown pose name', () => {
  assert.throws(() => getMascotFrame('angel', '404_missing.png'), /Unknown mascot frame/);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm run test:marketing:frames`

Expected: FAIL with `Cannot find module '../src/utils/mascotFrames.js'` or missing script error.

- [ ] **Step 3: Copy the sprite atlases and implement the metadata helper**

```powershell
New-Item -ItemType Directory -Force web\public\images\mascots\angel | Out-Null
New-Item -ItemType Directory -Force web\public\images\mascots\devil | Out-Null
New-Item -ItemType Directory -Force web\public\images\mascots\money | Out-Null
New-Item -ItemType Directory -Force web\src\data\mascots | Out-Null

Copy-Item app\assets\images\sprites\angel\sprite_sheet.png web\public\images\mascots\angel\sprite_sheet.png
Copy-Item app\assets\images\sprites\devil\sprite_sheet.png web\public\images\mascots\devil\sprite_sheet.png
Copy-Item app\assets\images\sprites\money\sprite_sheet.png web\public\images\mascots\money\sprite_sheet.png

Copy-Item app\assets\images\sprites\angel\sprite_sheet.json web\src\data\mascots\angel.json
Copy-Item app\assets\images\sprites\devil\sprite_sheet.json web\src\data\mascots\devil.json
Copy-Item app\assets\images\sprites\money\sprite_sheet.json web\src\data\mascots\money.json
```

```js
// web/src/utils/mascotFrames.js
import { readFileSync } from 'node:fs';

function loadAtlas(relativePath, imagePath) {
  const file = new URL(relativePath, import.meta.url);
  const atlas = JSON.parse(readFileSync(file, 'utf8'));
  const frameMap = new Map(atlas.sprites.map((sprite) => [sprite.fileName, sprite]));

  return {
    imagePath,
    sheetWidth: atlas.spriteSheetWidth,
    sheetHeight: atlas.spriteSheetHeight,
    frameMap,
  };
}

const atlases = {
  angel: loadAtlas('../data/mascots/angel.json', '/images/mascots/angel/sprite_sheet.png'),
  devil: loadAtlas('../data/mascots/devil.json', '/images/mascots/devil/sprite_sheet.png'),
  money: loadAtlas('../data/mascots/money.json', '/images/mascots/money/sprite_sheet.png'),
};

export function getMascotFrame(kind, fileName) {
  const atlas = atlases[kind];

  if (!atlas) {
    throw new Error(`Unknown mascot atlas: ${kind}`);
  }

  const frame = atlas.frameMap.get(fileName);

  if (!frame) {
    throw new Error(`Unknown mascot frame: ${kind}/${fileName}`);
  }

  return {
    ...frame,
    imagePath: atlas.imagePath,
    sheetWidth: atlas.sheetWidth,
    sheetHeight: atlas.sheetHeight,
  };
}
```

```json
// web/package.json
{
  "name": "conscia-web",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "test:marketing:frames": "node --test tests/mascot-frames.test.mjs"
  },
  "dependencies": {
    "astro": "^4.15.0",
    "@astrojs/tailwind": "^5.1.0",
    "tailwindcss": "^3.4.0"
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm run test:marketing:frames`

Expected: PASS with `2 passed`.

- [ ] **Step 5: Commit**

```bash
git add web/package.json web/public/images/mascots web/src/data/mascots web/src/utils/mascotFrames.js web/tests/mascot-frames.test.mjs
git commit -m "test: add mascot atlas metadata support"
```

### Task 2: Build The Animated Hero And Narrative Data Source

**Files:**
- Create: `web/src/data/marketingChapters.js`
- Create: `web/src/components/mascots/MascotSprite.astro`
- Create: `web/src/components/marketing/HeroBattleScene.astro`
- Create: `web/tests/marketing-page.test.mjs`
- Modify: `web/src/components/Hero.astro`
- Modify: `web/src/styles/global.css`

- [ ] **Step 1: Write the failing homepage smoke test**

```js
// web/tests/marketing-page.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../dist/index.html', import.meta.url), 'utf8');

test('homepage uses the mascot-led storytelling headline and app-first CTA', () => {
  assert.match(html, /Your financial conscience, in full color\./);
  assert.match(html, /Open the app/);
  assert.match(html, /See how it works/);
  assert.match(html, /Meet the inner voices/);
  assert.doesNotMatch(html, /Start with the free plan/);
  assert.doesNotMatch(html, /Join the beta/);
});
```

- [ ] **Step 2: Run the smoke test to verify it fails**

Run: `npm run build && node --test tests/marketing-page.test.mjs`

Expected: FAIL because the current `Hero.astro` still renders `Spend with a little more conscience...` and old pricing CTA language.

- [ ] **Step 3: Add the narrative content source and hero scene components**

```js
// web/src/data/marketingChapters.js
export const heroContent = {
  kicker: 'Meet the inner voices',
  title: 'Your financial conscience, in full color.',
  body:
    'Conscia turns impulse, reason, and reflection into one product flow so people can catch a spending decision before it disappears into a ledger.',
  primaryCta: { label: 'Open the app', href: '#open-the-app' },
  secondaryCta: { label: 'See how it works', href: '#catch-the-moment' },
  proof: [
    'Pre-purchase assistant before a spend',
    'Fast logging when the moment already happened',
    'Reflection and habit-building after the emotion settles',
  ],
};
```

```astro
--- 
// web/src/components/mascots/MascotSprite.astro
import { getMascotFrame } from '../../utils/mascotFrames.js';

const { kind, pose, class: className = '', alt = '' } = Astro.props;
const frame = getMascotFrame(kind, pose);
const style = `
  width:${frame.width}px;
  height:${frame.height}px;
  background-image:url(${frame.imagePath});
  background-position:-${frame.x}px -${frame.y}px;
  background-size:${frame.sheetWidth}px ${frame.sheetHeight}px;
`;
---

<div class={`mascot-sprite ${className}`} style={style} role="img" aria-label={alt}></div>
```

```astro
---
// web/src/components/marketing/HeroBattleScene.astro
import MascotSprite from '../mascots/MascotSprite.astro';
---

<div class="hero-battle-scene" data-scene="hero-battle" aria-hidden="true">
  <div class="chapter-cloud chapter-cloud-balanced"></div>

  <MascotSprite kind="devil" pose="8_whisper.png" class="hero-devil hero-loop-devil" alt="Devil mascot" />
  <MascotSprite kind="money" pose="1_neutral.png" class="hero-money hero-loop-money" alt="Receipt mascot" />
  <MascotSprite kind="angel" pose="8_shield.png" class="hero-angel hero-loop-angel" alt="Angel mascot" />
</div>
```

```astro
---
// web/src/components/Hero.astro
import LogoWithText from './icons/LogoWithText.astro';
import HeroBattleScene from './marketing/HeroBattleScene.astro';
import { heroContent } from '../data/marketingChapters.js';
---

<section class="relative overflow-hidden pt-6">
  <div class="section-shell">
    <nav class="glass-card flex items-center justify-between px-5 py-4 md:px-7">
      <LogoWithText size="38" />
      <div class="hidden items-center gap-7 text-sm font-medium text-[var(--ink-muted)] md:flex">
        <a href="#catch-the-moment" class="transition hover:text-[var(--navy)]">How it works</a>
        <a href="#reflect-without-shame" class="transition hover:text-[var(--navy)]">Reflection</a>
        <a href="#build-better-habits" class="transition hover:text-[var(--navy)]">Habits</a>
      </div>
      <a href="#open-the-app" class="premium-cta-secondary text-sm">Open the app</a>
    </nav>
  </div>

  <div class="section-shell relative py-12 md:py-16 lg:py-20">
    <div class="story-grid items-center gap-14">
      <div class="relative z-10">
        <span class="section-kicker">{heroContent.kicker}</span>
        <h1 class="mt-7 max-w-3xl font-heading text-5xl font-extrabold leading-[1.02] tracking-[-0.04em] text-[var(--ink-strong)] md:text-6xl lg:text-7xl">
          {heroContent.title}
        </h1>
        <p class="section-copy mt-7 max-w-2xl">{heroContent.body}</p>
        <div class="mt-9 flex flex-col gap-4 sm:flex-row">
          <a href={heroContent.primaryCta.href} class="premium-cta-primary">{heroContent.primaryCta.label}</a>
          <a href={heroContent.secondaryCta.href} class="premium-cta-secondary">{heroContent.secondaryCta.label}</a>
        </div>
        <div class="mt-10 grid gap-3 sm:grid-cols-3">
          {heroContent.proof.map((item) => (
            <div class="glass-card px-4 py-4 text-sm leading-6 text-[var(--ink-muted)]">{item}</div>
          ))}
        </div>
      </div>

      <HeroBattleScene />
    </div>
  </div>
</section>
```

```css
/* web/src/styles/global.css */
.chapter-cloud {
  position: absolute;
  inset: 6% 8%;
  border-radius: 40px;
  background:
    radial-gradient(circle at 22% 55%, rgba(165, 47, 40, 0.28), transparent 28%),
    radial-gradient(circle at 50% 26%, rgba(246, 203, 104, 0.26), transparent 26%),
    radial-gradient(circle at 78% 56%, rgba(27, 143, 159, 0.3), transparent 30%);
  filter: blur(12px);
}

.chapter-cloud-balanced {
  background:
    radial-gradient(circle at 22% 55%, rgba(165, 47, 40, 0.34), transparent 30%),
    radial-gradient(circle at 50% 26%, rgba(246, 203, 104, 0.32), transparent 26%),
    radial-gradient(circle at 78% 56%, rgba(27, 143, 159, 0.34), transparent 32%);
}

.mascot-sprite {
  position: absolute;
  background-repeat: no-repeat;
  image-rendering: auto;
  transform-origin: center;
}

.hero-battle-scene {
  position: relative;
  min-height: 520px;
  border-radius: 38px;
  border: 1px solid rgba(23, 36, 79, 0.08);
  background: rgba(255, 255, 255, 0.82);
  box-shadow: var(--shadow-soft);
  overflow: hidden;
}

.hero-devil { left: 7%; bottom: 14%; width: 34%; height: auto; aspect-ratio: 1 / 1; }
.hero-money { left: 35%; bottom: 16%; width: 28%; height: auto; aspect-ratio: 1 / 1; }
.hero-angel { right: 7%; bottom: 15%; width: 34%; height: auto; aspect-ratio: 1 / 1; }

.hero-loop-devil { animation: devilFloat 5.2s ease-in-out infinite; }
.hero-loop-money { animation: moneyPulse 5.2s ease-in-out infinite; }
.hero-loop-angel { animation: angelFloat 5.2s ease-in-out infinite; }

@keyframes devilFloat {
  0%, 100% { transform: translate3d(0, 0, 0) rotate(0deg); }
  40% { transform: translate3d(8px, -8px, 0) rotate(-2deg); }
  70% { transform: translate3d(14px, 2px, 0) rotate(1deg); }
}

@keyframes moneyPulse {
  0%, 100% { transform: translate3d(0, 0, 0) scale(1); }
  45% { transform: translate3d(0, -4px, 0) scale(1.03); }
}

@keyframes angelFloat {
  0%, 100% { transform: translate3d(0, 0, 0) rotate(0deg); }
  40% { transform: translate3d(-10px, -12px, 0) rotate(2deg); }
  70% { transform: translate3d(-16px, 0, 0) rotate(-1deg); }
}
```

- [ ] **Step 4: Run the smoke test to verify it passes**

Run: `npm run build && node --test tests/marketing-page.test.mjs`

Expected: PASS with the new headline, chapter teaser, and `Open the app` CTA visible in `dist/index.html`.

- [ ] **Step 5: Commit**

```bash
git add web/src/data/marketingChapters.js web/src/components/mascots/MascotSprite.astro web/src/components/marketing/HeroBattleScene.astro web/src/components/Hero.astro web/src/styles/global.css web/tests/marketing-page.test.mjs
git commit -m "feat: add mascot-led marketing hero"
```

### Task 3: Replace The Middle Of The Page With Storytelling Chapters

**Files:**
- Create: `web/src/components/marketing/StoryScene.astro`
- Create: `web/src/components/marketing/StoryChapter.astro`
- Modify: `web/src/data/marketingChapters.js`
- Modify: `web/src/pages/index.astro`
- Modify: `web/src/styles/global.css`
- Test: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Extend the failing smoke test with chapter assertions**

```js
// web/tests/marketing-page.test.mjs
test('homepage renders the three storytelling chapters in order', () => {
  assert.match(html, /Catch the moment/);
  assert.match(html, /Reflect without shame/);
  assert.match(html, /Build better habits/);
  assert.match(html, /Pre-purchase assistant/);
  assert.match(html, /Reflection prompts/);
  assert.match(html, /Recurring transactions/);
});
```

- [ ] **Step 2: Run the smoke test to verify it fails**

Run: `npm run build && node --test tests/marketing-page.test.mjs`

Expected: FAIL because `index.astro` still renders `Features`, `HowItWorks`, `Pricing`, and `Roadmap` instead of the new chapters.

- [ ] **Step 3: Add the reusable chapter data and chapter components**

```js
// web/src/data/marketingChapters.js
export const storyChapters = [
  {
    id: 'catch-the-moment',
    kicker: 'Catch the moment',
    title: 'Pre-purchase assistant and fast logging, right when the spend is still live.',
    body:
      'Use Conscia before the tap or immediately after. The product helps while the emotional context still exists instead of waiting for a month-end postmortem.',
    bullets: ['Pre-purchase assistant', 'Fast transaction logging', 'Real-world spending flow'],
    scene: {
      mood: 'warm',
      devilPose: '2_push.png',
      moneyPose: '4_save.png',
      uiBadge: 'Logged in seconds',
      cardTitle: 'Capture the spend',
    },
  },
  {
    id: 'reflect-without-shame',
    kicker: 'Reflect without shame',
    title: 'Reflection prompts that help users notice patterns without turning the app into a guilt machine.',
    body:
      'Conscia remembers hesitation, regret, and repeated second-guessing so users can learn from the moment rather than just archive it.',
    bullets: ['Reflection prompts', 'Regret memory', 'Pattern awareness'],
    scene: {
      mood: 'soft',
      angelPose: '8_shield.png',
      moneyPose: '1_neutral.png',
      uiBadge: 'Reflection + memory',
      cardTitle: 'Notice what happened',
    },
  },
  {
    id: 'build-better-habits',
    kicker: 'Build better habits',
    title: 'Budgets, recurring transactions, and insights that turn one decision into a steadier routine.',
    body:
      'The payoff is not one perfect choice. It is a better pattern: more context, calmer decisions, and stronger habits over time.',
    bullets: ['Budgets', 'Insights', 'Recurring transactions'],
    scene: {
      mood: 'cool',
      angelPose: '9_coinshield.png',
      moneyPose: '4_save.png',
      uiBadge: 'Reflection + budgets',
      cardTitle: 'See the payoff',
    },
  },
];
```

```astro
---
// web/src/components/marketing/StoryScene.astro
import MascotSprite from '../mascots/MascotSprite.astro';

const { mood, devilPose = null, angelPose = null, moneyPose, uiBadge, cardTitle } = Astro.props;
---

<div class={`story-scene story-scene-${mood}`}>
  <div class={`chapter-cloud chapter-cloud-${mood}`}></div>

  {devilPose && <MascotSprite kind="devil" pose={devilPose} class="scene-devil" alt="Devil mascot" />}
  <MascotSprite kind="money" pose={moneyPose} class="scene-money" alt="Receipt mascot" />
  {angelPose && <MascotSprite kind="angel" pose={angelPose} class="scene-angel" alt="Angel mascot" />}

  <div class="story-scene-card">
    <span class="chip-gold">{uiBadge}</span>
    <div class="mt-4 text-lg font-extrabold text-[var(--ink-strong)]">{cardTitle}</div>
    <div class="mt-4 space-y-3">
      <div class="h-3 rounded-full bg-[rgba(78,91,140,0.16)]"></div>
      <div class="h-3 w-4/5 rounded-full bg-[rgba(78,91,140,0.12)]"></div>
      <div class="h-3 w-3/5 rounded-full bg-[rgba(78,91,140,0.12)]"></div>
    </div>
  </div>
</div>
```

```astro
---
// web/src/components/marketing/StoryChapter.astro
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
              <span class="mt-2 h-2.5 w-2.5 rounded-full bg-[var(--gold)]"></span>
              <span>{item}</span>
            </li>
          ))}
        </ul>
      </div>

      <StoryScene {...chapter.scene} />
    </div>
  </div>
</section>
```

```astro
---
// web/src/pages/index.astro
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
import StoryChapter from '../components/marketing/StoryChapter.astro';
import OpenAppCta from '../components/marketing/OpenAppCta.astro';
import Footer from '../components/Footer.astro';
import { storyChapters } from '../data/marketingChapters.js';
---

<Layout>
  <Hero />
  <StoryChapter chapter={storyChapters[0]} />
  <StoryChapter chapter={storyChapters[1]} reverse={true} />
  <StoryChapter chapter={storyChapters[2]} />
  <OpenAppCta />
  <Footer />
</Layout>
```

```css
/* web/src/styles/global.css */
.chapter-grid {
  @apply grid items-center gap-10 lg:grid-cols-[0.95fr,1.05fr];
}

.chapter-grid-reverse {
  @apply lg:grid-cols-[1.05fr,0.95fr];
}

.chapter-grid-reverse > :first-child {
  @apply lg:order-2;
}

.chapter-grid-reverse > :last-child {
  @apply lg:order-1;
}

.story-scene {
  position: relative;
  min-height: 380px;
  border-radius: 34px;
  border: 1px solid rgba(23, 36, 79, 0.08);
  background: rgba(255, 255, 255, 0.82);
  box-shadow: var(--shadow-soft);
  overflow: hidden;
}

.chapter-cloud-warm {
  background:
    radial-gradient(circle at 22% 58%, rgba(165, 47, 40, 0.46), transparent 32%),
    radial-gradient(circle at 50% 26%, rgba(246, 203, 104, 0.34), transparent 28%),
    radial-gradient(circle at 80% 55%, rgba(123, 208, 215, 0.18), transparent 30%);
}

.chapter-cloud-soft {
  background:
    radial-gradient(circle at 24% 58%, rgba(165, 47, 40, 0.22), transparent 30%),
    radial-gradient(circle at 50% 28%, rgba(246, 203, 104, 0.3), transparent 28%),
    radial-gradient(circle at 78% 54%, rgba(123, 208, 215, 0.34), transparent 32%);
}

.chapter-cloud-cool {
  background:
    radial-gradient(circle at 22% 58%, rgba(165, 47, 40, 0.18), transparent 28%),
    radial-gradient(circle at 48% 28%, rgba(246, 203, 104, 0.26), transparent 26%),
    radial-gradient(circle at 78% 54%, rgba(27, 143, 159, 0.44), transparent 34%);
}

.scene-devil { left: 5%; bottom: 4%; width: 34%; aspect-ratio: 1 / 1; }
.scene-money { left: 37%; bottom: 7%; width: 22%; aspect-ratio: 1 / 1; z-index: 3; }
.scene-angel { right: 5%; bottom: 8%; width: 34%; aspect-ratio: 1 / 1; }

.story-scene-card {
  position: absolute;
  top: 8%;
  right: 7%;
  width: min(210px, 42%);
  border-radius: 26px;
  border: 1px solid rgba(23, 36, 79, 0.08);
  background: rgba(255, 255, 255, 0.92);
  padding: 18px;
  box-shadow: var(--shadow-soft);
}
```

- [ ] **Step 4: Run the smoke test to verify it passes**

Run: `npm run build && node --test tests/marketing-page.test.mjs`

Expected: PASS with the three chapter headings rendered in order and no pricing-led copy on the page.

- [ ] **Step 5: Commit**

```bash
git add web/src/data/marketingChapters.js web/src/components/marketing/StoryScene.astro web/src/components/marketing/StoryChapter.astro web/src/pages/index.astro web/src/styles/global.css web/tests/marketing-page.test.mjs
git commit -m "feat: add storytelling chapter sections"
```

### Task 4: Add The Final App CTA, Trust Language, And Responsive Polish

**Files:**
- Create: `web/src/components/marketing/OpenAppCta.astro`
- Modify: `web/src/components/Footer.astro`
- Modify: `web/src/layouts/Layout.astro`
- Modify: `web/src/styles/global.css`
- Test: `web/tests/marketing-page.test.mjs`

- [ ] **Step 1: Extend the smoke test with final CTA and trust assertions**

```js
// web/tests/marketing-page.test.mjs
test('homepage ends with an app-first CTA and trust language', () => {
  assert.match(html, /Open the app/);
  assert.match(html, /iPhone, Android, and web companion surfaces/);
  assert.match(html, /Private by default/);
  assert.match(html, /The app handles onboarding and account creation/);
});
```

- [ ] **Step 2: Run the smoke test to verify it fails**

Run: `npm run build && node --test tests/marketing-page.test.mjs`

Expected: FAIL because the current footer still says `Start with the free plan` and does not contain the new trust copy.

- [ ] **Step 3: Implement the final CTA chapter, metadata refresh, and footer cleanup**

```astro
---
// web/src/components/marketing/OpenAppCta.astro
---

<section id="open-the-app" class="py-24 md:py-32">
  <div class="section-shell">
    <div class="feature-panel overflow-hidden">
      <div class="chapter-cloud chapter-cloud-balanced opacity-80"></div>
      <div class="relative grid gap-8 lg:grid-cols-[1.1fr,0.9fr]">
        <div>
          <span class="section-kicker">Open the app</span>
          <h2 class="section-heading mt-6">Take the conversation into the product.</h2>
          <p class="section-copy mt-6 max-w-2xl">
            Conscia explains itself here, but the real onboarding, personality setup, and account creation live in the app where the spending context actually belongs.
          </p>
          <div class="mt-8 flex flex-col gap-4 sm:flex-row">
            <a href="conscia://open" class="premium-cta-primary">Open the app</a>
            <a href="mailto:hello@getconscia.com" class="premium-cta-secondary">Talk to the team</a>
          </div>
        </div>

        <div class="rounded-[28px] border border-[rgba(23,36,79,0.08)] bg-white/90 p-6 shadow-[var(--shadow-soft)]">
          <div class="text-sm font-semibold uppercase tracking-[0.24em] text-[var(--navy-soft)]">Why the app first</div>
          <ul class="mt-5 space-y-4 text-sm leading-7 text-[var(--ink-muted)]">
            <li class="flex items-start gap-3"><span class="mt-2 h-2.5 w-2.5 rounded-full bg-[var(--angel-deep)]"></span><span>The app handles onboarding and account creation.</span></li>
            <li class="flex items-start gap-3"><span class="mt-2 h-2.5 w-2.5 rounded-full bg-[var(--gold)]"></span><span>iPhone, Android, and web companion surfaces keep the same metaphor.</span></li>
            <li class="flex items-start gap-3"><span class="mt-2 h-2.5 w-2.5 rounded-full bg-[var(--navy)]"></span><span>Private by default, with budgeting context that stays useful over time.</span></li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</section>
```

```astro
---
// web/src/components/Footer.astro
import LogoWithText from './icons/LogoWithText.astro';
---

<footer class="pb-10 pt-8">
  <div class="section-shell">
    <div class="rounded-[36px] border border-[rgba(23,36,79,0.1)] bg-[linear-gradient(145deg,#ffffff_0%,rgba(255,255,255,0.88)_100%)] px-6 py-10 shadow-[var(--shadow-soft)] md:px-10">
      <div class="flex flex-col gap-8 lg:flex-row lg:items-end lg:justify-between">
        <div class="max-w-2xl">
          <span class="section-kicker">Still curious?</span>
          <h2 class="mt-6 font-heading text-4xl font-extrabold tracking-tight text-[var(--ink-strong)] md:text-5xl">
            Conscia is for people who want a little more honesty between the urge and the payment.
          </h2>
        </div>

        <div class="flex flex-col gap-3 sm:flex-row lg:flex-col">
          <a href="#open-the-app" class="premium-cta-primary">Open the app</a>
          <a href="mailto:feedback@getconscia.com" class="premium-cta-secondary">Send feedback</a>
        </div>
      </div>

      <div class="mt-10 border-t border-[rgba(23,36,79,0.08)] pt-6">
        <div class="flex flex-col gap-5 md:flex-row md:items-center md:justify-between">
          <LogoWithText size="34" />
          <nav class="flex flex-wrap gap-5 text-sm font-medium text-[var(--ink-muted)]">
            <a href="/privacy" class="transition hover:text-[var(--navy)]">Privacy</a>
            <a href="/terms" class="transition hover:text-[var(--navy)]">Terms</a>
            <a href="mailto:hello@getconscia.com" class="transition hover:text-[var(--navy)]">Contact</a>
          </nav>
        </div>
      </div>
    </div>
  </div>
</footer>
```

```astro
---
// web/src/layouts/Layout.astro
import '../styles/global.css';

interface Props {
  title?: string;
  description?: string;
}

const {
  title = 'Conscia — A devil, an angel, and your next spending decision',
  description = 'Conscia explains impulse, reason, reflection, budgets, and better habits through one playful financial conscience.',
} = Astro.props;
---
```

```css
/* web/src/styles/global.css */
@media (max-width: 1024px) {
  .hero-battle-scene {
    min-height: 420px;
  }

  .story-scene {
    min-height: 340px;
  }

  .story-scene-card {
    width: min(220px, 48%);
  }
}

@media (max-width: 640px) {
  .hero-battle-scene,
  .story-scene {
    min-height: 280px;
  }

  .hero-devil,
  .hero-angel,
  .scene-devil,
  .scene-angel {
    width: 38%;
  }

  .hero-money,
  .scene-money {
    width: 26%;
  }

  .story-scene-card {
    top: 6%;
    right: 5%;
    width: 46%;
    padding: 14px;
  }
}
```

- [ ] **Step 4: Run full verification**

Run: `npm run build && npm run test:marketing:frames && node --test tests/marketing-page.test.mjs`

Expected:
- `astro build` completes successfully
- atlas metadata tests pass
- marketing page smoke test passes

- [ ] **Step 5: Commit**

```bash
git add web/src/components/marketing/OpenAppCta.astro web/src/components/Footer.astro web/src/layouts/Layout.astro web/src/styles/global.css web/tests/marketing-page.test.mjs
git commit -m "feat: add app-first marketing finale"
```
