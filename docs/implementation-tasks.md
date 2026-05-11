# Conscia Enhancement Tasks Checklist

**Status Overview:** Phases 1-4 implemented/evolved in the current app branch; recurring transactions are now shipped; Phase 5 is now MVP-scoped as Conscience Journey gamification; remaining Phase 5+ work is planned
**Target Completion:** 16-20 weeks
**Last Updated:** 2026-05-11

---

## Phase 1: Dashboard Behavioral Insights (2-3 weeks)

Goal: Add behavioral psychology elements to home screen

### Frontend Tasks
- [ ] Create `lib/screens/dashboard/widgets/financial_mood_card.dart`
  - [ ] Design mood calculation widget
  - [ ] Implement mood color/icon system (Confident, Balanced, Cautious, Impulsive)
  - [ ] Add percentage display and trend indicator
  - [ ] Mobile responsive layout

- [ ] Create `lib/screens/dashboard/widgets/impulse_trends_card.dart`
  - [ ] Design category trend widget
  - [ ] Implement trend arrows (↑ worse, ↓ improving, ✓ steady)
  - [ ] Show top 3 trending categories
  - [ ] Color code by trend direction

- [ ] Create `lib/screens/dashboard/widgets/worth_it_counter_card.dart`
  - [ ] Design counter widget with sparkle effect
  - [ ] Implement month comparison (vs last month)
  - [ ] Add motivational copy
  - [ ] Animate counter on value change

- [ ] Create `lib/providers/behavioral_insights_provider.dart`
  - [ ] Define Riverpod provider for behavioral insights
  - [ ] Implement data fetching from backend
  - [ ] Add caching (1-hour TTL)
  - [ ] Handle loading/error states

- [ ] Update `lib/screens/dashboard/dashboard_screen.dart`
  - [ ] Reorder dashboard components (behavioral cards first)
  - [ ] Add behavioral cards below app bar
  - [ ] Adjust layout for new cards
  - [ ] Test responsive behavior on different screen sizes

- [ ] Create `lib/models/behavioral_insights.dart`
  - [ ] Define data models for mood, trends, worth-it counter
  - [ ] Add Freezed annotations
  - [ ] Add JSON serialization

### Backend Tasks
- [ ] Create `Conscia.Application/Services/BehavioralInsightsService.cs`
  - [ ] Implement `CalculateFinancialMood(userId)` method
  - [ ] Implement `GetImpulseTrends(userId)` method
  - [ ] Implement `GetWorthItCount(userId, monthYear)` method
  - [ ] Add unit tests for each method

- [ ] Create `Conscia.Domain/Entities/BehavioralMood.cs` enum
  - [ ] Define mood enum (Confident, Balanced, Cautious, Impulsive)
  - [ ] Add mood thresholds (percentage ranges)

- [ ] Create DynamoDB table `WeeklyInsights`
  - [ ] Define table schema (user_id, week_start_date, mood, etc.)
  - [ ] Set TTL policy (12 weeks)
  - [ ] Create seeding script

- [ ] Create `Conscia.Infrastructure/Repositories/WeeklyInsightsRepository.cs`
  - [ ] Implement CRUD operations
  - [ ] Add queries for latest insights per user

- [ ] Create backend endpoint `GET /api/v1/insights/behavioral`
  - [ ] Wire up to BehavioralInsightsService
  - [ ] Add auth middleware
  - [ ] Add error handling and response caching
  - [ ] Create integration test

- [ ] Create nightly insights generation job
  - [ ] Lambda function or scheduled service
  - [ ] Calculate mood/trends for all users
  - [ ] Store in WeeklyInsights table
  - [ ] Handle errors and logging

- [ ] Create Flutter models from API response
  - [ ] Generate Freezed + JSON serialization
  - [ ] Test deserialization

### Testing & QA
- [ ] Unit tests for BehavioralInsightsService (>80% coverage)
- [ ] Integration tests for backend endpoint
- [ ] Widget tests for each dashboard card
- [ ] Manual testing on iOS and Android
- [ ] Design review with mockups
- [ ] Performance testing (no noticeable delay on dashboard load)

---

## Phase 2: Friction Reduction (2 weeks)

Goal: Faster, easier transaction entry

