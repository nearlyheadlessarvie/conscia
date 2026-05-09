# Conscia Enhancement Tasks Checklist

**Status Overview:** Phases 1-3 implemented in the current app branch; recurring transactions are now shipped; Phases 4-8 remain planned
**Target Completion:** 16-20 weeks
**Last Updated:** 2026-05-07

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

### Delivered Since This Checklist Was Written
- [x] Add regret reflection capture to transaction and dashboard flows
- [x] Surface regret-oriented prompts and transaction detail reflection affordances
- [x] Keep the phase open for deeper merchant/category memory and analytics work still listed below

### Database Tasks
- [ ] Create `PurchasePatterns` table in DynamoDB
  - [ ] Define schema (user_id, category, merchant, amount_range, regret_rate, etc.)
  - [ ] Set appropriate indexes (GSI for user_id + category)
  - [ ] Create seeding script

- [ ] Create `MerchantStats` table (or combine with PurchasePatterns)
  - [ ] Track per-merchant regret rate
  - [ ] Include visit count

### Backend Tasks
- [ ] Create `Conscia.Application/Services/PurchasePatternService.cs`
  - [ ] Implement `AnalyzePurchasePatterns(userId)` method
  - [ ] Implement `GetRegretMemory(userId, category, merchant, amount)` method
  - [ ] Implement `GetMerchantStats(userId)` method
  - [ ] Add caching logic

- [ ] Create `Conscia.Infrastructure/Repositories/PurchasePatternRepository.cs`
  - [ ] Implement CRUD for PurchasePatterns
  - [ ] Add queries for pattern lookup

- [ ] Create nightly pattern analysis job
  - [ ] Lambda or scheduled service
  - [ ] Aggregate regret data by category, merchant, amount
  - [ ] Calculate regret rates
  - [ ] Store in PurchasePatterns table
  - [ ] Handle concurrency

- [ ] Create backend endpoint `GET /api/v1/patterns/regret-memory`
  - [ ] Query parameters: category, merchant, amount
  - [ ] Return relevant regret warnings
  - [ ] Add auth
  - [ ] Create integration test

- [ ] Create backend endpoint `GET /api/v1/patterns/merchants`
  - [ ] Return top merchants with stats
  - [ ] Include visit count, regret rate
  - [ ] Add sorting options
  - [ ] Create integration test

- [ ] Update Pre-Purchase AI endpoint
  - [ ] Include regret memory data in context
  - [ ] Return alerts in AI response (if applicable)
  - [ ] Test with various purchase scenarios

### Frontend Tasks
- [ ] Create `lib/models/purchase_pattern.dart`
  - [ ] Define model for purchase patterns
  - [ ] Add Freezed + JSON serialization

- [ ] Create `lib/providers/purchase_patterns_provider.dart`
  - [ ] Fetch regret memory for current purchase
  - [ ] Cache patterns (60-min TTL)

- [ ] Create `lib/screens/assistant/widgets/regret_memory_alert.dart`
  - [ ] Display regret memory warnings
  - [ ] Show merchant, category, or amount threshold alerts
  - [ ] Add optional dismiss action

- [ ] Update pre-purchase screen
  - [ ] Add regret memory alert card
  - [ ] Display before AI response
  - [ ] Allow user to dismiss or acknowledge

- [ ] Create `lib/screens/dashboard/widgets/merchant_tracking_card.dart`
  - [ ] Show top merchants with visit count
  - [ ] Highlight problematic merchants (high regret)
  - [ ] Show positive merchants (low regret)
  - [ ] Tap to view detailed stats

- [ ] Create new "Insights" tab (or expand Dashboard)
  - [ ] Add category performance breakdown
  - [ ] Add merchant stats section
  - [ ] Add behavioral insights summary
  - [ ] Add date range filters

- [ ] Add settings toggle for memory alerts
  - [ ] `lib/screens/settings/settings_screen.dart` update
  - [ ] "Remember Past Regrets" toggle
  - [ ] Store in user preferences

- [ ] Create `lib/models/merchant_stat.dart`
  - [ ] Define merchant stat model
  - [ ] Add Freezed + JSON

### Testing & QA
- [ ] Unit tests for PurchasePatternService
- [ ] Unit tests for pattern analysis algorithm
- [ ] Integration tests for nightly job
- [ ] Integration tests for endpoints
- [ ] Widget tests for regret memory alert
- [ ] Widget tests for merchant tracking card
- [ ] Manual testing: verify alerts appear correctly
- [ ] Privacy review: confirm sensitive data is not exposed
- [ ] Performance testing: pattern lookups are fast

---

## Phase 4: AI Personality Refinement (1-2 weeks)

Goal: Distinct, memorable personas

### Backend Tasks
- [ ] Update Impulse persona prompts
  - [ ] Review current prompts in `Conscia.AI` project
  - [ ] Increase emotional appeal and exclamation marks
  - [ ] Add FOMO/reward language
  - [ ] Add emojis to prompts
  - [ ] Test with Ollama locally

- [ ] Update Reason persona prompts
  - [ ] Reduce verbosity
  - [ ] Add direct commands ("Stop", "Skip this")
  - [ ] Lead with numbers and budget impact
  - [ ] Remove emotional language
  - [ ] Test with Ollama locally

