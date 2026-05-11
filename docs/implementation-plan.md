# Conscia Enhancement Implementation Plan

**Objective**: Transform Conscia from a standard finance app into "Duolingo for financial discipline" by adding behavioral insights, reducing friction, and creating a distinctive AI personality.

---

## 1. Enhanced Home Screen with Behavioral Insights

### Current State
- Standard "Budgets" section
- "Recent Transactions" list
- Basic regret prompts (24-48h old)

### Vision
Make the dashboard reflect the user's behavioral patterns and spending identity, not just raw data.

### New Dashboard Components

#### 1.1 Financial Mood Card
Shows emotional spending tendency for the current week.

**Display Example:**
```
🧠 Your Financial Mood
Cautious this week
70% of decisions were reasoned
(up from 60% last week)
```

**Data Source:**
- Query transactions from last 7 days
- Calculate regret_level distribution (worth_it, not_sure, regret)
- Assign "mood" based on ratio (e.g., >70% "worth it" = "Confident")

**Moods:**
- Confident: 75%+ "worth it" decisions
- Balanced: 50-75% "worth it"
- Cautious: 25-50% "worth it"
- Impulsive: <25% "worth it"

#### 1.2 Impulse Trends Card
Identifies categories where the user is trending impulsive or reasoned.

**Display Example:**
```
📊 Recent Impulse Trends
Gaming: 3 impulsive in last 7 days ↗️
Coffee: Steady reasonable ✓
Dining: 2 regrets this month ↙️
```

**Logic:**
- Per-category, calculate regret% over last 30 days
- Highlight categories with >60% regret rate
- Show trend direction (↑ getting worse, ↓ improving, ✓ steady)

#### 1.3 Worth It Counter
Gamified counter of positive spending decisions.

**Display Example:**
```
✨ Worth It This Month
You've made 12 decisions you're proud of
(13 last month) 📉
```

**Logic:**
- Count transactions with regret_level = "worth_it" in current month
- Compare to previous month for trend
- Add motivational tone based on progress

#### 1.4 Weekly Insights Card
High-level behavioral insights extracted from weekly data.

**Display Examples:**
```
💡 This Week's Insights
80% of dining spends were 'worth it'
Your biggest regret: Entertainment (£45)
On pace to stay 12% under Food budget
```

**Backend Processing:**
- Run nightly analysis job (or on-demand)
- Calculate per-category worth-it ratios
- Identify largest regrets
- Project budget vs spend for current month
- Store in `WeeklyInsights` table (cache)

---

## 2. Advanced Feedback Loops

### Current State
- Regret prompts appear 24-48h after transaction
- Data collected but not synthesized

### Vision
Transform reflections into habit-change insights that teach the user about themselves.

### New Features

#### 2.1 Weekly Digest (Push Notification)
Sent every Sunday with consolidated insights.

**Content:**
```
📊 Your Weekly Summary
Top category: Dining (£125 spent, 85% "worth it")
Biggest regret: Game purchase (£49)
Trending: Coffee visits up 30% vs last week

Your streak: 7 days of reasoned decisions 🔥
```

**Backend:**
- Scheduled Lambda (EventBridge rule: Sunday 8 AM user local time)
- Queries regret data, budget status, transaction trends
- Sends via Firebase Cloud Messaging

#### 2.2 Category Performance Dashboard
Per-category analytics showing worth-it ratios and trends.

**UI Location:** New "Insights" tab (or expanded Dashboard)

**Display:**
```
Category: Dining
This month: £325 spent, 80% "worth it" ✅
Last month:  £280 spent, 72% "worth it"
Trend: Spending ↑ but quality ↑

Top regret: £89 dinner on the 12th
Best decision: £12 lunch deal on the 8th
```

**Backend:**
- New endpoint: `GET /api/v1/insights/categories`
- Calculate category stats from transactions + regret levels
- Support date range filters (week, month, year)

#### 2.3 Behavioral Streaks
Gamify consecutive reasoned decisions.

**Display:**
```
🔥 Reasoned Decision Streak
5 days in a row
(Personal best: 14 days)
```

**Logic:**
- Count consecutive transactions with regret_level = "worth_it"
- Track personal best
- Reset on first "regret" transaction
- Show on dashboard as motivational element

#### 2.4 Smart Reminders (Pre-Purchase Memory)
Before purchase, alert user of past similar regrets.