### Delivered Since This Checklist Was Written
- [x] Replace emoji quick presets with app icon-based quick category chips
- [x] Redesign Add Transaction around a cleaner shell action model (`Scan` + plain add FAB)
- [x] Add shared `Smart location suggestions` for Add Transaction and Pre-Purchase Assistant
- [x] Prompt for location assistance on first open, with later control in Settings
- [x] Add in-app budget nudges after saving an expense in a category without a matching budget
- [x] Rework onboarding currency/profile flow to reduce setup friction before transaction entry
- [x] Add recurring expense/income schedules with weekly, monthly, and yearly cadence plus optional end date

### Frontend Tasks
- [ ] Add quick preset buttons to pre-purchase screen
  - [ ] Create `lib/screens/assistant/widgets/quick_preset_buttons.dart`
  - [ ] Define preset categories (Food, Gaming, Shopping, Coffee, Entertainment)
  - [ ] Implement tap-to-fill category logic
  - [ ] Show typical spend amount as subtitle

- [ ] Integrate voice input
  - [ ] Add `speech_to_text` package to pubspec.yaml
  - [ ] Create `lib/widgets/voice_input_button.dart`
  - [ ] Implement microphone permission request
  - [ ] Add speech-to-text on description field
  - [ ] Test transcription accuracy
  - [ ] Add fallback to manual entry

- [ ] Create `lib/providers/purchase_suggestions_provider.dart`
  - [ ] Fetch suggested amounts from backend
  - [ ] Cache suggestions (30-min TTL)
  - [ ] Handle loading/error states

- [ ] Add smart suggestion chips to pre-purchase screen
  - [ ] Create `lib/screens/assistant/widgets/suggestion_chips.dart`
  - [ ] Display typical amount suggestions
  - [ ] Implement tap-to-fill amount
  - [ ] Show last purchase date

- [ ] Redesign FAB to SpeedDial
  - [ ] Replace single FAB with `speed_dial_fab` or custom implementation
  - [ ] Add primary action: Add Expense
  - [ ] Add secondary: Ask Conscia
  - [ ] Add tertiary: Scan Receipt (premium)
  - [ ] Add haptic feedback on action select
  - [ ] Test accessibility

- [ ] Update `lib/core/routing/app_router.dart`
  - [ ] Distinguish FAB routing (add vs AI assistant)

### Backend Tasks
- [ ] Create `Conscia.Application/Services/PurchaseSuggestionService.cs`
  - [ ] Implement `GetSuggestionsForCategory(userId, category)` method
  - [ ] Query transaction history for typical amounts
  - [ ] Implement `GetMerchantSuggestion(userId, merchant)` method
  - [ ] Add unit tests

- [ ] Create backend endpoint `GET /api/v1/suggestions/purchase`
  - [ ] Query parameters: category, merchant
  - [ ] Return suggested amount, last purchase date
  - [ ] Add auth and caching
  - [ ] Create integration test

- [ ] Update Transaction model to include merchant field (if not already)
  - [ ] Add to DynamoDB schema
  - [ ] Add migration if needed

### Testing & QA
- [ ] Unit tests for PurchaseSuggestionService
- [ ] Integration tests for suggestion endpoint
- [ ] Widget tests for voice input button
- [ ] Widget tests for suggestion chips
- [ ] Microphone permission testing (iOS/Android)
- [ ] Manual testing on real devices
- [ ] Accessibility audit (touch target sizes)

---

## Phase 3: Regret Memory System (3 weeks)

Goal: Use past regrets to influence future decisions

**Status:** Implemented / evolved. The shipped version centers regret memory in Dashboard + Insights with category/merchant drilldowns and seeded story-demo data. Older pre-purchase-specific alert widgets are superseded/deferred by the current Insights-led implementation and can be revisited later as a Conscience Journey event source.

### Delivered Since This Checklist Was Written
- [x] Add regret reflection capture to transaction and dashboard flows
- [x] Surface regret-oriented prompts and transaction detail reflection affordances
- [x] Aggregate regret patterns into `PurchasePatterns`
- [x] Store weekly behavioral insights in `WeeklyInsights`
- [x] Add Dashboard/Insights regret summary surfaces
- [x] Add category and merchant regret drilldowns
- [x] Seed story-demo with regret patterns, weekly insights, and reflection data
- [x] Phase 5 dependency satisfied: Conscience Journey has reflection, pre-purchase, budget nudge, insight review, and regret pattern review surfaces to hook into