- [ ] Update Neutral/Reflection persona prompts
  - [ ] Add Socratic questions
  - [ ] Reference user's past regrets
  - [ ] Focus on self-reflection
  - [ ] Non-judgmental tone
  - [ ] Test with Ollama locally

- [ ] Adjust temperature values per persona
  - [ ] Impulse: 0.90-0.95
  - [ ] Reason: 0.35-0.45
  - [ ] Neutral: 0.60-0.70
  - [ ] Test for consistency

- [ ] Update `Conscia.AI/Services/BedrockAIService.cs` (if needed)
  - [ ] Adjust temperature configurations
  - [ ] Test with AWS Bedrock in dev/staging

### Frontend/Testing
- [ ] Manual testing: 10+ purchase scenarios
  - [ ] Test each persona tone
  - [ ] Verify tone differentiation
  - [ ] Check for consistency across scenarios
  - [ ] Gather user feedback (A/B testing later)

- [ ] Optional: Add personality strength slider
  - [ ] `lib/screens/settings/settings_screen.dart` update
  - [ ] "AI Personality Intensity" setting (Mild, Balanced, Intense)
  - [ ] Store preference in user settings
  - [ ] Adjust temperature based on slider

- [ ] Create test cases for personality tones
  - [ ] Entertainment vs Necessities
  - [ ] Large purchases vs small impulses
  - [ ] Time-of-day factors

### QA & Review
- [ ] UX review: confirm tone differentiation is clear
- [ ] Copy review: ensure no brand misalignment
- [ ] A/B testing setup (optional, future)

---

## Phase 5: Gamification & Streaks (2 weeks)

Goal: Behavioral habit tracking and motivation

### Database Tasks
- [ ] Create `AchievementProgress` table
  - [ ] Schema: user_id, achievement_key, progress, unlocked_at
  - [ ] Index: (user_id, achievement_key)
  - [ ] Define achievement keys ("streak_7", "under_budget", "self_aware", "big_saver", "budget_master")

### Backend Tasks
- [ ] Create `Conscia.Application/Services/AchievementService.cs`
  - [ ] Implement `CheckAchievements(userId, transaction)` method
  - [ ] Implement `GetCurrentStreak(userId)` method
  - [ ] Implement `GetUserProgress(userId)` method
  - [ ] Implement streak calculation logic
  - [ ] Add unit tests

- [ ] Create `Conscia.Infrastructure/Repositories/AchievementRepository.cs`
  - [ ] Implement CRUD for achievement progress
  - [ ] Add queries for user achievements

- [ ] Create backend endpoint `GET /api/v1/achievements`
  - [ ] Return user's achievement progress
  - [ ] Include unlocked achievements with dates
  - [ ] Include current streaks
  - [ ] Add auth
  - [ ] Create integration test

- [ ] Integrate achievement checking into transaction creation
  - [ ] Call `AchievementService.CheckAchievements()` after transaction saved
  - [ ] Update AchievementProgress table
  - [ ] Handle unlocks atomically

### Frontend Tasks
- [ ] Create `lib/models/achievement.dart`
  - [ ] Define achievement data models
  - [ ] Add Freezed + JSON serialization

- [ ] Create `lib/providers/achievements_provider.dart`
  - [ ] Fetch user achievements from backend
  - [ ] Refresh after transaction creation
  - [ ] Cache with 5-min TTL

- [ ] Create `lib/screens/dashboard/widgets/streak_counter_card.dart`
  - [ ] Display current streak prominently
  - [ ] Show personal best streak
  - [ ] Add fire emoji and animation
  - [ ] Link to achievements details

- [ ] Add achievement unlock modal
  - [ ] `lib/widgets/achievement_unlock_modal.dart`
  - [ ] Show on achievement unlock
  - [ ] Display badge, name, description
  - [ ] Add celebratory animation/confetti
  - [ ] Offer share button

- [ ] Create `lib/screens/profile/achievements_screen.dart`
  - [ ] Show all achievements
  - [ ] Display unlocked with dates
  - [ ] Show locked achievements with progress
  - [ ] Add achievement descriptions
  - [ ] Optional: sharing for unlocked achievements

- [ ] Update dashboard layout
  - [ ] Add streak counter card (prominent placement)
  - [ ] Show above budgets or behavioral cards

- [ ] Add achievement metadata
  - [ ] `lib/core/constants/achievements.dart`
  - [ ] Define achievement names, descriptions, icons
  - [ ] Thresholds for each achievement

### Testing & QA
- [ ] Unit tests for AchievementService (streak logic)
- [ ] Unit tests for achievement checking algorithm
- [ ] Integration tests for endpoint
- [ ] Widget tests for streak counter card
- [ ] Widget tests for achievement modal
- [ ] Manual testing: unlock achievements manually
- [ ] Test edge cases (reset streak, back-to-back transactions)
- [ ] Accessibility testing for modal and achievement screen

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
- Phase 4 is independent (can run in parallel with others)
- Phase 5 depends on Phase 3 (achievement checking needs transaction logic)
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
