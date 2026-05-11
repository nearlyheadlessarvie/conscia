# Conscience Journey Gamification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build MVP Conscience Journey gamification with XP, levels, weekly quests, badges, mascot moments, and idempotent event recording.

**Architecture:** The backend records trusted journey events and derives XP, levels, badges, and quests from centralized metadata. Flutter reads a journey summary for dashboard/journey screens and posts event records from reflection, pre-purchase, budget, and insights flows. Story-demo gets seeded journey data so the feature can be checked visually in the emulator.

**Tech Stack:** ASP.NET 8 Minimal APIs, C# application services, DynamoDB repositories, Flutter/Riverpod, Dio, existing mascot assets, Flutter widget/provider tests, xUnit backend tests.

---

## Files

- Create: `src/Conscia.Application/Services/ConscienceJourneyService.cs`
- Create: `src/Conscia.Application/Interfaces/IConscienceJourneyRepository.cs`
- Create: `src/Conscia.Application/DTOs/ConscienceJourneyDtos.cs`
- Create: `src/Conscia.Infrastructure/Repositories/ConscienceJourneyRepository.cs`
- Modify: `src/Conscia.Api/Endpoints/*` to register journey endpoints
- Modify: Dynamo setup/bootstrap code to create journey storage
- Create: `app/lib/models/conscience_journey.dart`
- Create: `app/lib/services/conscience_journey_service.dart`
- Create: `app/lib/providers/conscience_journey_provider.dart`
- Create: `app/lib/core/constants/conscience_journey.dart`
- Create: `app/lib/screens/dashboard/widgets/conscience_progress_card.dart`
- Create: `app/lib/screens/conscience/conscience_journey_screen.dart`
- Create: `app/lib/widgets/conscience_unlock_sheet.dart`
- Modify: reflection, pre-purchase, budget, and insights flows to record events
- Modify: `tools/Seeder` story-demo seed to include journey data
- Test: backend service/repository/endpoint tests
- Test: Flutter provider/widget tests

---

## Task 1: Backend DTOs And Metadata

- [ ] Create DTOs for `ConscienceJourneySummaryDto`, `ConscienceLevelDto`, `ConscienceQuestDto`, `ConscienceBadgeDto`, `ConscienceMascotMomentDto`, `RecordConscienceEventRequest`, and `ConscienceJourneyUpdateDto`.

- [ ] Add backend constants for MVP event types, XP rules, levels, quests, badges, and mascot moments.

- [ ] Write unit tests that assert all MVP event types have an XP rule and all badge/quest keys are unique.

- [ ] Commit:

```bash
git add src/Conscia.Application
git commit -m "feat: define conscience journey contracts"
```

## Task 2: Repository Storage

- [ ] Create `IConscienceJourneyRepository` with methods to get progress, insert event if absent, update progress, update badge progress, update quest progress, and get summary slices.

- [ ] Implement DynamoDB repository using idempotent event writes keyed by `userId`, `eventType`, and `sourceId`.

- [ ] Update local Dynamo setup/bootstrap with the required table or item collection.

- [ ] Write repository request-shape tests for idempotent event writes and summary queries.

- [ ] Commit:

```bash
git add src/Conscia.Application src/Conscia.Infrastructure tools
git commit -m "feat: add conscience journey storage"
```

## Task 3: Journey Service

- [ ] Implement `RecordEventAsync(userId, eventType, sourceId)` so duplicate events return current state without awarding XP again.

- [ ] Implement level calculation from total XP.

- [ ] Implement weekly quest progress and one-time quest completion XP.

- [ ] Implement badge progress and unlock evaluation.

- [ ] Implement `GetJourneyAsync(userId)` for dashboard and journey screen.

- [ ] Write unit tests for XP awarding, duplicate event idempotency, level thresholds, quest completion, badge unlocks, and non-shaming momentum behavior.

- [ ] Commit:

```bash
git add src/Conscia.Application src/Conscia.Infrastructure tests
git commit -m "feat: add conscience journey service"
```

## Task 4: API Endpoints

- [ ] Add `GET /api/v1/conscience-journey`.

- [ ] Add `POST /api/v1/conscience-journey/events`.

- [ ] Enforce auth and validate supported event types.

- [ ] Return updated journey state plus any unlocks from event posting.

- [ ] Add endpoint integration tests for fetch, event recording, duplicate event handling, and unsupported event rejection.

- [ ] Commit:

```bash
git add src/Conscia.Api tests
git commit -m "feat: expose conscience journey endpoints"
```

## Task 5: Flutter Models, Service, And Provider

- [ ] Create Dart journey models matching backend DTOs.

- [ ] Create `ConscienceJourneyService` with `fetchJourney()` and `recordEvent(eventType, sourceId)`.

- [ ] Create Riverpod provider that loads journey state and exposes a helper to record events then refresh state.

- [ ] Map service errors through `AppError`.

- [ ] Add provider/service tests with fake Dio responses.

- [ ] Commit:

```bash
git add app/lib/models app/lib/services app/lib/providers app/test
git commit -m "feat: add conscience journey client state"
```

## Task 6: Dashboard Progress Card

- [ ] Create dashboard `ConscienceProgressCard`.

- [ ] Show mascot, current level, XP progress, momentum, and one active quest.

- [ ] Add navigation to the journey screen.

- [ ] Add skeleton/empty/error states that do not block the dashboard.

- [ ] Add widget tests for loaded, empty, and tap-to-open states.

- [ ] Commit:

```bash
git add app/lib/screens/dashboard app/test
git commit -m "feat: show conscience progress on dashboard"
```

## Task 7: Journey Detail Screen And Unlock Sheet

- [ ] Create `ConscienceJourneyScreen`.

- [ ] Show current level, weekly quests, badges unlocked, badges in progress, and recent mascot moment.

- [ ] Create `ConscienceUnlockSheet` for level, quest, and badge unlocks.

- [ ] Use existing mascot assets and reduced-motion friendly animation.

- [ ] Add widget tests for quest progress, badge progress, and unlock sheet content.

- [ ] Commit:

```bash
git add app/lib/screens/conscience app/lib/widgets app/test
git commit -m "feat: add conscience journey screen"
```

## Task 8: Event Wiring

- [ ] Record `reflection_completed` after reflection save.

- [ ] Record `prepurchase_checked` after pre-purchase AI response completion.

- [ ] Record `budget_created_from_nudge` when a nudge-created budget succeeds.

- [ ] Record `insight_reviewed` when dashboard summary opens Insights.

- [ ] Record `regret_pattern_reviewed` when regret pattern detail opens.

- [ ] Use stable source ids so retrying the same action does not double-award XP.

- [ ] Add tests around at least reflection and pre-purchase event recording.

- [ ] Commit:

```bash
git add app/lib app/test
git commit -m "feat: award conscience journey events"
```

## Task 9: Story Demo Seed

- [ ] Extend `story-demo` seed with XP total, current level, weekly quest progress, unlocked badges, badge progress, and recent mascot moment.

- [ ] Ensure re-running the seed replaces only demo-user journey data.

- [ ] Add seeder tests or deterministic output checks if the tool has existing coverage.

- [ ] Commit:

```bash
git add tools/Seeder tests
git commit -m "feat: seed conscience journey demo data"
```

## Task 10: Final Verification

- [ ] Run backend tests for journey service, repository, and endpoints.

- [ ] Run Flutter tests for provider/card/screen/event wiring.

- [ ] Run `flutter analyze`.

- [ ] Run story-demo seed locally and visually confirm dashboard and journey screen show XP, quests, badges, and mascot moments.

- [ ] Update docs if implementation differs from the design.

- [ ] Commit final polish:

```bash
git add .
git commit -m "docs: finalize conscience journey implementation notes"
```