### Database Tasks
- [x] Create `PurchasePatterns` table in DynamoDB
  - [x] Define schema for summary, category, and merchant pattern items
  - [x] Add user-scoped DynamoDB key patterns for summary/category/merchant records
  - [x] Create story-demo seeding for purchase pattern data

- [x] ~~Create `MerchantStats` table~~ — Superseded by merchant entries in `PurchasePatterns`
  - [x] Track per-merchant regret rate
  - [x] Include visit count

### Backend Tasks
- [x] Create `Conscia.Application/Services/PurchasePatternService.cs`
  - [x] ~~Implement `AnalyzePurchasePatterns(userId)` method~~ — Superseded by `Conscia.PatternAggregator`
  - [x] Add summary/category/merchant lookup methods for Insights
  - [x] Add category and merchant detail lookups with backing transaction examples
  - [x] Keep caching/storage behind DynamoDB pattern tables rather than in-service memory

- [x] Create `Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`
  - [x] Implement upsert/read behavior for purchase pattern summary/category/merchant records
  - [x] Add user-scoped queries for pattern lookup

- [x] Create pattern analysis job
  - [x] Implement `Conscia.PatternAggregator`
  - [x] Aggregate regret data by category and merchant
  - [x] Calculate regret rates
  - [x] Store in `PurchasePatterns`
  - [x] Also calculate/store weekly behavioral insights

- [x] ~~Create backend endpoint `GET /api/v1/patterns/regret-memory`~~ — Superseded by Insights endpoints
  - [x] `GET /api/v1/insights/summary`
  - [x] `GET /api/v1/insights/categories`
  - [x] `GET /api/v1/insights/categories/{category}`
  - [x] `GET /api/v1/insights/merchants`
  - [x] `GET /api/v1/insights/merchants/{merchant}`

- [x] ~~Create backend endpoint `GET /api/v1/patterns/merchants`~~ — Superseded by `GET /api/v1/insights/merchants`
  - [x] Return merchants with visit count and regret rate
  - [x] Sort by regret-relevant signal in service/UI

- [ ] ~~Update Pre-Purchase AI endpoint with regret memory alert cards~~ — Deferred/superseded for MVP by Insights-led regret memory
  - [x] Pre-purchase flow exists and has behavioral context hooks
  - [ ] Future option: record `prepurchase_checked` for Conscience Journey
  - [ ] Future option: inject specific regret pattern warnings into AI context once the event system is in place

### Frontend Tasks
- [x] ~~Create `lib/models/purchase_pattern.dart`~~ — Superseded by `lib/models/insights_models.dart`
  - [x] Define models for summary, category stats, merchant stats, and drilldown details
  - [x] Add JSON parsing for Insights responses

- [x] ~~Create `lib/providers/purchase_patterns_provider.dart`~~ — Superseded by `lib/providers/insights_provider.dart`
  - [x] Fetch summary/category/merchant regret memory
  - [x] Return safe empty/null states when no patterns exist

- [ ] ~~Create `lib/screens/assistant/widgets/regret_memory_alert.dart`~~ — Deferred/superseded by Insights cards and dashboard summary
  - [x] Display regret memory warnings in Dashboard/Insights
  - [x] Show merchant/category regret pattern details
  - [ ] Future option: bring a compact warning into pre-purchase AI

- [ ] ~~Update pre-purchase screen with a regret memory alert card~~ — Deferred/superseded by current Insights-led flow
  - [x] Pre-purchase screen remains available as a Phase 5 event source
  - [ ] Future option: add regret warning context after Conscience Journey event tracking

- [x] ~~Create `lib/screens/dashboard/widgets/merchant_tracking_card.dart`~~ — Superseded by Insights feed + merchant spotlight/list/detail screens
  - [x] Show top merchants with visit count
  - [x] Highlight high-regret merchants
  - [x] Tap to view detailed merchant stats

- [x] Create new "Insights" screen and dashboard entry points
  - [x] Add category performance breakdown
  - [x] Add merchant stats section
  - [x] Add behavioral insights summary
  - [x] Add dashboard summary/feed links when insights exist
  - [ ] Date range filters deferred; current MVP uses recent/weekly/monthly derived windows

- [ ] ~~Add settings toggle for memory alerts~~ — Deferred; current implementation uses passive Insights surfaces rather than interruptive alerts
  - [ ] `lib/screens/settings/settings_screen.dart` update
  - [ ] "Remember Past Regrets" toggle
  - [ ] Store in user preferences

