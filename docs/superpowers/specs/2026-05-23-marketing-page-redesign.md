# Marketing Page Redesign + Account Deletion Page

**Date:** 2026-05-23
**Status:** Approved for implementation

---

## Overview

Redesign the Conscia web marketing page (`web/`) to match the app's actual atmosphere — warm, calm, journeying — and remove the chibi mascot characters as the primary visual. Add a `/account-deletion` page required by Google Play Store.

**What's changing:**
- Replace mascot battle scene hero with app screenshot + copy hero
- Replace story chapter mascot scenes with real app screenshots  
- Add a "How it works" 3-step strip between hero and chapters
- Refresh copy to match app's Journey/calm tone (drop "inner voices" / "financial conscience" framing)
- Add `/account-deletion` page (Google Play requirement, URL: `https://getconscia.com/account-deletion`)

**What's NOT changing:**
- Tech stack: Astro + Tailwind (no migration)
- Color tokens in `global.css` (navy, gold, teal, etc.) — reused as-is
- `/privacy` and `/terms` pages
- Overall 3-chapter narrative arc (before → during → after)

---

## Page Structure

```
Nav
└── Logo (left) + iOS badge + Android badge (right)

Hero
└── Copy (left): kicker · h1 · body · two CTA buttons
└── Phone frame (right): Journey home screen
└── Two floating ambient cards: budget % + a Worth It reflection chip
└── Background: warm cream-amber gradient (matches app)

How It Works (new section)
└── Section label + heading + body
└── 3-step cards in a horizontal grid
    1. Pause before you spend (navy step num)
    2. Log every moment (amber step num)
    3. Reflect and notice (teal step num)
└── Connector lines between cards (desktop only)

Chapter 1 — Log the moment
└── Copy (left): kicker · h2 · body · 3 bullets
└── Phone frame (right): Transactions screen
└── Background: white

Chapter 2 — Reflect without shame
└── Copy (right): kicker · h2 · body · 3 bullets  [reversed grid]
└── Phone frame (left): Reflect screen (Was it worth it? + 3 buttons)
└── Background: warm cream gradient

Chapter 3 — See the patterns
└── Copy (left): kicker · h2 · body · 3 bullets
└── Phone frame (right): Insights screen (regret pulse + patterns)
└── Background: white

Footer
└── Logo + tagline "Small choices, big freedom." (left)
└── Privacy + Terms links (left, below tagline)
└── iOS badge + Android badge stacked (right)
└── Background: dark navy (#17244f)
```

---

## Layout System

- **Container:** boxed — `mx-auto max-w-7xl px-6` (existing `section-shell` class)
- **Hero grid:** `grid-template-columns: 1fr 1fr`, aligned center, `gap: 48px`
- **Chapter grid:** `grid-template-columns: 1fr 1fr`, aligned center, `gap: 64px` — alternating phone side via `chapter-alt` class (existing pattern, keep)
- **How it works steps:** `grid-template-columns: repeat(3, 1fr)`, `gap: 24px`
- **Section vertical padding:** `py-24 md:py-32` (consistent with existing)
- **Phone frame width:** 260px in hero, 220px in chapters

---

## Phone Frame Screens (simulated — no real screenshots yet)

Screens are rendered as HTML inside the phone frame divs. Each mirrors the actual app UI at reduced scale. Data used is the same story-demo data visible in the app screenshots.

| Section | Screen | Key data shown |
|---------|--------|----------------|
| Hero | Journey home | 7-day streak · Next step card · This Week cards |
| Chapter 1 | Transactions list | ₱51,615 trail · Asian Hospital / Disneyland / Wildflour / Freelance Client rows |
| Chapter 2 | Reflect / home | Was it worth it? card (Asian Hospital) · Worth It / Not Sure / Regret buttons |
| Chapter 3 | Insights | ₱1,890 regret signal · 33% rate · Shopping pattern · Starbucks merchant |

---

## Copy Direction

Move away from "inner voices / financial conscience / impulse meets reason" framing. New tone: **calm, first-person, journeying**.