**Example:**
```
⚠️ Spending Alert
Last time you spent £50+ on games,
you marked it "not worth it"
Still want to proceed?
```

**Trigger Points:**
- User enters amount matching past regret pattern
- Category has >60% regret rate and amount exceeds threshold
- Same merchant with history of regrets

**Backend:**
- Pattern matching service that queries regret history
- Returns warnings in pre-purchase AI response

---

## 3. Sharper AI Personality System

### 2026-05-11 Status
Implemented/evolved. Phase 4 shipped as AI Personality + Visual Refresh rather than a prompt-only pass. Conscia now persists a global AI personality intensity preference, applies intensity-aware prompts and temperatures across pre-purchase and reflection flows, and exposes the setting in Flutter Settings. The original loud/emojified Impulse direction was superseded by brand-safe playful contrast supported by the mascot-led visual language.

### Original Current State
Both personas (Impulse/Reason) felt similar in tone.

### Vision
Make each persona distinct and memorable.

### Personality Updates

#### 3.1 Impulse Persona (Devil)
**Current Tone:** Safe, slightly encouraging
**Target Tone:** Playful, tempting, emotionally engaging

**Current Example:**
```
This seems like a good purchase for you.
```

**Target Example:**
```
Oh come on, you deserve this! Live a little! 🎉
You've been good all week—treat yourself.
```

**Tone Rules:**
- Use exclamation marks liberally
- Emojis encouraged
- Appeal to emotion, FOMO, reward
- Short, punchy sentences
- Acknowledge the fun factor

#### 3.2 Reason Persona (Angel)
**Current Tone:** Verbose, data-heavy
**Target Tone:** Concise, firm, data-driven

**Current Example:**
```
You should consider if this aligns with your goals
and whether it fits within your budget.
```

**Target Example:**
```
Stop. This exceeds your dining budget by 25%.
Save this for next month.
```

**Tone Rules:**
- Direct, no sugar-coating
- Numbers first
- Imperative language where appropriate
- Respect user's intelligence
- Focus on facts, not feelings

#### 3.3 Neutral Persona (Reflection)
**Current:** Asking neutral questions
**Target:** Thoughtful, introspective, slightly Socratic

**Example:**
```
Before you buy: Do you need this or want this?
If you regretted the last similar purchase,
what will be different this time?
```

**Tone Rules:**
- Posed as questions, not statements
- Encourage self-reflection
- Reference past behavior
- Non-judgmental
- Help user develop awareness

#### 3.4 Implementation
- [x] Update prompt templates in `Conscia.AI` project
- [x] Add intensity-aware temperature tweaking per persona:
  - Impulse: `0.65`, `0.82`, `1.0`
  - Reason: `0.18`, `0.28`, `0.42`
  - Reflection: `0.2`, `0.34`, `0.5`
- [x] Add "AI Personality Intensity" setting in Settings (mild, balanced, intense)
- [x] Thread the setting through user profile APIs and AI contexts
- [x] Add automated coverage for prompt templates, Bedrock/Ollama temperatures, and Flutter Settings updates
- [ ] Formal live transcript review across 10+ purchase scenarios remains release QA

---

## 4. Pre-Purchase Input Friction Reduction

### Current State
User must type description → enter amount → select category → submit

### Vision
Fast, intuitive input that learns from history.

### New Input Methods

#### 4.1 Quick Preset Buttons
Category quick-select buttons with emojis and amounts.

**UI:**
```
Quick Actions:
🍕 Food        🎮 Game        👕 Shopping
☕ Coffee      🎬 Entertainment
```

**Behavior:**
- Tap a preset to auto-fill category
- Shows typical spend amount (e.g., "Usually £4.50")
- User still enters custom amount if desired
- Faster for repeat purchases

#### 4.2 Voice Input
Speech-to-text for description.

**UI:**
- Microphone button next to description field
- "Say what you're buying..."
- Transcription appears in text field
- User can edit if needed

**Implementation:**
- Add `speech_to_text` package
- Request microphone permission on iOS/Android
- Fallback to manual entry if no speech detected

#### 4.3 Smart Suggestions
Suggest amounts/descriptions based on historical patterns.

**Examples:**
```
Usually coffee at Starbucks? ~£4.50 ✓
Last gaming purchase: £29.99
```

**Backend:**
- New service: `PurchaseSuggestionService`
- On category select, query merchant + amount history
- Return most common amount + date

**UI:**
- Suggestion chip below amount field
- Tap to auto-fill