- [x] ~~Create `lib/models/merchant_stat.dart`~~ — Superseded by `MerchantStat` in `lib/models/insights_models.dart`
  - [x] Define merchant stat model
  - [x] Add JSON parsing

### Testing & QA
- [ ] Unit tests for PurchasePatternService
- [ ] Unit tests for pattern analysis algorithm
- [ ] Integration tests for pattern aggregator job
- [ ] Integration tests for Insights endpoints
- [x] ~~Widget tests for regret memory alert~~ — Superseded by Insights/Dashboard surfaces
- [x] ~~Widget tests for merchant tracking card~~ — Superseded by merchant/category Insights screens
- [x] Manual testing path: story-demo seed shows regret patterns, categories, merchants, dashboard summary, and drilldowns
- [x] Privacy posture: regret memory is surfaced in-app only and user-scoped behind auth
- [x] Performance posture: pattern lookups read pre-aggregated DynamoDB records

---

## Phase 4: AI Personality Refinement (1-2 weeks)

Goal: Distinct, memorable personas

**Status:** Implemented / evolved. The original prompt-only phase became the broader Phase 4 AI Personality + Visual Refresh work. The shipped implementation persists a global AI personality intensity preference, threads it into pre-purchase and reflection AI calls, centralizes persona prompt/temperature behavior in `Conscia.AI`, and exposes the setting in Flutter Settings. The older "add lots of emojis/FOMO" direction was superseded by safer, brand-fit playful contrast plus mascot-led visuals.

### Delivered Since This Checklist Was Written
- [x] Add global `AI Personality Intensity` setting: Mild, Balanced, Intense
- [x] Persist `AiPersonalityIntensity` on the user profile with validation and API responses
- [x] Thread AI intensity into pre-purchase and reflection AI contexts
- [x] Centralize persona prompts in `PromptTemplates`
- [x] Apply intensity-aware temperature mapping in `BaseAIService`
- [x] Add unit coverage for prompt templates and Ollama/Bedrock temperature behavior
- [x] Add Flutter settings coverage for changing AI personality intensity
- [x] Evolve neutral persona into `Reflection` product voice
- [x] Pair the personality work with the mascot/loader visual refresh for AI surfaces

### Backend Tasks
- [x] Update Impulse persona prompts
  - [x] Review current prompts in `Conscia.AI` project
  - [x] Make the upside more vivid, emotional, and playful
  - [x] ~~Increase emotional appeal and exclamation marks~~ - Superseded by intensity-aware energy/directness rules
  - [x] ~~Add FOMO/reward language~~ - Superseded by safer temptation framing with guardrails
  - [x] ~~Add emojis to prompts~~ - Superseded by mascot-led visuals and non-theatrical prompt tone
  - [x] Add Ollama unit coverage for intensity-aware temperatures
  - [ ] Live local Ollama transcript review remains optional QA

- [x] Update Reason persona prompts
  - [x] Reduce verbosity with 2-3 sentence max guidance
  - [x] Add firmer challenge language through intensity profiles
  - [x] Lead with financial perspective and budget impact in the user context
  - [x] Keep tone factual and protective without shame
  - [x] Add Bedrock/Ollama unit coverage for lower-temperature behavior
  - [ ] Live local Ollama transcript review remains optional QA

- [x] Update Neutral/Reflection persona prompts
  - [x] Reframe neutral voice as `Reflection`
  - [x] Add introspective, bigger-picture guidance
  - [x] Reference user's recent regrets through AI context
  - [x] Focus on self-reflection and habit awareness
  - [x] Keep non-judgmental tone
  - [x] Add prompt template coverage

- [x] Adjust temperature values per persona
  - [x] Impulse: intensity-aware higher temperature (`0.65`, `0.82`, `1.0`)
  - [x] Reason: intensity-aware lower temperature (`0.18`, `0.28`, `0.42`)
  - [x] Reflection: intensity-aware balanced/low temperature (`0.2`, `0.34`, `0.5`)
  - [x] Test for consistency with Bedrock and Ollama unit tests

- [x] ~~Update `Conscia.AI/Services/BedrockAIService.cs` directly~~ - Superseded by provider-neutral handling in `BaseAIService`
  - [x] Adjust temperature configurations in shared orchestration
  - [ ] AWS Bedrock dev/staging transcript smoke test remains release QA

