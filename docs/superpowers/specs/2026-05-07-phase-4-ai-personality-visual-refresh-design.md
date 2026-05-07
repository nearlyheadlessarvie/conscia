# Phase 4: AI Personality + Visual Refresh, Part 1

**Date:** 2026-05-07  
**Status:** Draft for review  
**Scope:** `src/Conscia.AI/`, `src/Conscia.Api/`, `src/Conscia.Application/`, `app/lib/screens/assistant/`, `app/lib/screens/transactions/`, `app/lib/screens/settings/`, shared UI primitives, `web/`

## Summary

Phase 4 evolves from prompt tuning into a combined AI-behavior and visual-language milestone.

The goal is to make Conscia feel more distinct and memorable in two linked ways:

1. AI responses should have clearer personalities, stronger contrast, and a user-controlled intensity level that changes tone, directness, and model temperature across all AI surfaces.
2. The app should begin a broader visual refresh anchored around AI surfaces, the shared amount input, and a new compact conscience motif system that works across the app, launcher icon, and marketing site.

This phase is intentionally the start of a broader app-wide visual refresh, not the end of it. It establishes reusable visual patterns around the AI experience first, then those patterns can spread to the rest of the product later.

## Goals

- Make `Impulse`, `Reason`, and `Reflection` feel clearly different in voice.
- Let users control overall AI intensity globally.
- Improve the visual identity of AI surfaces without forcing a full redesign of every screen.
- Replace generic loading/spinner moments with branded, small-size conscience visuals where appropriate.
- Redesign the shared amount input so it feels premium, central, and more product-defining.
- Establish a reusable icon/motif direction that works in the app and on the marketing site.

## Non-Goals

- Full app-wide redesign of every screen in this phase.
- Completing unfinished voice input work.
- Implementing the full dedicated regret-memory alert system.
- Replacing all category/system icons with custom illustrated icons.
- Redesigning the entire landing page during this phase.

## Product Direction

Conscia should feel like a financial conscience, not just a budgeting tool with AI attached.

The product personality is:

- playful but not unserious
- direct but never shameful
- emotionally aware but still practical
- premium and memorable rather than generic fintech minimalism

The interface should reinforce that identity:

- the AI should feel like two believable internal voices plus a reflective synthesis
- the visuals should echo the conscience metaphor without turning into novelty art
- branding should stay readable on small mobile surfaces

## Global AI Personality Intensity

Add a new global setting:

- `Mild`
- `Balanced`
- `Intense`

Default:

- `Balanced`

Location:

- Settings
- label: `AI Personality Intensity`
- helper text: `Adjusts tone, directness, and how strongly Conscia plays both sides.`

This preference affects **all AI-generated responses**, including:

- Pre-Purchase Assistant
- transaction reflection sheets
- any future AI advice surfaces using the same AI service layer

### What Intensity Changes

Intensity changes:

- system prompt wording and persona instructions
- response directness
- emotional contrast between personas
- model temperature

Intensity does **not** change:

- safety rules
- freemium limits
- business logic
- budgeting calculations

### Intensity Behavior

#### Mild

- softer, gentler tone
- less push-pull between personas
- lower emotional force
- less commanding directness
- more observational framing

Use cases:

- users who want guidance without strong persuasion

#### Balanced

- clear contrast between personas
- practical and expressive without becoming theatrical
- default product voice

Use cases:

- most users

#### Intense

- stronger persona contrast
- sharper phrasing
- more memorable persuasive tension
- more confident directness

Use cases:

- users who want a stronger conscience/coach feel

## Persona Behavior

Conscia currently uses:

- `Impulse`
- `Reason`
- `Neutral`/summary

This phase keeps the same high-level architecture but sharpens the behaviors and reframes the neutral layer as `Reflection` in product voice where appropriate.

### Impulse

Role:

- tempting, playful, emotionally appealing devil’s-advocate voice

Characteristics:

- reward-oriented
- light FOMO/reward framing
- witty and energetic
- validates enjoyment and emotional value

Guardrails:

- never reckless
- never encourages clearly harmful financial behavior
- never becomes manipulative or sneering

### Reason

Role:

- concise, practical, budget-aware counterweight

Characteristics:

- short and decisive
- budget-first
- direct about cost, tradeoffs, and timing
- less emotionally padded

Guardrails:

- never shaming
- never parental or preachy
- never cold to the point of feeling hostile

### Reflection

Role:

- calm synthesis and self-awareness layer

Characteristics:

- Socratic when useful
- non-judgmental
- pattern-aware
- capable of referencing prior regrets or recurring behavior where data exists

Guardrails:

- should not sound like a lecture
- should not repeat the same sentence structure every time

## Temperature and Directness Strategy

Intensity should affect all personas, but not identically.

Recommended temperature bands:

### Mild

- `Impulse`: `0.72`
- `Reason`: `0.28`
- `Reflection`: `0.45`

### Balanced

- `Impulse`: `0.84`
- `Reason`: `0.38`
- `Reflection`: `0.58`

### Intense

