# Conscia Glyph Inventory And Level Up Design

## Goal

Define the intentional long-term scope for Conscia’s custom glyph system and describe a dedicated full-screen `Level Up` experience that gives Journey progress a calmer, more ceremonial moment than a standard alert.

## Why This Direction

The app has reached the point where visual language needs clearer boundaries.

Right now:

- category glyph work is trending toward something more ownable
- the dashboard and Journey surfaces already carry more emotional weight than generic utility UI
- some Journey-related alert copy still reflects an older information architecture
- `level up` moments feel important enough to deserve a more meaningful destination

At the same time, trying to replace every icon in the app with bespoke Conscia symbols would create a noisy, harder-to-maintain system.

The better design split is:

- custom Conscia glyphs for the identity layer
- Material/Cupertino icons for the system layer

That keeps the branded icons special and preserves instant clarity in settings, notifications chrome, navigation, and generic utilities.

## Custom Glyph Scope

Conscia custom glyphs should be reserved for:

- categories
- quests
- milestones
- levels

These are the product concepts that are uniquely tied to Conscia’s tone, emotional framing, and Journey system.

## System Icon Scope

Material/Cupertino icons should remain in place for:

- navigation
- settings rows
- generic utility controls
- system affordances like back, close, share, search, filter, edit, delete
- notification chrome such as the bell itself

This keeps the app grounded and legible while allowing custom glyphs to act as the brand layer rather than replacing every familiar symbol.

## Glyph Generation Workflow

The next generation workflow should be designed for easy iteration with GPT while preserving a consistent house style.

The prompt pack format should be:

- one master system prompt that defines the overall Conscia icon language
- one short prompt per icon

This allows icons to be generated independently while still inheriting a shared visual grammar.

## Master Visual Direction

Every generated glyph should follow these rules:

- monochrome
- rounded strokes
- soft geometry
- warm and calm visual tone
- strong silhouette first
- readable at small mobile sizes
- balanced spacing
- no text
- no gradients, shadows, textures, or realism
- no game-like intensity
- no corporate fintech sharpness
- no tiny decorative details

The glyphs should feel:

- thoughtful
- grounded
- reassuring
- human
- editorial rather than technical

## Glyph Inventory Prompt Pack

The prompt pack should be grouped by concept family.

### Categories

- groceries
- dining
- coffee
- transport
- shopping
- health
- bills
- education
- travel
- subscription
- salary
- freelance
- business
- investment
- gift
- home
- utilities
- phone
- pets
- other

These should feel warm, simplified, and highly recognizable. For travel specifically, the direction should avoid abstract airplane marks and favor something clearer like luggage or a passport.

### Quests

- reflect-three-purchases
- check-before-purchase
- review-regret-pattern
- read-two-insights
- create-budget-guardrail
- send-family-invite
- add-family-expense
- review-subscriptions
- set-bill-reminder
- move-money-to-savings
- pay-down-debt

These should feel like gentle prompts or rituals rather than achievement badges.

### Milestones

- first-reflection
- pause-before-purchase
- budget-rescuer
- regret-pattern-spotted
- worth-it-week
- family-founder
- insight-reader
- subscription-sleuth
- fee-detective
- savings-streak
- debt-slasher
- bill-boss

These should feel commemorative but still calm and grounded.

### Levels

- awakening
- impulse-spotter
- budget-guardian
- conscience-captain
- money-monk
- fallback advanced level crest

These are the most Conscia-specific symbols and should carry the strongest sense of identity.

## GPT Prompt Pack Format

The final prompt pack should contain:

### 1. Master system prompt

A reusable instruction block that defines:

- Conscia’s emotional tone
- stroke/shape behavior
- what to avoid
- the expected icon output style

### 2. One short prompt per icon

Each icon prompt should:

- name the icon
- describe the metaphor
- describe the feeling it should carry
- keep the instruction short enough to pair cleanly with the master prompt

This is intended to be pasted into GPT as:

1. master system prompt
2. one icon prompt
3. inspect result
4. refine/export

## Alert Copy Cleanup

Journey alert copy needs to reflect the current dashboard-first architecture.

`Open Journey Home` is stale because the Journey home context is now effectively integrated into the dashboard.

Recommended replacements:

- `View level` for level-up alerts
- `See progress` for badge/milestone alerts
- `Continue journey` for quest-completion alerts

This keeps the wording aligned with the modern app structure while still preserving the Journey concept.

## Level Up Page

`Level up` should no longer feel like a generic alert that routes into a broad screen. It should open a dedicated full-screen destination.

The page should feel like a quiet threshold, not a noisy reward ceremony.

## Level Up Experience Goals

The full-screen level-up page should:

- briefly isolate the user from the surrounding dashboard context
- make the new level feel meaningful
- connect the level to what changed in the user’s money rhythm
- guide the user back into the app with one clear next step

## Level Up Tone

The tone should be:

- quiet ceremonial progress
- warm
- affirming
- reflective
- grounded

It should avoid:

- confetti-heavy celebration
- game-like reward blasts
- dense analytics-first presentation
- loud visual payoffs

## Level Up Page Structure

The recommended page structure is:

### Atmosphere

- a soft background wash or halo
- gentle visual separation from the dashboard
- the level glyph centered prominently near the top

### Main message

- title like `You reached Budget Guardian`
- a short warm line such as `Your money rhythm is getting steadier.`

### Meaning block

- one or two sentences that explain what this level represents
- meaning-first, not stats-first

### Optional progress support

- XP gained
- streak context
- related milestone cue if relevant

This information should remain secondary to the emotional framing.

### Primary action

- `Continue your journey`

This should return the user to the dashboard/Journey context.

### Secondary exit

- a minimal close/back affordance
- understated, not equal in emphasis to the main CTA

## Navigation Behavior

The intended flow is:

- user receives a `journey_level_up` alert
- the alert action is labeled `View level`
- tapping the alert opens the dedicated full-screen level-up page
- the CTA on that page returns them to the dashboard

This creates a clearer emotional arc:

- alert
- celebration/meaning
- return to everyday progress

## Success Criteria

This work succeeds if:

- the glyph system has a clearly bounded long-term scope
- GPT generation can be guided by one reusable master prompt plus short icon prompts
- custom glyphs remain special instead of spreading into every system surface
- stale Journey alert wording is removed
- level-up moments feel meaningfully distinct from ordinary alerts

## Recommendation

Proceed with:

- a reusable glyph inventory prompt pack for categories, quests, milestones, and levels
- alert copy cleanup to match the dashboard-first Journey structure
- a dedicated full-screen `Level Up` page designed as a calm ceremonial checkpoint