### Frontend/Testing
- [ ] Formal manual testing: 10+ purchase scenarios
  - [ ] Test each persona tone with real model transcripts
  - [ ] Verify tone differentiation across low/high intensity
  - [ ] Check consistency across pre-purchase and reflection flows
  - [ ] Gather user feedback (A/B testing later)

- [x] Add personality strength slider/control
  - [x] `lib/screens/settings/settings_screen.dart` update
  - [x] "AI Personality Intensity" setting (Mild, Balanced, Intense)
  - [x] Store preference in user settings
  - [x] Adjust temperature based on slider/control

- [x] Create automated test cases for personality infrastructure
  - [x] Prompt template persona coverage
  - [x] Bedrock mild temperature coverage
  - [x] Ollama intense temperature coverage
  - [x] Flutter settings update coverage
  - [ ] Scenario-level transcript assertions for entertainment vs necessities remain future QA
  - [ ] Scenario-level transcript assertions for large purchases vs small impulses remain future QA
  - [ ] Time-of-day factors remain future context work

### QA & Review
- [x] UX/product review: global intensity setting and mascot-led AI surfaces were accepted during emulator review
- [x] Copy direction review: superseded manipulative FOMO/emojis with brand-safe playful contrast
- [ ] A/B testing setup (optional, future)

---

## Phase 5: Conscience Journey Gamification (2 weeks)

Goal: Playful, mascot-led habit progression that rewards awareness, reflection, and intentional decisions without shame mechanics.

### Database Tasks
- [ ] Create `ConscienceProgress` storage
  - [ ] Schema: `user_id`, `xp_total`, `level_key`, `momentum_days`, `best_momentum_days`, `updated_at`
  - [ ] Store current journey state separately from individual earned badges
  - [ ] Use DynamoDB for MVP so writes can be event-style and low-cost

- [ ] Create `ConscienceEvents` storage
  - [ ] Schema: `user_id`, `event_id`, `event_type`, `source_id`, `xp_awarded`, `created_at`
  - [ ] Enforce idempotency with `(user_id, event_type, source_id)` or equivalent keying
  - [ ] Supported MVP event types: `reflection_completed`, `prepurchase_checked`, `budget_created_from_nudge`, `insight_reviewed`, `regret_pattern_reviewed`

- [ ] Create `ConscienceBadgeProgress` storage
  - [ ] Schema: `user_id`, `badge_key`, `progress`, `target`, `unlocked_at`
  - [ ] Define MVP badge keys: `first_reflection`, `pause_before_purchase`, `budget_rescuer`, `regret_pattern_spotted`, `worth_it_week`

- [ ] Create `ConscienceQuestProgress` storage
  - [ ] Schema: `user_id`, `week_start`, `quest_key`, `progress`, `target`, `completed_at`, `xp_awarded`
  - [ ] Keep quests weekly and deterministic for MVP
  - [ ] Use user's locale/timezone later; start with server week boundary if timezone is unavailable

### Backend Tasks
- [ ] Create `Conscia.Application/Services/ConscienceJourneyService.cs`
  - [ ] Implement `RecordEventAsync(userId, eventType, sourceId)` with idempotent XP awarding
  - [ ] Implement `GetJourneyAsync(userId)` for dashboard/profile consumption
  - [ ] Implement level calculation from `xp_total`
  - [ ] Implement weekly quest progress updates
  - [ ] Implement badge progress/unlock evaluation
  - [ ] Add unit tests for XP, levels, idempotency, quest completion, badge unlocks

- [ ] Create `Conscia.Infrastructure/Repositories/ConscienceJourneyRepository.cs`
  - [ ] Read/write journey state
  - [ ] Read/write event records
  - [ ] Read/write badge progress
  - [ ] Read/write weekly quest progress

- [ ] Create backend endpoint `GET /api/v1/conscience-journey`
  - [ ] Return XP total, current level, next level threshold, momentum, active weekly quests, badge progress, and recent mascot moment
  - [ ] Add auth
  - [ ] Create integration test

- [ ] Create backend endpoint `POST /api/v1/conscience-journey/events`
  - [ ] Accept event type and source id from trusted app flows
  - [ ] Reject unsupported event types
  - [ ] Return updated journey state and any unlocks
  - [ ] Add auth and idempotency tests

- [ ] Wire MVP event sources
  - [ ] Reflection completed after worth-it/not-sure/regret save
  - [ ] Pre-purchase check completed after AI response
  - [ ] Budget created from an unbudgeted category nudge
  - [ ] Insight summary/card opened from dashboard
  - [ ] Regret pattern detail opened from insights