- `Impulse`: `0.94`
- `Reason`: `0.48`
- `Reflection`: `0.68`

These values are starting points, not contractual magic numbers. During implementation, exact values may be nudged if testing shows excessive repetition or instability.

Directness should also scale:

- `Mild`: suggestive
- `Balanced`: clear
- `Intense`: decisively worded

Example for `Reason`:

- Mild: `You may want to pause a bit on this.`
- Balanced: `This looks like a good moment to pause.`
- Intense: `Pause. This is likely not the right spend right now.`

## Visual Refresh Scope

This phase starts the broader app-wide visual refresh by focusing on the highest-leverage shared surfaces:

- Pre-Purchase Assistant
- transaction reflection sheet loading state
- shared amount input
- AI personality settings control
- compact brand motif system
- marketing alignment notes for `web/`

This phase does not attempt to redesign every list, every settings row, or every onboarding screen.

## Compact Conscience Motif System

The current detailed conscience icon is strong for branding, onboarding, and store presence, but too intricate for small in-app UI.

This phase introduces a simplified visual family derived from that concept.

### Core Rule

Use a **simplified conscience motif** for in-app assistant states and compact surfaces.

Do not reuse the detailed full illustration directly in small UI.

### Motif Direction

- circular split-balance emblem
- yin-yang-inspired structure
- clearly feminine angel silhouette
- clearly masculine devil silhouette
- classic shoulder-angel orientation in the composition:
  - devil on the left
  - angel on the right
- premium, elegant, readable at launcher and compact UI sizes
- more simplified than the current detailed icon
- not flat for flatness’ sake, but cleaner and easier to read

### Gender Readability

The silhouettes should read clearly:

- angel: feminine
- devil: masculine

Use silhouette language, not detailed facial rendering:

- angel: softer profile, longer flowing hair shape, gentler contour rhythm
- devil: sharper profile, stronger jaw/brow, more angular horn structure

The result should feel premium and iconic, not cartoonish.

### Usage Levels

#### Level 1: Detailed Brand Mark

Use for:

- onboarding hero moments
- marketing hero treatments
- app/store branding

#### Level 2: Simplified Premium Mark

Use for:

- launcher/app icon direction
- assistant headers
- loading states
- compact branded product moments

This is the main design target for this phase.

### Preferred Direction

For execution, use the previously reviewed `C` direction from the icon exploration board as the base composition.

That direction should be refined, not copied mechanically:

- preserve the circular split-balance structure
- keep the devil left / angel right orientation
- simplify internal detail where small-size readability improves
- keep enough richness to avoid becoming a generic flat emblem

## App Icon Direction

The app icon should move toward:

- circular split-balance emblem
- cleaner premium mark
- easier to read at launcher size on Android and iOS
- still recognizably derived from the current conscience concept
- based on the reviewed `C` direction from the concept board

Color direction:

- angel should remain the lighter, clearer side of the balance
- devil should shift to a darker, moodier red
- the devil red should sit closer to the navy background so it feels premium and integrated rather than neon-bright
- the two sides should still remain distinguishable at launcher size

The mark should not become generically flat. It can preserve subtle depth, layering, and richness, but the small-size reading test matters more than illustration detail.

The icon should remain strong in:

- Android launcher sizes
- iOS home screen
- splash/app-switcher usage
- favicon/marketing downscale scenarios

## Pre-Purchase Assistant Visual Direction

### Header Motif

Replace the current generic overlapping circles with the new simplified conscience motif family.

The assistant header should feel like a branded product moment, not a placeholder illustration.

### Thinking State

When the AI is generating a response, show a branded thinking state instead of a generic loading indicator.

Behavior:

- subtle “faceoff” or “push-pull” animation between the angel and devil
- playful, but restrained
- small and compact
- should not feel like a game or cartoon battle

Suggested motion cues:

- alternating emphasis
- slight opposing lean
- subtle bounce or tilt
- soft breathing/pulsing rhythm

No large, noisy motion.

### Helper Copy

Possible caption style:

- `Impulse and Reason are weighing in…`

Tone should match the app voice: warm, branded, not cheesy.

## Reflection Sheet Loading State

Reflection sheets can use the same motif system, but more quietly.

Rule:

- reuse the same conscience family
- reduce intensity
- slower, calmer motion
- more contemplative than playful

This should feel like a polished branded loader, not a forced reuse of the assistant animation.

Suggested caption:

- `Reflecting on this purchase…`

If testing shows the animation feels busy in the modal context, the fallback is a simpler calm pulse version of the same motif.

## Shared Amount Input Redesign

The current amount field is functional but visually generic.

This phase redesigns the shared amount input used in:

- Add Transaction
- Pre-Purchase Assistant

### Goals

- make the amount feel central to the decision
- improve hierarchy
- reduce generic form-field feel
- preserve usability and numeric clarity

### Direction

- larger, calmer container
- centered amount
- sign indicator at left
- compact currency chip at right
- softer but intentional border/shadow treatment
- more generous vertical padding
- stronger amount emphasis without becoming flashy

