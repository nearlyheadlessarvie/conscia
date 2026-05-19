# Journey Class-1 Redesign Design

**Date:** 2026-05-19
**Status:** Approved for planning
**Feature:** Conscia Journey redesign as a class-1 behavioral hub

## Goal

Redesign the Journey feature so it no longer feels like a secondary gamification screen and instead becomes a first-class behavioral hub inside the Conscia app.

The new Journey should:

- feel like a dedicated companion-led destination
- interpret user behavior across the app rather than only displaying rewards
- guide the user toward the next best mindful action
- stay faithful to the existing Conscia iOS-forward v2 design language
- preserve the current 5-destination dock and current app shell structure

The redesign should not:

- add Journey as a sixth dock destination
- replace Home as the app's primary landing screen
- introduce fictional backend capabilities that do not exist yet
- turn Journey into an arcade-style XP dashboard

## Product Role

Journey should become the app's behavioral operating system.

The app's tool destinations remain what they are today:

- Home
- Transactions
- Scan Receipt
- Purchase Assistant
- Settings

Journey serves a different purpose. It is the place where Conscia interprets what the user's actions mean.

Budgets, reflections, regret tracking, insights review, and purchase pauses may happen in other parts of the app, but Journey is where those actions are translated into:

- momentum
- recovery
- consistency
- patterns of growth
- patterns of drift
- recommended next actions

Journey should answer four questions each time the user opens it:

- How am I doing?
- What should I do next?
- What patterns are improving or slipping?
- What did Conscia notice about me lately?

This shifts Journey from a trophy case into an active behavior center.

## Product Direction

The approved direction is:

- behavior-first, not navigation-first
- balanced habit-building, not only reflection or only discipline
- companion-led, not hyper-gamified
- dedicated hub, not a home-screen replacement

That means Journey should feel alive and important, but its importance comes from interpretation and guidance rather than raw nav prominence.

## Navigation And Discovery

Journey remains a full-screen destination at the existing `/journey` route.

It should not be promoted into the floating dock. The current 5-destination dock remains unchanged.

Instead, Journey becomes class-1 through stronger discovery and stronger return value:

- Home keeps a prominent Journey entry point in the editorial hero
- alerts and important Journey moments can deep-link into the Journey hub
- other behavioral surfaces such as Insights, Purchase Assistant, and transaction reflection flows can open Journey when the user wants the broader personal meaning
- the Journey hub itself must feel rich enough that users intentionally return to it

Working model:

- the dock gets users to tools
- Journey interprets behavior across those tools

## Home Relationship

Home should stop presenting Journey as a small stat card or sidecar surface.

Home's Journey preview should instead communicate:

- the user's current Journey state
- one recommended next step
- one signal of improvement or drift
- one strong entry into the full Journey hub

This keeps Journey prominent without collapsing Home into Journey.

## Screen Structure

The Journey screen should be reorganized into five major modules in this order.

### 1. Hero Summary

The screen starts with a full-bleed editorial hero using the existing gradient-hero language already used across the app's richer emotional screens.

The hero should include:

- Journey title
- current level, chapter, or equivalent progress identity
- a short companion-led guidance message
- momentum or streak signal
- one calm progress indicator

The hero should feel emotionally rewarding, but not like a game lobby.

### 2. Today With Conscia

This is the primary module of the screen.

It answers:

- what is the single best next action right now?

This section should present one clear recommendation card, not multiple competing prompts.

Representative recommendation types:

- reflect on a recent expense
- review a regret pattern
- complete a weekly habit
- pause before a likely impulsive purchase
- revisit a budget nudge

This section is the clearest expression of Journey as a behavior hub rather than a scoreboard.

### 3. This Week

The current quest treatment should evolve into a weekly arc.

This module should:

- show 2-3 active habits or commitments
- use plain, human language
- emphasize consistency
- avoid noisy checklist energy

The visual treatment should feel like guided commitments, not missions in a game.

### 4. Patterns

This module turns existing Conscia signals into a personal behavioral read.

It should highlight:

- where the user is improving
- where the user may be drifting
- what Conscia has noticed recently

This module should reuse current insights and regret-related data where possible, but present it through the Journey lens rather than an analytics lens.

The tone must stay supportive and non-punitive.

### 5. Milestones

Badges, unlocks, streaks, and mascot moments still matter, but they move below the behavioral modules.

Milestones become evidence of progress rather than the main narrative of the screen.

This helps Journey feel more mature and more useful without removing delight.

## Visual Direction

Journey must follow the established Conscia design guidelines and the approved iOS-forward app redesign direction.

Rules:

- keep the warm `paper` canvas below the hero
- use white grouped cards with restrained borders
- keep gradients mostly contained to the hero and selected key surfaces
- preserve the mascot sprites as the identity language
- use the existing color tokens and typography tokens
- keep the screen visually compatible with Home, Insights, Assistant, and Profile

Journey should feel more editorial than Transactions or Budgets, but it must still read as native to the existing app.

The redesign should avoid:

- generic fintech dashboard aesthetics
- a sixth navigation item
- oversized decorative mascot overload
- overly playful arcade gamification
- cluttered micro-card stacking

## Tone

Journey should feel like a supportive companion.

Desired tone:

- warm
- intelligent
- observant
- emotionally steady
- quietly motivating

Undesired tone:

- childish
- judgmental
- noisy
- overly congratulatory
- manipulative

Progress should feel meaningful, but the emotional center of the screen is guidance and self-awareness, not reward extraction.

## Current Data Fit

The redesign should initially stay grounded in current implementation reality.

The current Journey contracts already support:

- total XP and level state
- momentum tracking
- weekly quest data
- badge progress
- mascot moments

The current app also already has related behavioral inputs in:

- transaction reflection
- regret tracking
- budget nudges
- insights review
- purchase assistant flows

The first version of the redesign should primarily reframe and reprioritize this information into better modules instead of requiring major new backend contracts up front.

## Implementation Phasing

### Phase 1: Screen Restructure

Use the existing Journey route and current summary data to redesign the screen around:

- hero summary
- Today with Conscia
- weekly arc
- patterns
- milestones

This phase is primarily UI, hierarchy, and presentation logic.

### Phase 2: Deeper Behavioral Intelligence

Deepen the Journey system over time by improving event sourcing and interpretation across:

- Purchase Assistant
- Insights
- transaction detail and reflection
- regret review
- budget guidance

This phase strengthens the quality of Journey recommendations and makes the hub smarter over time.

## Acceptance Criteria

The Journey redesign is successful when:

- Journey feels like a first-class destination without becoming a dock tab
- the screen leads with guidance and behavioral meaning rather than only XP and badges
- one clear next action is visible near the top of the screen
- weekly commitments feel human and supportive rather than gamey
- patterns and behavioral signals are presented in a non-judgmental way
- milestones still exist but no longer dominate the whole screen
- the design clearly follows the established Conscia visual system
- the redesign works within the current 5-destination navigation structure

## Implementation Notes

- Keep the existing `/journey` route.
- Keep Home as the main landing screen.
- Strengthen Journey through hierarchy, discovery, and behavioral usefulness rather than shell-level navigation changes.
- Preserve the current floating integrated dock pattern exactly as established in the broader app redesign work.