#### 4.4 NFC/QR Receipt Scanning
Scan receipt QR code to auto-populate transaction.

**Flow:**
1. Tap "Scan Receipt" button
2. Camera opens (device's NFC reader or QR scanner)
3. Parse receipt data (amount, merchant, date, items)
4. Pre-fill form and let user confirm

**Implementation:**
- Add `nfc_manager` or `qr_code_scanner` package
- Link to premium receipt scanning feature (Phase 8)

---

## 5. Regret Memory System

### Current State
Implemented/evolved. Reflections are captured, regret patterns are aggregated into Dashboard/Insights, and category/merchant drilldowns now surface the user's regret memory. The original pre-purchase alert-card concept is deferred; the current MVP path uses Insights-led memory and keeps pre-purchase available as a future event/context hook.

### Vision
"Last time you spent £150 on games, you marked it 'Not worth it'"—use history to reinforce behavior change.

### Memory Features

#### 5.1 Purchase Pattern Analysis
Identify patterns of regret by merchant, amount, category, time.

**Database Table: `PurchasePatterns`**
```
user_id | category | merchant | amount_range | 
  regret_rate | sample_size | last_updated

Example:
user1 | gaming | Steam | £20-50 | 70% regret | 10 | 2026-05-03
user1 | coffee | Starbucks | £4-6 | 20% regret | 25 | 2026-05-03
```

**Backend:**
- Nightly job aggregates transaction + regret data
- Groups by category, merchant, amount buckets
- Calculates regret_rate = (regret + not_sure) / total
- Stores in `PurchasePatterns` table

#### 5.2 Pre-Purchase Memory Alerts
During pre-purchase assistant, surface relevant regret history.

**Status:** Superseded/deferred for MVP. Regret memory currently surfaces through Dashboard + Insights summary/category/merchant cards. A compact pre-purchase warning can be added later using the same `PurchasePatterns` data and the Conscience Journey event system.

**Alert Types:**

**Category Alert:**
```
⚠️ Entertainment Purchases Over £50
You've regretted 60% of these
(6 out of 10 times)
```

**Merchant Alert:**
```
⚠️ Amazon Gaming Purchases
Last 3 gaming purchases from Amazon:
- £45.99 - Regretted ❌
- £29.99 - Worth it ✅
- £59.99 - Regretted ❌
```

**Amount Threshold Alert:**
```
⚠️ Large Purchases Over £75
Your regret rate doubles above this amount
This week's biggest regret: £120
```

**Time-Based Alert:**
```
⚠️ Evening Impulse Pattern
You regret 65% of purchases made after 8 PM
This decision is at 9:15 PM
```

**Implementation:**
- Query `PurchasePatterns` table before showing AI response
- Include relevant alerts in `BudgetContextCard` on pre-purchase screen
- Option to disable memory alerts in settings (privacy)

#### 5.3 Merchant Tracking
Track spending patterns by merchant.

**Status:** Implemented/evolved through the Insights merchant list and merchant detail screens rather than a standalone dashboard merchant card.

**Dashboard Card:**
```
🏪 Your Top Merchants
Starbucks: 25 visits, 3 regrets (12%)
Amazon: 8 purchases, 6 regrets (75%) ⚠️
Tesco: 12 visits, 0 regrets ✅
```

**Features:**
- See favorite merchants (frequent, low regret)
- See problematic merchants (high regret rate)
- Set spending caps per merchant (optional)

#### 5.4 Category Consequence Tracking
Synthesize per-category insights to show long-term patterns.

**Example:**
```
📈 Entertainment Purchases
Last 30 days: £215 spent, 45% regret rate
Top regrets: Games (£120 total), Movies (£50)

If this trend continues:
- You'll spend £860 on entertainment this year
- £387 will be regretted spending

Suggestion: Set entertainment budget to £50/week
```

**Backend:**
- Calculate rolling 30/90/365-day windows
- Project annualized spending
- Estimate regretted amount
- Provide budget recommendation

---

## 6. Floating Action Button (FAB) Redesign

### Current State
Single "+" button (ambiguous—is it add expense or ask AI?)

### Vision
Clear separation of actions with quick-access menu.

### New FAB Design

#### 6.1 Primary Action: Add Transaction
- Icon: Pencil/Plus
- Color: Primary brand color
- Action: Navigate to "Add Transaction" screen

#### 6.2 Secondary Actions (Speed Dial)
Long-press or tap reveals submenu:

```
├─ Add Expense (pencil icon)
├─ Ask Conscia (sparkle/AI icon)
├─ Scan Receipt (camera icon, premium)
└─ Quick Entry (preset menu)
```

#### 6.3 Implementation
- Replace single FAB with `speed_dial_fab` package
- Add haptic feedback on action selection
- Test on different screen sizes
- Ensure accessibility (large touch targets)

---

## 7. Overall Positioning as "Financial Discipline Coach"

### Current Messaging
"Your Financial Conscience" — helpful but generic

### Target Messaging
"Your AI Financial Coach — Build Better Spending Habits"
(Position as Duolingo for money, Headspace for spending)

### Brand Updates

#### 7.1 Onboarding Messaging
Update screens to emphasize behavior change and discipline.

**New Onboarding Copy:**
```
Welcome to Conscia
Your personal AI coach for smarter spending

Like Duolingo, but for money—
build better habits, one decision at a time.

[Example: Show user making a "worth it" decision,
Conscience Progress card, weekly insight badge]
```

#### 7.2 Conscience Journey Gamification

MVP gamification should feel like progress through a playful financial conscience, not a generic streak counter. The system rewards awareness and intentionality: reflecting, pausing before purchases, acting on insights, creating budgets from nudges, and reviewing regret patterns.

**Core Loop:**
- User takes an intentional action
- App records a Conscience Journey event
- User earns XP, quest progress, badge progress, or a mascot moment
- Dashboard shows one clear next quest rather than overwhelming the user

**MVP Progression:**
- Conscience XP: earned from reflection, pre-purchase checks, budget creation from nudges, insight reviews, and regret pattern reviews
- Levels: named milestones such as "Awakening", "Impulse Spotter", "Budget Guardian", and "Conscience Captain"
- Weekly quests: 2-3 rotating goals such as "Reflect on 3 purchases", "Check before one purchase", and "Review a regret pattern"
- Badges: meaningful achievements such as "First Reflection", "Pause Before Purchase", "Budget Rescuer", "Regret Pattern Spotted", and "Worth-It Week"
- Mascot moments: small angel/devil reactions that celebrate awareness without shaming the user

**Guardrails:**
- Prefer "momentum" over harsh streak resets
- Do not reward only spending less
- Do not punish regret; regret is treated as useful signal
- Keep social sharing post-MVP unless user demand appears

#### 7.3 Habit Tracking Dashboard
New "Habits" section (or expand Dashboard) anchored by Conscience Journey:

**Elements:**
- Conscience Progress card (level, XP, momentum, active quest)
- Weekly regret % trend chart
- Category breakdown (pie chart)
- Budget adherence (progress bar)
- Projected month-end balance

#### 7.4 Social Proof & Positioning
- Update App Store description
- Update app screenshots to feature insights and Conscience Journey progress
- Marketing copy: "Join 10K+ users building healthier financial habits"
- In-app banner: "Share your achievement" (optional social sharing)

---

## 8. Technical Architecture

### Database Schema Changes

**New Tables:**

1. **WeeklyInsights**
   - `user_id` (FK)
   - `week_start_date`
   - `financial_mood` (enum: confident, balanced, cautious, impulsive)
   - `top_category` (category with most spending)
   - `biggest_regret` (transaction ID)
   - `budget_status_per_category` (JSON)
   - `created_at`
   - TTL: 12 weeks

2. **PurchasePatterns**
   - `user_id` (FK)
   - `category`
   - `merchant` (optional)
   - `amount_min`, `amount_max`
   - `regret_rate` (decimal 0-1)
   - `sample_size` (int)
   - `last_updated`
   - Index: (user_id, category, merchant)

3. **ConscienceProgress**
   - `user_id` (FK)
   - `xp_total`
   - `level_key`
   - `momentum_days`
   - `best_momentum_days`
   - `updated_at`

4. **ConscienceEvents**
   - `user_id` (FK)
   - `event_id`
   - `event_type` (reflection_completed, prepurchase_checked, budget_created_from_nudge, insight_reviewed, regret_pattern_reviewed)
   - `source_id` (idempotency source such as transaction id, budget id, insight id)
   - `xp_awarded`
   - `created_at`
   - Unique/idempotent key: `(user_id, event_type, source_id)`

5. **ConscienceBadgeProgress**
   - `user_id` (FK)
   - `badge_key`
   - `progress`
   - `target`
   - `unlocked_at` (nullable datetime)
   - Unique: `(user_id, badge_key)`

6. **ConscienceQuestProgress**
   - `user_id` (FK)
   - `week_start`
   - `quest_key`
   - `progress`
   - `target`
   - `xp_awarded`
   - `completed_at` (nullable datetime)

7. **BehavioralInsights** (optional, for caching)
   - `user_id` (FK)
   - `insight_type` (enum)
   - `data` (JSON)
   - `generated_at`
   - TTL: 24 hours

### Backend Services (New/Updated)

1. **BehavioralInsightsService**
   - `CalculateFinancialMood(userId)` → BehavioralMood
   - `GetImpsulseTrends(userId)` → List<CategoryTrend>
   - `GetWorthItCount(userId, monthYear)` → int
   - `GenerateWeeklyInsights(userId)` → WeeklyInsight

2. **PurchasePatternService**
   - `AnalyzePurchasePatterns(userId)` → List<PurchasePattern>
   - `GetRegretMemory(userId, category, merchant?, amount?)` → List<RegretWarning>
   - `GetMerchantStats(userId)` → List<MerchantStat>

3. **ConscienceJourneyService**
   - `RecordEventAsync(userId, eventType, sourceId)` → ConscienceJourneyUpdate
   - `GetJourneyAsync(userId)` → ConscienceJourneySummary
   - `EvaluateBadgesAsync(userId, event)` → List<UnlockedBadge>
   - `EvaluateWeeklyQuestsAsync(userId, event)` → List<CompletedQuest>
   - `CalculateLevel(xpTotal)` → ConscienceLevel

4. **InsightsGenerationService** (Async/Scheduled)
   - `GenerateWeeklyInsights(userId)` — runs nightly
   - `AnalyzePatternsJob()` — runs daily per all users
   - `SendWeeklyDigest(userId)` — sends Sunday 8 AM

### Frontend Providers (New/Updated)

1. `behavioral_insights_provider.dart`
   - Fetches financial mood, trends, worth-it count
   - Caches for 1 hour

2. `purchase_patterns_provider.dart`
   - Fetches regret memory alerts
   - Used in pre-purchase screen

3. `conscience_journey_provider.dart`
   - Tracks XP, levels, quests, badges, and mascot moments
   - Records journey events from reflection, pre-purchase, budget, and insights flows
   - Refreshes dashboard progress after event-producing actions

4. `weekly_insights_provider.dart`
   - Fetches cached weekly digest
   - Displays on dashboard card

### Frontend Screens (New/Updated)

1. **Enhanced Dashboard**
   - Add behavioral insight cards above budget section
   - Reorder priority: Mood → Trends → Worth It → Weekly Insights → Budgets → Transactions

2. **New "Insights" Tab** (optional)
   - Category performance breakdown
   - Merchant stats
   - Behavioral streaks
   - Achievement progress

3. **Updated Pre-Purchase Screen**
   - Add quick preset buttons above description field
   - Add voice input microphone icon
   - Add smart suggestion chips below amount
   - Add regret memory alert card before AI response
   - Add purchase pattern analysis in AI context

4. **Updated FAB**
   - Replace single FAB with SpeedDial
   - Actions: Add Expense, Ask Conscia, Scan Receipt, Quick Entry

---

## 9. Implementation Phases & Timeline

### Phase 1: Dashboard Behavioral Insights (2-3 weeks)
**Goal:** Add behavioral psychology elements to home screen

- [ ] Create `financial_mood_card.dart` widget
- [ ] Create `impulse_trends_card.dart` widget
- [ ] Create `worth_it_counter_card.dart` widget
- [ ] Create `behavioral_insights_provider.dart` (Riverpod)
- [ ] Backend: `BehavioralInsightsService` with mood/trends calculation
- [ ] Backend: New endpoint `GET /api/v1/insights/behavioral`
- [ ] Backend: `WeeklyInsights` table + seeding
- [ ] Update dashboard layout to show behavioral cards
- [ ] Design review & QA

### Phase 2: Friction Reduction (2 weeks)
**Goal:** Faster, easier transaction entry

- [ ] Add quick preset buttons to pre-purchase screen
- [ ] Add voice input integration (`speech_to_text` package)
- [ ] Create `PurchaseSuggestionService` backend
- [ ] Backend: New endpoint `GET /api/v1/suggestions/purchase`
- [ ] Implement smart suggestion chips in pre-purchase screen
- [ ] Update FAB to SpeedDial
- [ ] Mobile testing (iOS/Android microphone permissions)

### Phase 3: Regret Memory System (3 weeks)
**Goal:** Use past regrets to influence future decisions

- [ ] Create `PurchasePatterns` database table
- [ ] Backend: `PurchasePatternService` with pattern analysis
- [ ] Backend: Nightly aggregation job (Lambda + EventBridge)
- [ ] Backend: `GetRegretMemory()` service method
- [ ] Create `purchase_patterns_provider.dart`
- [ ] Add regret memory alerts to pre-purchase screen
- [ ] Add merchant tracking card to dashboard/insights tab
- [ ] Implement category consequence tracking backend service
- [ ] Privacy: Add settings toggle for memory alerts

### Phase 4: AI Personality Refinement (1-2 weeks)
**Goal:** Distinct, memorable personas

**Status:** Implemented/evolved as AI Personality + Visual Refresh.

- [x] Update Impulse persona prompts (playful/tempting, with safer guardrails than the original FOMO/emojis concept)
- [x] Update Reason persona prompts (firm/concise)
- [x] Update Neutral persona prompts into Reflection voice
- [x] Adjust temperature per persona and intensity
- [x] Add AI personality intensity setting in Settings
- [x] UX/product review: Confirm tone differentiation direction
- [ ] Formal live-model testing across 10+ purchase scenarios remains release QA

### Phase 5: Conscience Journey Gamification (2 weeks)
**Goal:** Playful habit progression through XP, levels, weekly quests, badges, and mascot moments.

- [ ] Create Conscience Progress/Event/Badge/Quest storage
- [ ] Backend: `ConscienceJourneyService` with idempotent event recording
- [ ] Backend: `GET /api/v1/conscience-journey`
- [ ] Backend: `POST /api/v1/conscience-journey/events`
- [ ] Create `conscience_journey_provider.dart`
- [ ] Add Conscience Progress card to dashboard
- [ ] Add Conscience Journey detail screen
- [ ] Implement unlock/moment bottom sheet
- [ ] Add story-demo seed data for XP, quests, badges, and mascot moments

### Phase 6: Weekly Digest (2 weeks)
**Goal:** Email/push notifications with insights

- [ ] Create weekly insights generation backend service
- [ ] Set up Firebase Cloud Messaging integration (backend)
- [ ] Backend: EventBridge rule for Sunday 8 AM send
- [ ] Backend: Digest generation Lambda
- [ ] Update mobile app to handle push notifications
- [ ] Flutter: `firebase_messaging` package integration
- [ ] Design digest template (push + in-app preview)
- [ ] User timezone handling for send time

### Phase 7: New Insights Tab (2 weeks)
**Goal:** Dedicated analytics dashboard

- [ ] Design Insights screen layout (category breakdown, merchant stats, streaks)
- [ ] Implement category performance card
- [ ] Implement merchant tracking widget
- [ ] Implement behavioral insights summary
- [ ] Add date range filters (week/month/year)
- [ ] Integration with existing providers
- [ ] Mobile testing & polish

### Phase 8: Positioning & Branding (1 week)
**Goal:** Update messaging across app

- [ ] Update onboarding copy
- [ ] Update App Store description
- [ ] Update app screenshots (highlight insights/streaks)
- [ ] In-app copy updates ("Your AI Financial Coach")
- [ ] Achievement unlock copy
- [ ] Settings & tutorial updates

**Total Estimated Time: 16-20 weeks (4-5 months)**

---

## 10. Success Metrics

### Engagement Metrics
- Daily active users (DAU) increase by 25%
- Time on app increase (especially dashboard)
- Frequency of pre-purchase AI checks

### Behavior Change Metrics
- Average regret rate per category trending down
- Budget adherence improving (% within budget)
- Streak participation (% of users with active streaks)

### Retention Metrics
- 30-day retention improvement
- Monthly active users (MAU) growth
- Reduced churn

### Feature Adoption
- % of users viewing behavioral insights
- % of users achieving first streak
- % of users unlocking achievements
- Click-through rate on memory alerts

---

## 11. Future Enhancements (Post-MVP)

- AI learning per user (personality adaptation)
- Social leaderboards (anonymous challenges)
- Smart budget recommendations based on behavior
- Location-based spending alerts
- Time-of-day impulse patterns
- Peer comparison (anonymized)
- Habit stacking (linking spending goals to other habits)
- Integration with calendar (avoid spending on specific dates/events)
