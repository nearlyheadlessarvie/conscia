# Conscience Journey Gamification Design

**Date:** 2026-05-11  
**Status:** Approved for MVP scope  
**Feature:** Richer gamification that stays playful, extensible, and emotionally safe

## Goal

Add a mascot-led gamification layer to Conscia that makes healthy financial behavior feel rewarding without reducing the app to generic streak pressure.

The MVP version is called **Conscience Journey**. It introduces XP, levels, weekly quests, badges, and small angel/devil mascot moments. The system rewards awareness and intentionality: reflecting on spending, pausing before purchases, reviewing insights, creating budgets from nudges, and learning from regret patterns.

## Product Principles

- Reward awareness, not only spending less.
- Treat regret as signal, not failure.
- Use "momentum" instead of harsh streak resets.
- Keep the dashboard focused: one progress card and one suggested quest.
- Make quests and badges additive through centralized metadata and backend event rules.
- Keep social sharing and cosmetic unlock collections post-MVP unless real users ask for them.

## MVP User Experience

### Dashboard

Add a **Conscience Progress** card near the insights area.

The card shows:
- Mascot art
- Current level title
- XP progress toward next level
- Momentum days
- One active weekly quest
- A chevron into the full journey screen

Example copy:

> Budget Guardian  
> 420 / 600 XP  
> This week: Reflect on 3 purchases

### Journey Screen

Create a dedicated **Conscience Journey** screen.

Sections:
- Current level and XP progress
- Weekly quests
- Recent mascot moment
- Badges unlocked
- Badges in progress

### Unlock Moment

When an event completes a quest, unlocks a badge, or levels up the user, show a lightweight bottom sheet.

The sheet should:
- Use angel/devil mascot art
- Explain what was earned
- Offer a single close action
- Avoid confetti-heavy or casino-like behavior

## MVP Events

Supported event types:

- `reflection_completed`
- `prepurchase_checked`
- `budget_created_from_nudge`
- `insight_reviewed`
- `regret_pattern_reviewed`

Each event requires a `source_id` so XP awarding is idempotent.

## MVP Rewards

### XP

Initial XP rules:

- Reflection completed: 20 XP
- Pre-purchase check completed: 20 XP
- Budget created from nudge: 35 XP
- Insight reviewed: 10 XP
- Regret pattern reviewed: 25 XP

### Levels

Initial level metadata:

- `awakening`: 0 XP
- `impulse_spotter`: 100 XP
- `budget_guardian`: 300 XP
- `conscience_captain`: 600 XP
- `money_monk`: 1000 XP

### Weekly Quests

Initial weekly quests:

- Reflect on 3 purchases
- Check before 1 purchase
- Review 1 regret pattern

Quest completion awards bonus XP once per week.

### Badges

Initial badges:

- `first_reflection`
- `pause_before_purchase`
- `budget_rescuer`
- `regret_pattern_spotted`
- `worth_it_week`

## Architecture

### Backend

Create `ConscienceJourneyService`.

Responsibilities:
- Record idempotent events
- Award XP
- Update level
- Update momentum
- Update weekly quest progress
- Update badge progress
- Return journey summary for dashboard and journey screen

Endpoints:
- `GET /api/v1/conscience-journey`
- `POST /api/v1/conscience-journey/events`

### Storage

Use DynamoDB for MVP.

Tables or item collections:
- `ConscienceProgress`
- `ConscienceEvents`
- `ConscienceBadgeProgress`
- `ConscienceQuestProgress`

The implementation can use one table with typed sort keys if that better matches existing Dynamo patterns.

### Flutter

Create:
- `lib/models/conscience_journey.dart`
- `lib/services/conscience_journey_service.dart`
- `lib/providers/conscience_journey_provider.dart`
- `lib/screens/dashboard/widgets/conscience_progress_card.dart`
- `lib/screens/conscience/conscience_journey_screen.dart`
- `lib/widgets/conscience_unlock_sheet.dart`
- `lib/core/constants/conscience_journey.dart`

Wire events from:
- Reflection save
- Pre-purchase response completion
- Budget creation from nudge
- Dashboard insight open
- Regret pattern detail open

## Story Demo Seed

The `story-demo` seed should include:
- A non-zero XP total
- Current level
- Weekly quest progress
- At least 3 unlocked badges
- At least 1 badge in progress
- At least 1 recent mascot moment

## Non-Goals

- Leaderboards
- Social sharing
- Cosmetic shop
- Punitive streak loss
- Paid gamification gates
- Seasonal events

## Success Criteria

- Dashboard clearly communicates user progress without crowding insights.
- Event recording is idempotent.
- Adding a new badge or quest requires metadata plus one event rule, not a rewrite.
- Tests cover XP, levels, badges, quests, and duplicate event handling.
- The feature still feels like Conscia: playful conscience, not generic habit app.