### Frontend Tasks
- [ ] Create `lib/models/conscience_journey.dart`
  - [ ] Define journey, level, quest, badge, unlock, and mascot moment models
  - [ ] Add JSON serialization following existing model patterns

- [ ] Create `lib/services/conscience_journey_service.dart`
  - [ ] Fetch journey state
  - [ ] Record journey events from app flows
  - [ ] Map backend errors through `AppError`

- [ ] Create `lib/providers/conscience_journey_provider.dart`
  - [ ] Fetch and cache journey state
  - [ ] Expose helper methods to record events and refresh state
  - [ ] Refresh after event-producing flows

- [ ] Create `lib/screens/dashboard/widgets/conscience_progress_card.dart`
  - [ ] Show mascot, current level title, XP progress, momentum, and one active quest
  - [ ] Link to journey details
  - [ ] Keep placement near dashboard insights so it feels motivational, not decorative

- [ ] Create `lib/screens/conscience/conscience_journey_screen.dart`
  - [ ] Show current level, XP progress, weekly quests, unlocked badges, locked badge progress, and recent mascot moments
  - [ ] Make future additions data-driven through metadata maps

- [ ] Add unlock/moment UI
  - [ ] Create `lib/widgets/conscience_unlock_sheet.dart`
  - [ ] Show badge/level/quest completion moments after event recording
  - [ ] Use angel/devil mascot art without confetti overload

- [ ] Add journey metadata
  - [ ] `lib/core/constants/conscience_journey.dart`
  - [ ] Define level keys, XP thresholds, badge names, quest labels, mascot copy, and icons
  - [ ] Keep metadata centralized so new badges/quests are additive

### Testing & QA
- [ ] Unit tests for `ConscienceJourneyService`
- [ ] Unit tests for idempotent XP awarding
- [ ] Unit tests for level thresholds and weekly quest completion
- [ ] Integration tests for journey fetch and event recording endpoints
- [ ] Widget tests for dashboard progress card
- [ ] Widget tests for journey screen and unlock sheet
- [ ] Manual testing with `story-demo` seed: visible XP, active quests, unlocked badges, and mascot moments
- [ ] Accessibility testing for progress bars, unlock sheet, mascot alt semantics, and reduced motion

### Product Guardrails
- [ ] Reward awareness and intentionality, not only spending less
- [ ] Use "momentum" rather than punishing streak resets
- [ ] Do not shame users for regret or missed quests
- [ ] Keep social sharing out of MVP unless explicitly revisited
- [ ] Ensure every new quest/badge can be added through centralized metadata and one backend event rule

---

## Phase 6: Weekly Digest (2 weeks)

Goal: Email/push notifications with insights

### Backend Tasks
- [ ] Set up Firebase Cloud Messaging (FCM)
  - [ ] Configure FCM project (if not already done)
  - [ ] Add server-side credentials to secrets manager

- [ ] Create `Conscia.Application/Services/WeeklyDigestService.cs`
  - [ ] Implement `GenerateDigestContent(userId)` method
  - [ ] Query insights, regret data, streaks
  - [ ] Format content for push notification
  - [ ] Add unit tests

- [ ] Create `Conscia.Infrastructure/Services/PushNotificationService.cs`
  - [ ] Send FCM message to user device
  - [ ] Handle delivery confirmation
  - [ ] Log failed sends

- [ ] Set up EventBridge rule for Sunday 8 AM
  - [ ] Create CDK stack or manual configuration
  - [ ] Define schedule expression (Sunday 8 AM, handle timezones)
  - [ ] Link to Lambda trigger