| Element | Old | New direction |
|---------|-----|---------------|
| Hero kicker | "Meet the inner voices" | "Personal finance · reimagined" |
| Hero h1 | "Your financial conscience." | "Your money has a story. Start reading it." |
| Chapter 1 kicker | "Catch the moment" | "Log the moment" |
| Chapter 2 kicker | "Reflect without shame" | Keep — still accurate |
| Chapter 3 kicker | "Build better habits" | "See the patterns" |

All copy in `web/src/data/marketingChapters.js` and `heroContent`.

---

## Files to Create / Modify

### Modify
- `web/src/data/marketingChapters.js` — update `heroContent` and `storyChapters` copy
- `web/src/pages/index.astro` — add HowItWorks section import between Hero and chapters
- `web/src/components/Hero.astro` — replace `HeroBattleScene` with new `HeroPhone` component
- `web/src/components/HowItWorks.astro` — repurpose for 3-step strip (currently empty/unused)
- `web/src/styles/global.css` — remove mascot/battle-scene CSS classes, add any new utility classes needed
- `web/src/components/marketing/StoryScene.astro` — replace mascot scene with app screenshot phone frame

### Create
- `web/src/components/marketing/HeroPhone.astro` — single phone frame (Journey screen) with floating cards
- `web/src/components/screens/JourneyScreen.astro` — Journey home screen simulation
- `web/src/components/screens/TransactionsScreen.astro` — Transactions list screen simulation
- `web/src/components/screens/ReflectScreen.astro` — Reflect / Was it worth it screen simulation
- `web/src/components/screens/InsightsScreen.astro` — Insights / regret pulse screen simulation
- `web/src/pages/account-deletion.astro` — Google Play account deletion page

### Delete (after confirming unused)
- `web/src/components/marketing/HeroBattleScene.astro`
- `web/src/components/mascots/MascotSprite.astro`
- `web/src/utils/mascotFrames.js`
- `web/src/data/mascots/` (angel.json, devil.json, money.json)
- Mascot CSS classes from `global.css`

---

## Account Deletion Page (`/account-deletion`)

**URL:** `https://getconscia.com/account-deletion`  
**Required by:** Google Play Store data safety section  
**Template:** Same `Layout.astro` as privacy/terms

### Required content (per Google Play policy)
1. App and developer name clearly stated
2. Step-by-step instructions for requesting deletion (in-app flow)
3. List of data types deleted
4. Retention period (or confirmation of immediate deletion)

### Content

**Steps to delete your account:**
1. Open Conscia
2. Tap **Settings** (bottom nav, rightmost icon)
3. Scroll to **Data & privacy**
4. Tap **Delete account**
5. Confirm by tapping **Delete account** in the confirmation dialog

**Data deleted immediately and permanently:**
- Account credentials and profile data
- All transactions and receipts
- Budget configurations
- AI interaction history
- Reflection and regret data

**Retention:** None. Deletion is permanent and immediate. No data is retained after confirmation.

**Export first:** Before deleting, use **Settings → Download my data** to export a JSON copy of your history.

---

## Mascot Removal

The angel, devil, and money mascots were the primary visual in the previous design. They are fully removed. No mascot images, sprites, or animation code should remain in the final build. The mascot JSON data files and sprite utilities can be deleted once confirmed unused.

The CSS classes `hero-battle-scene`, `chapter-cloud`, `mascot-frame`, `mascot-sprite`, `hero-loop-*`, `scene-*`, `hero-devil`, `hero-angel`, `hero-money` can all be removed from `global.css`.

---

## Success Criteria

- [ ] Marketing page loads with no mascot images or references
- [ ] Hero shows Journey screen phone frame with floating cards
- [ ] "How it works" 3-step strip renders between hero and chapters
- [ ] All 3 chapter sections show correct simulated app screens
- [ ] Chapter alternation (left/right phone sides) works on desktop and mobile
- [ ] `/account-deletion` page exists and contains all Google Play required content
- [ ] Existing `/privacy` and `/terms` pages unaffected
- [ ] No broken imports (mascot utilities removed cleanly)
- [ ] Tailwind build passes with no unused class warnings from deleted components