Expense and income variants should preserve their semantic cues, but the shared structure should remain consistent.

This is a shared component refresh, not two separate screens hand-styled differently.

## Settings Screen Update

Add `AI Personality Intensity` to Settings using the new visual language.

Recommended control:

- segmented pill or premium-feeling three-option selector

Options:

- `Mild`
- `Balanced`
- `Intense`

Selected state should feel clearly active without breaking the broader settings aesthetic.

## Marketing Site Alignment

The existing `web/` marketing page is in scope as a design target, even if not fully implemented in this phase.

The mockup/design language from this phase should be reusable there:

- conscience motif family
- premium amount-input visual language
- AI personality framing
- cleaner assistant-inspired hero treatment

The marketing site should feel like the same product family, not a separate brand exercise.

This phase should produce enough visual direction that `web/` can later be refreshed with minimal reinterpretation.

## Accessibility and Mobile Readability

The conscience motif and shared amount input must hold up on real devices.

Requirements:

- icon remains legible at small sizes
- high enough contrast for silhouettes
- loaders are understandable without relying on color alone
- motion remains subtle and non-fatiguing
- controls remain tappable and readable on mobile

Platform note:

The improvement in mockups is not primarily because of web rendering. The current live UI feels weaker mostly due to hierarchy and component styling choices. The new design should improve Android, iOS, and web together.

## Technical Direction

Expected backend/frontend touchpoints:

- prompt template updates
- AI service temperature configuration
- user preference storage for intensity
- settings UI and profile/service plumbing
- assistant header/loading visuals
- reflection sheet loading visuals
- shared amount input component refresh

The intensity setting should be stored like other user-facing preferences so it survives account usage across sessions.

## Testing and Review

### AI Behavior QA

- test at least 10+ spending scenarios
- compare all three intensity levels
- compare all personas across low/high stakes purchases
- verify that voice contrast is clear but still brand-aligned

### Visual QA

- compare assistant and reflection loaders on mobile sizes
- verify icon clarity at small sizes
- verify amount input readability on Android, iOS, and web
- check settings control clarity and accessibility

### Brand QA

- confirm the new simplified mark still feels like Conscia
- confirm the marketing hero can reuse the same visual language

## Open Follow-Up Work After This Phase

- broader app-wide visual refresh across more screens
- voice input completion
- dedicated regret-memory alert experience in assistant flow
- date-range filters and deeper insights polish
- marketing page implementation refresh in `web/`

## Deliverables

- global AI personality intensity setting
- revised persona prompts and temperature mapping
- redesigned assistant thinking state
- subtle reflection loader refresh
- shared amount input redesign
- simplified premium conscience motif family
- full first-pass custom category icon family
- app icon direction update brief
- marketing-aligned visual language starter

## Category Icon Family Expansion

This phase should also define the first full custom Conscia category icon family in one pass.

### Why

Right now, category surfaces rely mostly on platform-native iconography. That is fast and functional, but it makes the app feel more generic than the refreshed AI and brand direction.

Since Conscia is moving toward a stronger, more memorable visual identity, category icons should become part of that identity too.

The category system is one of the most repeated visual languages in the product:

- transaction chips
- category pickers
- budget cards
- dashboard summaries
- assistant category selection
- marketing/site storytelling later

Because it appears so often, a custom family here will have outsized impact.

### Scope

Do all supported transaction categories in one pass.

Do not stop at only the top few categories.

The result should be a complete first-pass icon family covering the app’s existing category taxonomy, so users do not see a mix of polished custom icons for some categories and fallback generic icons for the rest.

### Style

The category family should use:

- slightly more illustrative mini-icons
- stronger personality than plain glyphs
- disciplined silhouettes
- premium, compact readability at mobile sizes

These are not mascot illustrations or detailed sticker art.

They should feel:

- more expressive than Material/Cupertino defaults
- simpler than marketing illustrations
- crisp in chips, cards, and lists

### Platform Strategy

The icon family should adapt to platform context as much as practical while preserving the same conceptual metaphor.

Recommended rule:

- same core concept per category on both platforms
- Android rendering can be slightly bolder / more Material-friendly
- iOS rendering can be slightly cleaner / lighter / more Cupertino-friendly

This should not become two unrelated icon sets.

It should feel like:

- one shared Conscia family
- with platform-tuned execution

### What Stays Platform-Native

Keep platform-native icons for utility/system actions, including examples like:

- back
- close
- calendar
- chevrons
- overflow
- settings
- share
- edit

### What Becomes Conscia-Owned

Use the custom Conscia system for:

- category icons
- the conscience motif family
- app icon
- AI loaders / clash states
- other brand-defining AI surfaces

### Quality Bar

Each category icon should:

- read instantly at small sizes
- work on both light and dark-adjacent surfaces if needed
- feel related to the rest of the family
- avoid becoming visually noisy when shown in repeated rows

### Design Output

The visual refresh should include a category-icon sheet showing:

- all categories
- platform-tuned examples where relevant
- color/shape consistency rules
- example usage in chips, cards, and list rows