- [ ] Create Lambda function for digest delivery
  - [ ] Query all active users
  - [ ] Call WeeklyDigestService per user
  - [ ] Handle timezone conversion (user's local time)
  - [ ] Send via PushNotificationService
  - [ ] Log execution and errors

- [ ] Create backend endpoint `GET /api/v1/digest/preview`
  - [ ] Return what Sunday's digest would contain
  - [ ] Useful for testing and user preview
  - [ ] Add auth

### Frontend Tasks
- [ ] Add `firebase_messaging` package to pubspec.yaml
  - [ ] Configure iOS and Android properly
  - [ ] Handle permission requests

- [ ] Create push notification handler
  - [ ] `lib/services/push_notification_service.dart`
  - [ ] Handle incoming FCM messages
  - [ ] Display local notifications (using `flutter_local_notifications`)
  - [ ] Handle tap to navigate

- [ ] Create `lib/widgets/weekly_digest_preview.dart`
  - [ ] Display digest content in a modal or new screen
  - [ ] Show from API preview endpoint
  - [ ] Useful for user testing

- [ ] Add user preference for digest timing
  - [ ] `lib/screens/settings/settings_screen.dart` update
  - [ ] "Weekly Digest Day & Time" picker
  - [ ] Store preference backend (UserSubscription or separate table)

- [ ] Test push notifications locally
  - [ ] Use Firebase emulator (if available)
  - [ ] Or manual testing with real FCM

### Testing & QA
- [ ] Unit tests for WeeklyDigestService
- [ ] Integration tests for digest endpoint
- [ ] Integration tests for EventBridge + Lambda
- [ ] Manual testing: verify digest content is accurate
- [ ] Manual testing: push notification arrives and displays correctly
- [ ] Manual testing: tap notification navigates correctly
- [ ] Timezone testing (verify Sunday 8 AM for different zones)
- [ ] Stress test: generate digest for all users

---

## Phase 7: New Insights Tab (2 weeks)

Goal: Dedicated analytics dashboard

### Design Tasks
- [ ] Mockup Insights screen layout
  - [ ] Category performance card
  - [ ] Merchant stats card
  - [ ] Behavioral insights summary
  - [ ] Date range filters
  - [ ] Share/export buttons (future)

### Frontend Tasks
- [ ] Create `lib/screens/insights/insights_screen.dart`
  - [ ] Main screen with tabbed/scrollable layout
  - [ ] Responsive design for different screen sizes

- [ ] Create `lib/screens/insights/widgets/category_performance_card.dart`
  - [ ] Show per-category: spending, worth-it %, trend
  - [ ] List top regrets per category
  - [ ] Show best decisions per category
  - [ ] Tap to expand details

- [ ] Create `lib/screens/insights/widgets/merchant_stats_card.dart`
  - [ ] Show top merchants: visit count, regret rate
  - [ ] Highlight problematic merchants (red)
  - [ ] Highlight positive merchants (green)
  - [ ] Sort options (spending, regret rate, visit count)

- [ ] Create `lib/screens/insights/widgets/behavioral_summary_card.dart`
  - [ ] Show current mood
  - [ ] Show top regret
  - [ ] Show monthly spend projection
  - [ ] Show projected regretted amount

- [ ] Create `lib/providers/insights_provider.dart`
  - [ ] Fetch category performance data
  - [ ] Fetch merchant stats
  - [ ] Fetch behavioral summary
  - [ ] Handle date range filters
  - [ ] Cache with 30-min TTL

- [ ] Add date range picker
  - [ ] Week, Month, Year, Custom
  - [ ] Filter all insights by selected range

- [ ] Update navigation
  - [ ] Add "Insights" to main bottom navigation or top navigation
  - [ ] Link from dashboard behavioral cards to detailed insights

- [ ] Create `lib/models/category_performance.dart`
  - [ ] Define model for category insights
  - [ ] Add Freezed + JSON

- [ ] Create `lib/models/merchant_stat.dart` (if not already)
  - [ ] Define model for merchant stats
  - [ ] Add Freezed + JSON

### Backend Tasks
- [ ] Extend existing endpoints or create new ones
  - [ ] `GET /api/v1/insights/categories?from=&to=` — category performance
  - [ ] `GET /api/v1/insights/merchants?from=&to=` — merchant stats
  - [ ] `GET /api/v1/insights/summary?from=&to=` — behavioral summary
  - [ ] All with date range filtering

- [ ] Create corresponding backend services
  - [ ] Update `BehavioralInsightsService` or create new ones
  - [ ] Add date range filtering
  - [ ] Optimize queries for performance

### Testing & QA
- [ ] Unit tests for insights endpoints
- [ ] Widget tests for insights cards
- [ ] Manual testing: date range filtering works correctly
- [ ] Manual testing: data updates correctly on main dashboard
- [ ] Performance testing: insights load quickly
- [ ] Responsiveness testing on different device sizes

---

## Phase 8: Positioning & Branding (1 week)

Goal: Update messaging across app

### Onboarding & Copy Updates
- [ ] Update onboarding slide 1
  - [ ] New headline: "Your AI Financial Coach"
  - [ ] Subtitle: "Build better spending habits, one decision at a time"
  - [ ] Add comparison: "Like Duolingo, but for money"

- [ ] Update onboarding slide 2-3
  - [ ] Show behavior change benefits
  - [ ] Highlight streak/achievement system
  - [ ] Show insight examples

- [ ] Update app description (Play Store & App Store)
  - [ ] New tagline: "Financial discipline made personal"
  - [ ] Emphasize AI coaching and habit building
  - [ ] Include "Join 10K+ users..." social proof

- [ ] Update app screenshots
  - [ ] Feature behavioral insights dashboard
  - [ ] Show streaks and achievements
  - [ ] Show AI personality differentiation
  - [ ] Show weekly insights card

### In-App Copy Updates
- [ ] Update dashboard section headers
  - [ ] "Your Financial Mood" → emphasize personalization
  - [ ] "Learn From Your Patterns" → emphasize behavior change

- [ ] Update achievement unlock messages
  - [ ] "You're building a healthier spending habit!"
  - [ ] "Your discipline is paying off!"

- [ ] Update settings screen
  - [ ] Add section: "Your Financial Coach"
  - [ ] Links to achieve history, about app

- [ ] Create tutorial/help content
  - [ ] "What is Financial Mood?"
  - [ ] "How do streaks work?"
  - [ ] "How to use insights to change habits"

### Optional Marketing
- [ ] Create social sharing template for achievements
  - [ ] Share button on achievement unlock
  - [ ] "I've built a 7-day reasoned decision streak! 🔥"
  - [ ] Link to app store

- [ ] Add in-app banner for special milestones
  - [ ] "You've reflected on 50+ purchases!"
  - [ ] "Help a friend build better habits"

### Testing & QA
- [ ] Proofread all copy updates
- [ ] Verify links in help/tutorial sections
- [ ] Manual testing: all onboarding screens display correctly
- [ ] Screenshot review with design team

---

## General Tasks (Throughout All Phases)

### Ongoing Testing
- [ ] Create comprehensive test data/scenarios
- [ ] Set up manual testing checklist
- [ ] Create user feedback survey
- [ ] Monitor app performance metrics
- [ ] Track feature adoption

### Documentation
- [ ] Document new database tables in schema guide
- [ ] Document new backend services
- [ ] Document new Riverpod providers
- [ ] Create migration guides for developers
- [ ] Update API documentation

### Code Quality
- [ ] Maintain >80% test coverage
- [ ] Code review all PRs
- [ ] Run linting and formatting checks
- [ ] Address technical debt as needed
- [ ] Update CI/CD pipeline if needed

### DevOps & Infrastructure
- [ ] Test new Lambda functions (weekly digest, pattern analysis)
- [ ] Set up monitoring and alarms
- [ ] Configure backups for new tables
- [ ] Set up cost monitoring
- [ ] Document infrastructure changes in CDK

### Analytics & Metrics
- [ ] Set up event tracking for new features
- [ ] Track feature adoption rates
- [ ] Monitor engagement metrics
- [ ] Track retention changes
- [ ] Create dashboards for success metrics

---

## Blockers & Dependencies

### Known Blockers
- None currently identified

### Dependencies
- Phase 2 depends on Phase 1 (some API endpoints can run in parallel)
- Phase 3 depends on Phase 1 (transaction history needed for patterns)
- Phase 4 is implemented/evolved and was independent of the earlier phases
- Phase 5 depends on Phase 3 and current insights flows (journey events need reflections, pre-purchase checks, budget nudges, and regret pattern review sources)
- Phase 6 depends on Phase 1 (digest needs insights)
- Phase 7 depends on Phase 1 & 3 (needs insights and merchant data)
- Phase 8 is independent (copy updates can happen anytime)

---

## Notes

- **Backend Service Design**: Use existing DynamoDB repositories pattern for new tables
- **Frontend State Management**: Continue using Riverpod; follow existing provider patterns
- **Testing Strategy**: Write tests as features are implemented; aim for >80% coverage
- **Database**: Leverage DynamoDB TTL for temporary data (PurchasePatterns can be re-computed nightly)
- **Performance**: All new endpoints should cache at Riverpod level; queries should be optimized
- **Privacy**: Ensure regret memory alerts are toggleable; don't expose sensitive data
- **Accessibility**: Run accessibility audit on new UI components
- **Mobile**: Test on iOS and Android physical devices, not just emulators
