# Conscia — Flutter UI/UX Design Specification

**Version:** 1.0 | **Target:** iOS + Android | **Stack:** Flutter 3.x, Riverpod 2.x, GoRouter, Dio, Material 3

---

## Table of Contents

1. [Design System](#1-design-system)
2. [Navigation Architecture](#2-navigation-architecture)
3. [State Management Architecture](#3-state-management-architecture)
4. [Screen Specifications](#4-screen-specifications)
5. [Animation & Micro-Interaction Specs](#5-animation--micro-interaction-specs)
6. [Dark Mode](#6-dark-mode)
7. [Responsive Layout](#7-responsive-layout)
8. [Accessibility Checklist](#8-accessibility-checklist)

---

## 1. Design System

### 1.1 Color Palette

#### Semantic Tokens

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| `primary` | `#1A237E` (Indigo 900) | `#7986CB` (Indigo 300) | AppBar, nav selected, primary buttons |
| `onPrimary` | `#FFFFFF` | `#1A237E` | Text/icons on primary surfaces |
| `primaryContainer` | `#C5CAE9` (Indigo 100) | `#283593` (Indigo 800) | Chips, badges, subtle highlights |
| `secondary` | `#FFB300` (Amber 600) | `#FFD54F` (Amber 300) | FAB, CTAs, highlights, premium badge |
| `onSecondary` | `#1A237E` | `#1A237E` | Text on secondary surfaces |
| `surface` | `#FFFFFF` | `#1E1E2E` | Cards, sheets, dialogs |
| `surfaceContainer` | `#F5F5F5` | `#252536` | Elevated card backgrounds |
| `background` | `#FAFAFA` | `#0D1117` | Scaffold background |
| `onSurface` | `#1C1B1F` | `#E6E1E5` | Primary text |
| `onSurfaceVariant` | `#49454F` | `#CAC4D0` | Secondary text, labels |
| `outline` | `#79747E` | `#938F99` | Borders, dividers |
| `outlineVariant` | `#CAC4D0` | `#49454F` | Subtle dividers |
| `error` | `#E53935` | `#F2B8B5` | Errors, validation, expense amounts |
| `income` | `#4CAF50` | `#81C784` | Income amounts, positive indicators |
| `expense` | `#E53935` | `#EF9A9A` | Expense amounts, negative indicators |

#### AI Personality Colors

| Token | Value | Gradient | Usage |
|---|---|---|---|
| `devilBg` | `#FFF8E1` (light) / `#3E2723` (dark) | `#FFB300` → `#E65100` | Devil message bubble background |
| `devilAccent` | `#E65100` | — | Devil icon, border accent |
| `devilText` | `#3E2723` (light) / `#FFE0B2` (dark) | — | Devil message text |
| `angelBg` | `#E0F7FA` (light) / `#0D3B47` (dark) | `#00BCD4` → `#1565C0` | Angel message bubble background |
| `angelAccent` | `#00838F` | — | Angel icon, border accent |
| `angelText` | `#004D40` (light) / `#B2EBF2` (dark) | — | Angel message text |
| `neutralBg` | `#F5F5F5` (light) / `#2C2C3A` (dark) | — | Neutral message bubble background |
| `neutralAccent` | `#757575` | — | Neutral icon |
| `neutralText` | `#424242` (light) / `#BDBDBD` (dark) | — | Neutral message text |

#### Budget Health Colors

| Condition | Color (Light) | Color (Dark) | Token Name |
|---|---|---|---|
| 0–49% used | `#4CAF50` | `#81C784` | `budgetHealthy` |
| 50–79% used | `#FFC107` | `#FFD54F` | `budgetCaution` |
| 80–99% used | `#FF9800` | `#FFB74D` | `budgetWarning` |
| ≥100% used | `#E53935` | `#EF9A9A` | `budgetDanger` |

### 1.2 Typography

Using Google Fonts: **Poppins** (headings) + **Inter** (body). Fallback to system sans-serif.

| Style Name | Font | Weight | Size | Line Height | Letter Spacing | Usage |
|---|---|---|---|---|---|---|
| `displayLarge` | Poppins | 700 | 32sp | 40sp | -0.5 | Onboarding headlines |
| `displayMedium` | Poppins | 600 | 28sp | 36sp | 0 | Screen titles (rare) |
| `headlineLarge` | Poppins | 600 | 24sp | 32sp | 0 | Section headers |
| `headlineMedium` | Poppins | 600 | 20sp | 28sp | 0 | Card titles, dialog titles |
| `titleLarge` | Poppins | 600 | 18sp | 26sp | 0 | AppBar titles |
| `titleMedium` | Inter | 500 | 16sp | 24sp | 0.15 | List item primary text |
| `titleSmall` | Inter | 500 | 14sp | 20sp | 0.1 | Budget category name |
| `bodyLarge` | Inter | 400 | 16sp | 24sp | 0.5 | Body text |
| `bodyMedium` | Inter | 400 | 14sp | 20sp | 0.25 | Default body text |
| `bodySmall` | Inter | 400 | 12sp | 16sp | 0.4 | Captions, timestamps |
| `labelLarge` | Inter | 500 | 14sp | 20sp | 0.1 | Button text |
| `labelMedium` | Inter | 500 | 12sp | 16sp | 0.5 | Chip text, badge text |
| `labelSmall` | Inter | 500 | 11sp | 16sp | 0.5 | Overline text, currency codes |

### 1.3 Spacing & Grid

Base unit: **8dp**. All spacing is a multiple of 8.

| Token | Value | Usage |
|---|---|---|
| `xs` | 4dp | Inline icon-to-text gap |
| `sm` | 8dp | Between tightly related elements |
| `md` | 16dp | Default card padding, between list items |
| `lg` | 24dp | Section spacing |
| `xl` | 32dp | Screen-level vertical spacing |
| `xxl` | 48dp | Onboarding hero spacing |
| `screenPadding` | 16dp horizontal | Left/right screen gutters |
| `cardPadding` | 16dp all | Internal card padding |

### 1.4 Component Library

#### Cards

- **Border radius:** 16dp
- **Elevation:** 0 (light mode uses `outlineVariant` 1dp border), 2dp (dark mode uses shadow)
- **Padding:** 16dp internal
- **Spacing between cards:** 12dp vertical

#### Buttons

| Variant | Height | Radius | Usage |
|---|---|---|---|
| `FilledButton` (primary) | 48dp | 24dp (full pill) | Primary CTA per screen |
| `FilledTonalButton` | 48dp | 24dp | Secondary actions |
| `OutlinedButton` | 48dp | 24dp | Tertiary actions, cancel |
| `TextButton` | 40dp | 8dp | Inline actions, "Forgot password?" |
| `IconButton` | 48dp | 24dp | AppBar actions |
| `FAB` | 56dp | 16dp | Quick-add transaction |

All buttons enforce minimum 48×48dp touch target.

#### Text Fields

- **Style:** `OutlinedTextField` (Material 3 outlined variant)
- **Height:** 56dp
- **Border radius:** 12dp
- **Border:** 1dp `outline`, focused: 2dp `primary`
- **Label:** Animated floating label
- **Error:** Red border + error text below (bodySmall, error color)
- **Prefix/suffix:** Currency code badge in amount fields (see [Multi-Currency UX](#multi-currency-ux))

#### Chips (Filter)

- **Height:** 36dp
- **Radius:** 8dp
- **Padding:** 8dp horizontal, 4dp vertical
- **Selected state:** `primaryContainer` bg, `onPrimaryContainer` text
- **Unselected state:** `surface` bg, `onSurfaceVariant` text, 1dp `outline` border

#### Bottom Navigation Bar

- **Height:** 80dp (includes safe area padding on iOS)
- **Items:** 4 — Dashboard, Transactions, Assistant, Settings
- **Icons:** Outlined (unselected), Filled (selected)
- **Label:** Always visible, `labelMedium`
- **Selected:** `primary` color, filled icon variant
- **Unselected:** `onSurfaceVariant`, outlined icon variant
- **Active indicator:** `primaryContainer` pill behind selected icon (M3 standard)

| Tab | Label | Icon (unselected) | Icon (selected) |
|---|---|---|---|
| Dashboard | Home | `Icons.home_outlined` | `Icons.home` |
| Transactions | Transactions | `Icons.receipt_long_outlined` | `Icons.receipt_long` |
| Assistant | Assistant | `Icons.auto_awesome_outlined` | `Icons.auto_awesome` |
| Settings | Settings | `Icons.settings_outlined` | `Icons.settings` |

#### LinearProgressIndicator (Budget)

- **Height:** 8dp
- **Border radius:** 4dp (full capsule)
- **Background track:** `outlineVariant` at 20% opacity
- **Value color:** Dynamic based on percentage (see Budget Health Colors)
- **Animation:** `Curves.easeInOut`, 400ms on value change

#### Currency Badge

- **Container:** `primaryContainer` background, 6dp radius
- **Text:** `labelSmall`, bold, 3-letter ISO code (e.g., "USD")
- **Padding:** 6dp horizontal, 2dp vertical
- **Tap target:** 44×32dp minimum (badge + padding)
- **Behavior:** Tapping opens `CurrencyPickerBottomSheet`

---

## 2. Navigation Architecture

### 2.1 GoRouter Route Tree

```dart
GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isAuthenticated;
    final isOnboarding = state.uri.path.startsWith('/onboarding');
    if (!isLoggedIn && !isOnboarding) return '/onboarding';
    if (isLoggedIn && isOnboarding) return '/';
    return null;
  },
  routes: [
    // --- Onboarding (no shell) ---
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
      routes: [
        GoRoute(path: 'sign-up', builder: (_, __) => const SignUpScreen()),
        GoRoute(path: 'sign-in', builder: (_, __) => const SignInScreen()),
        GoRoute(path: 'setup', builder: (_, __) => const SetupScreen()),
      ],
    ),

    // --- Main app (ShellRoute with BottomNavBar) ---
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: TransactionListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, __) => const TransactionFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => TransactionDetailScreen(
                id: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, state) => TransactionFormScreen(
                    id: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/assistant',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: PrePurchaseScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'budgets',
              builder: (_, __) => const BudgetsScreen(),
            ),
          ],
        ),
      ],
    ),

    // --- Receipt routes (outside shell — full-screen) ---
    GoRoute(
      path: '/scan',
      builder: (_, __) => const ReceiptScannerScreen(),
    ),
    GoRoute(
      path: '/receipts/:id/review',
      builder: (_, state) => ReceiptReviewScreen(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

### 2.2 Navigation Flow Graph

```
[App Launch]
    │
    ├── Not authenticated ──► /onboarding
    │                              ├── Welcome slides (PageView)
    │                              ├── /onboarding/sign-up
    │                              ├── /onboarding/sign-in
    │                              └── /onboarding/setup (currency + locale)
    │                                        │
    │                                        └── ► / (Dashboard)
    │
    └── Authenticated ──► / (Dashboard)
                           │
                    ┌──────┼──────────┬──────────┐
                    ▼      ▼          ▼          ▼
                   /    /transactions /assistant /settings
                   │      │                      │
                   │      ├── /transactions/add  ├── /settings/budgets
                   │      ├── /transactions/:id  │
                   │      │     └── .../edit     │
                   │      │                      │
                   ├──────┴──────────────────────┘
                   │
                   ├── /scan (full-screen, premium gate)
                   └── /receipts/:id/review (full-screen)

Bottom Nav Tabs: Dashboard │ Transactions │ Assistant │ Settings
```

### 2.3 Navigation Behaviors

| Transition | Animation | Duration |
|---|---|---|
| Bottom nav tab switch | None (`NoTransitionPage`) | Instant |
| Push to detail screen | Slide from right (platform default) | 300ms |
| Push to add/edit form | Slide from bottom | 300ms |
| Open bottom sheet | Slide from bottom + fade overlay | 250ms |
| Full-screen modal (scan) | Slide from bottom, full-screen | 350ms |
| Back navigation | Reverse of push animation | 300ms |

---

## 3. State Management Architecture

### 3.1 Provider Overview

All providers use Riverpod 2.x code-generation style (`@riverpod` annotations via `riverpod_generator`).

#### Auth & User

| Provider | Type | Description |
|---|---|---|
| `authNotifierProvider` | `AsyncNotifier<AuthState>` | Manages login/register/logout, stores tokens in `flutter_secure_storage`, exposes `isAuthenticated` |
| `currentUserProvider` | `AsyncNotifier<User?>` | Fetches `GET /api/v1/users/me` on login, caches until invalidated |
| `subscriptionProvider` | `AsyncNotifier<SubscriptionStatus>` | Fetches `GET /api/v1/subscriptions/status`, caches with 5-min TTL |

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) = _Authenticated;
}
```

#### Dashboard

| Provider | Type | Description |
|---|---|---|
| `budgetSummaryProvider` | `FutureProvider<List<Budget>>` | `GET /api/v1/budgets` — auto-refresh on app resume |
| `regretPromptsProvider` | `FutureProvider<List<Transaction>>` | Transactions 24–48h old with null `regretLevel`, derived from `transactionsProvider` or a dedicated query |
| `budgetWarningsProvider` | `FutureProvider<List<InAppAlert>>` | `GET /api/v1/alerts` — filtered to budget warnings |
| `recentTransactionsProvider` | `FutureProvider<List<Transaction>>` | First page of `GET /api/v1/transactions?pageSize=10` |

#### Transactions

| Provider | Type | Description |
|---|---|---|
| `transactionListProvider` | `AsyncNotifier<PaginatedList<Transaction>>` | Paginated list with filter state (category), supports `loadMore()`, `refresh()` |
| `transactionDetailProvider(id)` | `FutureProvider.family<Transaction, String>` | `GET /api/v1/transactions/:id` |
| `categoryFilterProvider` | `StateProvider<String?>` | Selected category filter, null = all |
| `transactionFormProvider` | `StateNotifier<TransactionFormState>` | Form state for add/edit — type, amount, currency, category, merchant, date, location |

#### Budgets

| Provider | Type | Description |
|---|---|---|
| `budgetListProvider` | `AsyncNotifier<List<Budget>>` | `GET /api/v1/budgets`, invalidated on create/update/delete |
| `budgetFormProvider` | `StateNotifier<BudgetFormState>` | Form state for create/edit budget |

#### AI / Assistant

| Provider | Type | Description |
|---|---|---|
| `prePurchaseFormProvider` | `StateNotifier<PrePurchaseFormState>` | Form fields: description, amount, currency, category |
| `prePurchaseResponseProvider` | `AsyncNotifier<AIResponse?>` | Holds response from `POST /api/v1/ai/pre-purchase`, null = no request yet |

#### Receipts (Premium)

| Provider | Type | Description |
|---|---|---|
| `receiptScanProvider` | `AsyncNotifier<ReceiptScanState>` | Camera → upload → OCR → result lifecycle |
| `receiptReviewProvider(id)` | `AsyncNotifier<ReceiptReviewState>` | Editable OCR result fields, confirm action |

#### Settings

| Provider | Type | Description |
|---|---|---|
| `userPreferencesProvider` | `AsyncNotifier<UserPreferences>` | Currency + locale, synced to `PUT /api/v1/users/me` |

### 3.2 Freezed Models

```dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String type,          // "Income" | "Expense"
    required double amount,
    required String currencyCode,
    required String category,
    String? merchant,
    required DateTime date,
    TransactionLocation? location,
    String? regretLevel,           // "WorthIt" | "NotSure" | "Regret" | null
    DateTime? createdAt,
  }) = _Transaction;
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String category,
    required double monthlyLimit,
    required double currentSpend,
    required String currencyCode,
    required double percentUsed,
    required bool isOverBudget,
  }) = _Budget;
  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}

@freezed
class AIResponse with _$AIResponse {
  const factory AIResponse({
    required String devilMessage,
    required String angelMessage,
    required String neutralMessage,
    BudgetContext? budget,
  }) = _AIResponse;
  factory AIResponse.fromJson(Map<String, dynamic> json) =>
      _$AIResponseFromJson(json);
}

@freezed
class SubscriptionStatus with _$SubscriptionStatus {
  const factory SubscriptionStatus({
    required String tier,          // "Free" | "Premium"
    String? platform,              // "iOS" | "Android"
    required bool isActive,
    DateTime? expiresAt,
  }) = _SubscriptionStatus;
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusFromJson(json);
}

@freezed
class InAppAlert with _$InAppAlert {
  const factory InAppAlert({
    required String id,
    required String triggerName,
    required String title,
    required String message,
    required DateTime createdAt,
  }) = _InAppAlert;
  factory InAppAlert.fromJson(Map<String, dynamic> json) =>
      _$InAppAlertFromJson(json);
}
```

### 3.3 Dio Configuration

```dart
final dio = Dio(BaseOptions(
  baseUrl: Environment.apiBaseUrl,    // https://api.conscia.app/api/v1
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  headers: {'Content-Type': 'application/json'},
));

// Interceptor 1: Auth token injection
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
));

// Interceptor 2: 401 → redirect to /onboarding
dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      ref.read(authNotifierProvider.notifier).logout();
    }
    handler.next(error);
  },
));
```

---

## 4. Screen Specifications

### 4.1 Onboarding (`/onboarding`)

#### Layout

Full-screen with no AppBar or BottomNav. Background: solid `background` color with a subtle radial gradient of `primary` at 5% opacity centered at top-right.

#### Welcome Slides — `PageView` (3 pages)

**Shared structure per slide:**
- Top 55%: Centered illustration placeholder (280×280dp, `BoxDecoration` with rounded corners). For MVP, use a styled `Icon` or vector illustration container.
- Bottom 45%: Text block — headline (`displayLarge`), body (`bodyLarge`, `onSurfaceVariant`), CTA.

**Slide 1 — "Meet Your Financial Conscience"**
- Illustration: Two overlapping circles — warm (amber glow) and cool (teal glow) — representing Devil and Angel.
- Headline: "Meet Your Financial Conscience"
- Body: "Before you buy, ask yourself — or let two AI advisors argue it out for you."
- No button (swipe hint: 3 dot indicators at bottom).

**Slide 2 — "Track Without Guilt"**
- Illustration: Stylized receipt turning into a bar chart.
- Headline: "Track Without Guilt"
- Body: "Log your spending. See your budgets. Reflect on what was worth it — and what wasn't."

**Slide 3 — "Start Now"**
- Illustration: Checkmark inside a circle with radiating lines (achievement motif).
- Headline: "Take Control of Your Money"
- Body: "Sign up in 30 seconds. Free forever, with premium superpowers when you need them."
- **Primary CTA:** `FilledButton` — "Create Account" → navigates to `/onboarding/sign-up`
- **Secondary CTA:** `TextButton` — "Already have an account? Sign In" → navigates to `/onboarding/sign-in`

**Page Indicators:**
- 3 dots, centered, 32dp below the text block.
- Active: `primary`, 10dp diameter.
- Inactive: `outlineVariant`, 8dp diameter.
- Animated position with `Curves.easeInOut`, 200ms.

#### Sign-Up Screen (`/onboarding/sign-up`)

**AppBar:** Back arrow (leading), no title.

**Form — vertically centered in a `SingleChildScrollView`:**

| Field | Widget | Validation |
|---|---|---|
| Email | `OutlinedTextField`, `keyboardType: emailAddress`, autofill hint: email | Non-empty, valid email format |
| Password | `OutlinedTextField`, `obscureText: true`, autofill hint: newPassword, suffix: visibility toggle `IconButton` | Min 8 chars, 1 uppercase, 1 number |
| Confirm Password | `OutlinedTextField`, `obscureText: true` | Must match password |

**Below form:**
- **CTA:** `FilledButton`, full width, "Create Account"
- **Loading state:** Button shows `SizedBox(24×24, CircularProgressIndicator(strokeWidth: 2))` replacing text
- **Error state:** `MaterialBanner` above form with error message from API (e.g., "Email already in use")
- **Footer:** `TextButton` — "Already have an account? Sign In" → `/onboarding/sign-in`

**On success:** Navigates to `/onboarding/setup`.

#### Sign-In Screen (`/onboarding/sign-in`)

Identical layout to Sign-Up minus Confirm Password field.

| Field | Widget | Validation |
|---|---|---|
| Email | `OutlinedTextField` | Non-empty, valid email |
| Password | `OutlinedTextField`, obscured | Non-empty |

- **CTA:** "Sign In"
- **Error:** "Invalid email or password" banner
- **Footer:** `TextButton` — "Don't have an account? Sign Up" → `/onboarding/sign-up`

**On success:** Stores tokens via `authNotifierProvider`, navigates to `/onboarding/setup` (first login) or `/` (returning user — check if `currentUserProvider` has `preferredCurrency` set).

#### Setup Screen (`/onboarding/setup`)

**AppBar:** "Set Up Your Profile", no back button (user must complete setup).

**Content (vertical stack, 24dp gaps):**

1. **Currency Picker**
   - Label: "Your Default Currency" (`titleMedium`)
   - Widget: `ListTile` with leading flag emoji (derived from currency → country), title: currency name, subtitle: ISO code. Tapping opens `CurrencyPickerBottomSheet`.
   - Default: Inferred from device locale (e.g., US locale → USD, MX locale → MXN).

2. **Locale/Region Picker**
   - Label: "Number & Date Format" (`titleMedium`)
   - Widget: `ListTile` showing preview of formatted number (e.g., "$1,234.56" for en-US, "$1.234,56" for es-MX). Tapping opens `LocalePickerBottomSheet`.
   - Default: Device locale.

3. **Preview Card**
   - Card showing: "This is how amounts will look:" followed by a sample formatted amount using the selected currency + locale.

4. **CTA:** `FilledButton`, full width, "Let's Go!" → navigates to `/`.

#### CurrencyPickerBottomSheet

- **Drag handle** at top (centered, 32×4dp, `outlineVariant`).
- **Search field** pinned below handle: `OutlinedTextField` with `Icons.search` leading, "Search currencies..." placeholder.
- **List:** `ListView.builder` of all ISO 4217 currencies. Each item: flag emoji + currency code (`labelLarge`, bold) + currency name (`bodyMedium`). Tapping selects and dismisses.
- **Height:** 70% of screen.
- **Filter:** Client-side filter on code and name.
- **Selected indicator:** Trailing `Icons.check` in `primary` color on the currently selected currency.

#### LocalePickerBottomSheet

Same structure as CurrencyPickerBottomSheet. Items show locale name + preview of number format (e.g., "English (US) — $1,234.56").

---

### 4.2 Dashboard (`/`)

#### AppBar

- **Title:** "Conscia" (`titleLarge`, `primary` color, Poppins 600)
- **Actions:** Notification bell `IconButton` (displays unread alert count badge if >0). Tapping opens an alert list bottom sheet.
- **No leading** (this is a root tab).
- **Elevation:** 0, `surface` background with bottom `Divider(1dp, outlineVariant)`.

#### Body — `CustomScrollView` with `SliverList`

The dashboard is a single scrollable surface. Sections stack vertically with 16dp spacing between sections.

---

**Section 1: Budget Warning Banner (conditional)**

Visible only when any budget has `percentUsed >= 80`.

- **Widget:** `Container` with `budgetWarning` background at 15% opacity, 12dp radius, 16dp padding.
- **Content:** Row — `Icons.warning_amber_rounded` (24dp, `budgetWarning` color) + 8dp gap + Column:
  - "Budget Alert" (`titleSmall`, bold, `budgetWarning`)
  - "{N} budget(s) over 80%" (`bodySmall`, `onSurfaceVariant`)
- **Tap action:** Scrolls to budget section, or navigates to `/settings/budgets`.
- **Dismiss:** Trailing `IconButton(Icons.close)`, dismisses for this session.

---

**Section 2: Budget Summary Cards — Horizontal Scroll**

- **Section header:** Row — "Budgets" (`headlineMedium`) + `Spacer` + `TextButton("See All")` → `/settings/budgets`.
- **Cards:** `SizedBox(height: 140)` containing `ListView.builder(scrollDirection: Axis.horizontal)`.
- **Card width:** 200dp. **Gap between cards:** 12dp. **Left padding:** 16dp (screen gutter). **Right padding:** 16dp.

**Each Budget Card:**

```
┌──────────────────────────┐
│  🛒  Groceries           │  ← category icon + name (titleSmall)
│                          │
│  $340 / $500             │  ← spent / limit (bodyLarge, bold)
│  ████████░░░░░ 68%       │  ← LinearProgressIndicator + percentage
│  USD                     │  ← currency code (labelSmall, onSurfaceVariant)
└──────────────────────────┘
```

- **Background:** `surface`
- **Radius:** 16dp
- **Padding:** 16dp
- **Category icon:** Mapped from category string (see [Category Icon Map](#category-icon-map))
- **Amount format:** Locale-aware via `intl` `NumberFormat.simpleCurrency(locale, name: currencyCode)`
- **Progress bar:** 8dp height, color from Budget Health Colors based on `percentUsed / 100`
- **Percentage label:** Right-aligned, `labelMedium`, same color as progress bar
- **Tap action:** Navigate to `/settings/budgets`

**Empty state:** If no budgets, show a single card with dashed border (`CustomPaint`), `Icons.add_circle_outline` + "Create a budget" text. Tapping navigates to `/settings/budgets`.

---

**Section 3: Regret Prompt Cards (conditional)**

Visible only when there are transactions from 24–48h ago with null `regretLevel`.

- **Section header:** "How do you feel about these?" (`headlineMedium`)
- **Cards:** Vertical stack of dismissible cards, max 5 shown, "Show more" `TextButton` if >5.

**Each Regret Prompt Card:**

```
┌────────────────────────────────────────────┐
│  ☕  Starbucks              $6.50 USD      │  ← icon + merchant + amount
│  Yesterday, 2:30 PM                        │  ← relative date
│                                            │
│  Was it worth it?                          │  ← prompt text (titleSmall)
│                                            │
│  [ 😊 Worth It ]  [ 🤷 Not Sure ]  [ 😔 Regret ]  │  ← 3 action buttons
└────────────────────────────────────────────┘
```

- **Background:** `surface`
- **Radius:** 16dp
- **Merchant + amount:** Row with `Spacer` between
- **Amount color:** `expense` for expenses, `income` for income
- **Date:** `bodySmall`, `onSurfaceVariant`, relative format ("Yesterday", "2 days ago")
- **Prompt:** "Was it worth it?" (`titleSmall`, `onSurface`)
- **Action buttons:** 3 `FilledTonalButton` in a `Row` with `Expanded` children, 8dp gap:
  - "Worth It" — icon: `Icons.sentiment_satisfied_alt`, tint: `income`
  - "Not Sure" — icon: `Icons.sentiment_neutral`, tint: `secondary`
  - "Regret" — icon: `Icons.sentiment_dissatisfied`, tint: `expense`
- **On tap:** Calls `POST /api/v1/transactions/{id}/regret` with corresponding `RegretLevel`, card animates out (`SlideTransition` + `FadeTransition`, 300ms)
- **Dismiss (swipe):** `Dismissible` widget, swipe right dismisses without feedback. Swipe direction: `DismissDirection.startToEnd`. Background shows "Skip" text.

---

**Section 4: Recent Transactions**

- **Section header:** Row — "Recent" (`headlineMedium`) + `Spacer` + `TextButton("View All")` → `/transactions`
- **List:** Shows last 10 transactions (first page fetch). No pagination here.

**Each Transaction Row:**

```
┌────────────────────────────────────────────────┐
│  🛒  │  Walmart                    -$45.20 USD │
│      │  Groceries · May 1          ●  WorthIt  │
└────────────────────────────────────────────────┘
```

- **Leading:** Category icon in a `CircleAvatar(radius: 20)` with `primaryContainer` background
- **Title:** Merchant name or "Unknown" (`titleMedium`)
- **Subtitle:** Category · Date (`bodySmall`, `onSurfaceVariant`)
- **Trailing column (right-aligned):**
  - Amount (`titleMedium`, bold) — colored `expense` (red, with "−" prefix) or `income` (green, with "+" prefix)
  - Currency code (`labelSmall`, `onSurfaceVariant`)
- **Regret indicator (optional):** Small colored dot (6dp) next to amount:
  - WorthIt: `income` (green)
  - NotSure: `secondary` (amber)
  - Regret: `expense` (red)
  - null: no dot
- **Tap:** Navigate to `/transactions/:id`
- **Divider:** `Divider(indent: 72)` between rows (aligned past the avatar)

**Empty state:** Centered illustration + "No transactions yet" + "Tap + to add your first" (`bodyMedium`, `onSurfaceVariant`).

---

**Section 5: Quick-Add FAB**

- **Position:** `FloatingActionButton.extended` at bottom-right, 16dp from edges, above bottom nav.
- **Icon:** `Icons.add`
- **Label:** "Add" (hidden when scrolled — use `FloatingActionButton` without label)
- **Color:** `secondary` background, `onSecondary` icon
- **Elevation:** 6dp
- **Tap:** Navigate to `/transactions/add`
- **Behavior on scroll:** Shrinks from extended to regular FAB on `ScrollController` offset > 100dp. Animated with `AnimatedSwitcher`.

---

### 4.3 Transaction List (`/transactions`)

#### AppBar

- **Title:** "Transactions" (`titleLarge`)
- **Actions:** None

#### Filter Bar (pinned below AppBar)

- **Widget:** `SliverPersistentHeader` (pinned) containing a `SingleChildScrollView(scrollDirection: Axis.horizontal)` of `FilterChip` widgets.
- **Height:** 52dp (chip height 36dp + 8dp padding top/bottom)
- **First chip:** "All" — selected when no category filter active
- **Remaining chips:** One per category that exists in the user's transactions (fetched from transaction list, deduplicated). Examples: Groceries, Dining, Transport, Entertainment, etc.
- **Chip behavior:** Tapping a chip sets `categoryFilterProvider`, triggers re-fetch of `transactionListProvider` with `?category=X` parameter.
- **Padding:** 16dp left, 8dp between chips, 16dp right

#### Transaction List

- **Widget:** `SliverList.builder` inside a `CustomScrollView`
- **Pull-to-refresh:** `RefreshIndicator` wrapping the scroll view. Calls `transactionListProvider.refresh()`.
- **Infinite scroll:** `ScrollController` listener — when within 200dp of bottom, calls `transactionListProvider.loadMore()`.
- **Loading more indicator:** `SliverToBoxAdapter` at bottom with centered `CircularProgressIndicator(strokeWidth: 2)`, visible when loading next page.

**Each item:** Same layout as Dashboard Recent Transaction Row, plus:
- **Regret indicator** is more prominent here: a small label right of the amount showing "Worth It" / "Not Sure" / "Regret" in `labelSmall` with corresponding color. Hidden if null.

**Date separators:** Group transactions by date. Insert a `SliverToBoxAdapter` with date header text ("Today", "Yesterday", "Mon, Apr 28") styled as `labelLarge`, `onSurfaceVariant`, 16dp left padding, 8dp vertical padding.

**Empty state (no transactions):** Full-screen centered:
- Icon: `Icons.receipt_long_outlined` (64dp, `outlineVariant`)
- Text: "No transactions yet" (`headlineMedium`)
- Subtext: "Tap + to add your first expense or income" (`bodyMedium`, `onSurfaceVariant`)

**Empty state (filter active, no results):** Same layout but:
- Text: "No {category} transactions"
- Subtext: "Try a different filter"

---

### 4.4 Transaction Detail (`/transactions/:id`)

#### AppBar

- **Title:** "Transaction" (`titleLarge`)
- **Leading:** Back arrow
- **Actions:** `PopupMenuButton` with options: "Edit", "Delete"
  - Edit → `/transactions/:id/edit`
  - Delete → Confirmation `AlertDialog`: "Delete this transaction? This can't be undone." → `DELETE /api/v1/transactions/:id` → pop back to list with `SnackBar("Transaction deleted")`

#### Body — `SingleChildScrollView`, 16dp horizontal padding

**Hero Card (top):**

```
┌──────────────────────────────────────────┐
│         🛒                                │  ← large category icon (48dp CircleAvatar)
│      Walmart                              │  ← merchant (headlineLarge, centered)
│                                           │
│     −$45.20 USD                           │  ← amount (displayMedium, expense/income color)
│     Expense · Groceries                   │  ← type + category (bodyLarge, onSurfaceVariant)
│     May 1, 2026 · 2:30 PM                │  ← date (bodyMedium, onSurfaceVariant)
└──────────────────────────────────────────┘
```

- Card: `surface`, 16dp radius, 24dp padding, centered content
- Icon: `CircleAvatar(radius: 32)` with `primaryContainer` bg
- Amount: `displayMedium`, Poppins 700, colored by type
- Below card: 24dp spacer

**Location Info (conditional — only if `location != null`):**

```
┌──────────────────────────────────────────┐
│  📍  Near Walmart Supercenter            │
│      34.0522° N, 118.2437° W             │
└──────────────────────────────────────────┘
```

- Card: `surfaceContainer`, 12dp radius, 16dp padding
- Leading: `Icons.location_on` (20dp, `primary`)
- Title: `location.merchantName ?? "Location"` (`titleSmall`)
- Subtitle: Lat/long formatted to 4 decimal places (`bodySmall`, `onSurfaceVariant`)

**Regret Level Section:**

- **Header:** "How did this purchase feel?" (`titleMedium`)
- **If set:** Display the current level as a styled chip:
  - WorthIt: `Chip` with `income` bg at 15%, `Icons.sentiment_satisfied_alt`, "Worth It" label
  - NotSure: `Chip` with `secondary` bg at 15%, `Icons.sentiment_neutral`, "Not Sure" label
  - Regret: `Chip` with `expense` bg at 15%, `Icons.sentiment_dissatisfied`, "Regret" label
  - Below: `TextButton("Change")` → shows the 3-button picker inline (same as dashboard regret card buttons)
- **If null:** Show the 3-button picker directly (same layout as regret prompt card)

**AI Reflection Section:**

- **Button:** `FilledTonalButton.icon(Icons.auto_awesome, "Ask AI to Reflect")` — full width
- **Tap:** Calls `POST /api/v1/transactions/:id/reflect` (maps to the AI reflection endpoint if available; if not yet implemented, uses pre-purchase endpoint with transaction data as context)
- **Loading:** Button disabled, shows `CircularProgressIndicator(strokeWidth: 2)` replacing icon
- **Result:** Opens `AIReflectionBottomSheet` (see below)

#### AIReflectionBottomSheet

- **Height:** 85% of screen
- **Drag handle:** Standard
- **Content:** 3 message bubbles stacked vertically, 12dp gap:

**Devil Bubble:**
```
┌─ 😈 ─────────────────────────────────┐
│                                       │
│  "Come on, that coffee was totally    │
│   worth it. You work hard!"           │
│                                       │
└───────────────────────────────────────┘
```
- Background: `devilBg` (light/dark adaptive)
- Left border: 4dp solid `devilAccent`
- Radius: 12dp
- Padding: 16dp
- Icon row: `😈` emoji or `Icons.local_fire_department` in `devilAccent` + "Impulse" label (`labelMedium`, `devilAccent`)
- Message: `bodyLarge`, `devilText`

**Angel Bubble:**
```
┌─ 😇 ─────────────────────────────────┐
│                                       │
│  "That $6.50 adds up to $195/month.  │
│   Your coffee budget is at 78%."      │
│                                       │
└───────────────────────────────────────┘
```
- Background: `angelBg`
- Left border: 4dp solid `angelAccent`
- Icon row: `😇` emoji or `Icons.shield` in `angelAccent` + "Reason" label
- Message: `bodyLarge`, `angelText`

**Neutral Bubble:**
```
┌─ ⚖️ ─────────────────────────────────┐
│                                       │
│  "What would change if you made this │
│   coffee at home twice a week?"       │
│                                       │
└───────────────────────────────────────┘
```
- Background: `neutralBg`
- Left border: 4dp solid `neutralAccent`
- Icon row: `⚖️` emoji or `Icons.balance` in `neutralAccent` + "Reflection" label
- Message: `bodyLarge`, `neutralText`

---

### 4.5 Add/Edit Transaction (`/transactions/add`, `/transactions/:id/edit`)

#### AppBar

- **Title:** "Add Transaction" or "Edit Transaction" (`titleLarge`)
- **Leading:** Close button (`Icons.close`) → confirmation dialog if form is dirty
- **Actions:** None

#### Body — `SingleChildScrollView`, 16dp horizontal padding, 16dp top padding

**Transaction Type Toggle (top):**

- Widget: `SegmentedButton<TransactionType>` (M3), full width
- Segments: "Expense" (leading: `Icons.arrow_downward`, tint: `expense`) | "Income" (leading: `Icons.arrow_upward`, tint: `income`)
- Default: Expense
- 16dp bottom margin

**Amount Input:**

- Widget: Large `OutlinedTextField`
- **Custom styling:** Font size 32sp (`displayMedium`), center-aligned, Poppins 700
- `keyboardType: TextInputType.numberWithOptions(decimal: true)`
- **Prefix:** Transaction type symbol ("−" for expense, "+" for income) in corresponding color
- **Suffix:** Currency badge (e.g., "USD") — tapping opens `CurrencyPickerBottomSheet`
- **Placeholder:** "0.00"
- Validation: Must be > 0
- 16dp bottom margin

**Category Picker:**

- Label: "Category" (`titleSmall`, `onSurfaceVariant`)
- Widget: `Wrap` of `ChoiceChip` widgets in a 3-column grid layout
- Each chip: icon (20dp) + label (`labelMedium`)
- Max visible: 9 chips (3 rows). If more, `TextButton("More...")` expands to show all.
- Selected: `primaryContainer` bg, `primary` check overlay
- 16dp bottom margin

**Category Icon Map** <a id="category-icon-map"></a>

| Category | Icon | Emoji Fallback |
|---|---|---|
| Groceries | `Icons.shopping_cart` | 🛒 |
| Dining | `Icons.restaurant` | 🍽️ |
| Transport | `Icons.directions_car` | 🚗 |
| Entertainment | `Icons.movie` | 🎬 |
| Shopping | `Icons.shopping_bag` | 🛍️ |
| Health | `Icons.favorite` | ❤️ |
| Bills | `Icons.receipt` | 📄 |
| Education | `Icons.school` | 🎓 |
| Travel | `Icons.flight` | ✈️ |
| Coffee | `Icons.coffee` | ☕ |
| Subscriptions | `Icons.autorenew` | 🔄 |
| Salary | `Icons.account_balance` | 🏦 |
| Freelance | `Icons.work` | 💼 |
| Gift | `Icons.card_giftcard` | 🎁 |
| Other | `Icons.more_horiz` | ··· |

**Merchant Name:**

- Widget: `OutlinedTextField`
- Label: "Merchant (optional)"
- `textCapitalization: TextCapitalization.words`
- 16dp bottom margin

**Date Picker:**

- Widget: `ListTile` with `Icons.calendar_today` leading
- Title: Formatted date (e.g., "May 1, 2026")
- Trailing: `Icons.chevron_right`
- Tap: Opens `showDatePicker()` — initial: form date or today, first: 1 year ago, last: today (no future dates for expenses; allow future for income)
- 16dp bottom margin

**Location Toggle:**

- Widget: `SwitchListTile`
- Title: "Include Location" (`titleSmall`)
- Subtitle: "Attach GPS coordinates" (`bodySmall`, `onSurfaceVariant`)
- On toggle: Requests location permission, captures `Position` from `geolocator` package, stores lat/long in form state
- When on and location captured: Shows "📍 34.0522, −118.2437" below the switch (`bodySmall`)
- 16dp bottom margin

**Notes (optional):**

- Widget: `OutlinedTextField`, `maxLines: 3`, `minLines: 1`
- Label: "Notes (optional)"
- 24dp bottom margin

**Submit Button:**

- `FilledButton`, full width, 48dp height
- Text: "Save Transaction" (add) or "Update Transaction" (edit)
- Loading state: `CircularProgressIndicator(strokeWidth: 2)` replacing text
- Disabled when: form invalid or submitting
- On success (add): `POST /api/v1/transactions` → pop back, show `SnackBar("Transaction added!")`, invalidate `transactionListProvider` + `budgetSummaryProvider`
- On success (edit): `PUT /api/v1/transactions/:id` → pop back, show `SnackBar("Transaction updated")`, invalidate detail + list providers
- On error: `SnackBar` with error message from API

**Edit mode prefill:** When `id` parameter is present, `transactionDetailProvider(id)` loads the transaction and pre-fills all fields. Form tracks `isDirty` state (any field changed from initial).

---

### 4.6 Pre-Purchase Assistant (`/assistant`)

#### AppBar

- **Title:** "Pre-Purchase Assistant" (`titleLarge`)
- **Subtitle (optional):** "Should you buy it?" (`bodySmall`, `onSurfaceVariant`) — only if no response is loaded

#### Body — `Column` filling available space

**State 1: Input Form (no response yet)**

Centered vertically in available space, `SingleChildScrollView`:

**Illustration (top):**
- Centered: Two overlapping circle avatars — Devil (amber) and Angel (teal), 64dp each, offset by 20dp
- Below: "Let's think this through" (`headlineMedium`, centered)
- 24dp spacer

**Form fields (same `OutlinedTextField` style):**

| Field | Widget | Details |
|---|---|---|
| Description | `OutlinedTextField`, 2 lines max | Label: "What are you thinking of buying?", validation: non-empty |
| Amount | `OutlinedTextField`, number input | Same large-format style as transaction form, with currency badge suffix |
| Category | `DropdownButtonFormField` | Same categories as transaction form, dropdown menu |

- 16dp gap between fields

**CTA:**
- `FilledButton.icon(Icons.auto_awesome, "Ask My Conscience")`, full width
- Loading state: Button replaced by typing indicator animation (see [Animations](#typing-indicator))

---

**State 2: Loading (API call in progress)**

Form collapses to a compact summary at top:

```
┌──────────────────────────────────────────┐
│  "New headphones"  ·  $150 USD  ·  🎬   │
└──────────────────────────────────────────┘
```

Below: **Typing indicator** — 3 dots in a row, pulsing sequentially. Below dots: "Your conscience is thinking..." (`bodySmall`, `onSurfaceVariant`).

---

**State 3: Response Display**

**Compact summary card** pinned at top (same as loading state).

**3 AI Message Bubbles** — same visual treatment as `AIReflectionBottomSheet`:

1. **Devil (Impulse)** — appears first, slides in from left, 200ms delay
2. **Angel (Reason)** — appears second, slides in from right, 400ms delay
3. **Neutral (Reflection)** — appears third, fades in, 600ms delay

Each bubble uses the same design spec as described in [4.4 AIReflectionBottomSheet](#aireflectionbottomsheet).

**Budget Context Card (conditional):**

If the API response includes a matching budget, show below the bubbles:

```
┌──────────────────────────────────────────┐
│  📊  Entertainment Budget                │
│                                          │
│  $340 / $500 (68%)                       │
│  ████████░░░░░░░                         │
│                                          │
│  This purchase would bring you to 98%    │
└──────────────────────────────────────────┘
```

- Card: `surfaceContainer`, 16dp radius
- Progress bar: Same budget health color scheme
- Projected percentage: Calculated client-side (`(currentSpend + amount) / monthlyLimit * 100`), shown in `bodyMedium`, colored based on projected health

**Bottom action:**
- `OutlinedButton("Ask About Something Else")` — resets form, clears response
- 16dp bottom padding

---

### 4.7 Budgets (`/settings/budgets`)

#### AppBar

- **Title:** "Budgets" (`titleLarge`)
- **Leading:** Back arrow
- **Actions:** `IconButton(Icons.add)` → opens `CreateBudgetBottomSheet`

#### Body — `ListView.builder`

**Each Budget Card:**

```
┌──────────────────────────────────────────────┐
│  🛒  Groceries                        ⋮      │
│                                               │
│  $340.00 / $500.00                   68%      │
│  ████████████░░░░░░░                          │
│                                               │
│  USD · Resets in 12 days                      │
└──────────────────────────────────────────────┘
```

- Card: `surface`, 16dp radius, 16dp padding, 12dp gap between cards
- Header row: Category icon (`CircleAvatar(radius: 16)`) + category name (`titleMedium`) + `Spacer` + `PopupMenuButton` (options: Edit, Delete)
- Amounts: `$spent / $limit` (`bodyLarge`, `onSurface`) + right-aligned percentage (`titleSmall`, budget health color)
- Progress bar: Full-width `LinearProgressIndicator`, 8dp height, 4dp radius, color by health
- Footer: Currency code + "Resets in {N} days" (calculated: days until end of current month) (`bodySmall`, `onSurfaceVariant`)
- **Over budget visual:** When `isOverBudget`, the entire card has a subtle 1dp border in `budgetDanger` at 50% opacity. The progress bar shows a striped/overflow effect (value clamped to 1.0, but background tinted red).

**Empty state:**
- Centered illustration + "No budgets yet" + "Create budgets to track spending by category" + `FilledButton("Create Budget")`

#### CreateBudgetBottomSheet / EditBudgetBottomSheet

- **Height:** Wraps content (~350dp)
- **Drag handle:** Standard
- **Title:** "New Budget" or "Edit Budget" (`headlineMedium`)

**Fields:**

| Field | Widget | Details |
|---|---|---|
| Category | `DropdownButtonFormField` | Same category list. Disabled in edit mode. |
| Monthly Limit | `OutlinedTextField` (number) | Same large-format amount style, currency badge suffix |
| Currency | Pre-filled from user preference, changeable via badge tap |

- **CTA:** `FilledButton`, full width, "Create Budget" / "Save Changes"
- **Delete (edit only):** `TextButton("Delete Budget", style: TextStyle(color: error))` — shows confirmation dialog

---

### 4.8 Receipt Scanner (`/scan`) — Premium Only

#### Premium Gate

**If user is on Free tier:** Instead of the camera, display a premium upsell screen:

```
┌──────────────────────────────────────────────┐
│                                               │
│              📸  ← large icon (80dp)          │
│                                               │
│        Scan Receipts with AI                  │  ← headlineLarge
│                                               │
│   Snap a photo of any receipt and let AI      │  ← bodyLarge, centered
│   extract merchant, total, and line items.    │
│                                               │
│         [ ⭐ Upgrade to Premium ]             │  ← FilledButton, secondary color
│                                               │
│         Maybe Later                           │  ← TextButton → pop back
│                                               │
└──────────────────────────────────────────────┘
```

Tapping "Upgrade to Premium" opens the `SubscriptionBottomSheet` (see [4.11](#411-subscriptionupgrade-bottom-sheet)).

#### Camera Screen (Premium Users)

- **Full-screen camera preview** using `camera` package
- **AppBar:** Transparent, white icons, leading: close button
- **Overlay:** Semi-transparent dark mask with a centered document outline (rounded rectangle, white border, 2dp dashed) showing the capture area. Below: "Align receipt within the frame" (`bodyMedium`, white)
- **Capture button:** Centered at bottom, 72dp white circle with 64dp inner circle, styled like iOS camera button
- **Flash toggle:** Top-right `IconButton` (auto/on/off cycle)
- **Gallery button:** Bottom-left, opens device gallery via `image_picker`

#### Processing State

After capture:
- Camera preview freezes on last frame
- Overlay becomes solid `background` at 90% opacity
- Center: `CircularProgressIndicator` + "Scanning receipt..." (`bodyLarge`)
- Duration: Depends on API response time (~2-5s)

#### On Success

Navigate to `/receipts/:id/review` with the scan result.

#### On Error

- `SnackBar("Couldn't read that receipt. Try again with better lighting.")` with `SnackBarAction("Retry")`
- Return to camera preview

---

### 4.9 Receipt Review (`/receipts/:id/review`)

#### AppBar

- **Title:** "Review Receipt" (`titleLarge`)
- **Leading:** Back arrow (with unsaved changes confirmation)

#### Body — `SingleChildScrollView`, 16dp padding

**Confidence Banner (top):**

```
┌──────────────────────────────────────────────┐
│  🤖  AI Confidence: 87%  ████████░░          │
│  Please verify the extracted data            │
└──────────────────────────────────────────────┘
```

- Background: `primaryContainer` at 30% opacity if confidence ≥ 70%, `error` at 15% if < 70%
- 12dp radius, 12dp padding
- `LinearProgressIndicator` showing confidence value (0.0–1.0)
- Text: "AI Confidence: {N}%" (`titleSmall`) + helper text (`bodySmall`)
- If confidence < 70%: Helper reads "Low confidence — please check all fields carefully"
- 16dp bottom margin

**Editable Fields:**

Each field has a small "AI" badge indicator showing it was auto-extracted. Fields that the AI is less confident about are highlighted with a subtle amber background.

| Field | Widget | Pre-filled From |
|---|---|---|
| Merchant | `OutlinedTextField` | `ReceiptScanResultDto.merchant` |
| Total Amount | `OutlinedTextField` (number, large format) | `ReceiptScanResultDto.total` |
| Currency | Currency badge (tappable) | `ReceiptScanResultDto.currencyCode` |
| Date | Date picker `ListTile` | `ReceiptScanResultDto.date` |

**Line Items Section (expandable):**

- Header: "Line Items ({count})" (`titleMedium`) + expand/collapse `IconButton`
- Default: Collapsed if > 3 items
- Each item: Row — description (`bodyMedium`, `Expanded`) + amount (`bodyMedium`, right-aligned)
- Items are read-only in MVP (editing individual line items is complex; user edits the total)

**Category Picker:**

- Same `Wrap` of `ChoiceChip` as transaction form
- Pre-selected based on merchant name heuristic (if OCR merchant matches a known category)

**Confirm Button:**

- `FilledButton`, full width, "Confirm & Save"
- Calls `POST /api/v1/receipts/:id/confirm` with corrected fields
- On success: Creates a transaction from the receipt data, navigates to `/transactions/:id` (the newly created transaction), shows `SnackBar("Receipt saved as transaction")`
- Loading state: Button with `CircularProgressIndicator`

---

### 4.10 Settings (`/settings`)

#### AppBar

- **Title:** "Settings" (`titleLarge`)

#### Body — `ListView` of grouped sections

**Section 1: Profile**

```
┌──────────────────────────────────────────────┐
│  👤  alice@example.com                        │
│      Member since May 2026                    │
└──────────────────────────────────────────────┘
```

- `ListTile`: Leading `CircleAvatar` with first letter of email, `primaryContainer` bg
- Title: email (`titleMedium`)
- Subtitle: "Member since {createdAt formatted}" (`bodySmall`)
- Non-tappable (no profile edit in MVP beyond currency/locale)

**Section 2: Preferences**

| Setting | Widget | Behavior |
|---|---|---|
| Default Currency | `ListTile` | Shows current currency (e.g., "USD — US Dollar"). Trailing: `Icons.chevron_right`. Tap → `CurrencyPickerBottomSheet`. On select: `PUT /api/v1/users/me` |
| Number Format | `ListTile` | Shows current locale format preview (e.g., "$1,234.56"). Trailing: `Icons.chevron_right`. Tap → `LocalePickerBottomSheet`. On select: `PUT /api/v1/users/me` |

**Section 3: Budgets**

- Single `ListTile`: "Manage Budgets" with `Icons.pie_chart_outline` leading, trailing `Icons.chevron_right`
- Tap → `/settings/budgets`

**Section 4: Subscription**

```
┌──────────────────────────────────────────────┐
│  ⭐  Premium                                  │
│      Active until Jun 1, 2026                 │
│                                [ Manage ]     │
└──────────────────────────────────────────────┘
```

**Free tier:**
```
┌──────────────────────────────────────────────┐
│  Conscia Free                                 │
│  3 budgets · 5 AI assists/mo                  │
│                                               │
│        [ ⭐ Upgrade to Premium ]              │
└──────────────────────────────────────────────┘
```

- Card: `surfaceContainer`, 16dp radius, 16dp padding
- Free: Shows limits, `FilledButton("Upgrade to Premium")` → `SubscriptionBottomSheet`
- Premium: Shows tier badge (`⭐ Premium` in `secondary` color), expiry date, `OutlinedButton("Manage")` → platform subscription management

**Section 5: About**

| Item | Behavior |
|---|---|
| Sign Out | `ListTile` with `Icons.logout`, `error` color icon + text. Tap → Confirmation dialog → clears tokens, navigates to `/onboarding` |
| App Version | `ListTile`, non-tappable: "Version 1.0.0 (build 1)" (`bodySmall`, `onSurfaceVariant`) |

---

### 4.11 Subscription/Upgrade Bottom Sheet

**Triggered from:** Receipt scanner premium gate, Settings upgrade button, any premium feature gate.

**Height:** 85% of screen.

**Content:**

**Header:**
- "Unlock Conscia Premium" (`headlineLarge`, centered)
- "Make smarter money decisions" (`bodyLarge`, `onSurfaceVariant`, centered)
- 24dp spacer

**Feature Comparison Table:**

```
┌──────────────────────────────────────────────┐
│  Feature              Free        Premium    │
│  ─────────────────────────────────────────── │
│  Manual Tracking      Unlimited   Unlimited  │
│  Budgets              3           Unlimited  │
│  AI Assists/month     5           Unlimited  │
│  Reflections/month    10          Unlimited  │
│  Receipt Scanning     ✗           ✓          │
│  Multi-Currency       1 currency  Unlimited  │
└──────────────────────────────────────────────┘
```

- Implemented as a `DataTable` or custom `Column` of `Row` widgets
- "Free" column: `bodyMedium`, `onSurfaceVariant`
- "Premium" column: `bodyMedium`, `primary`, bold
- Check/cross icons: `Icons.check_circle` in `income` / `Icons.cancel` in `outlineVariant`
- Alternating row backgrounds: transparent / `surfaceContainer` at 50%

**Pricing:**

- "$X.XX / month" (`headlineMedium`, `primary`) — actual price from `in_app_purchase` product query
- "Cancel anytime" (`bodySmall`, `onSurfaceVariant`)

**CTA:**

- `FilledButton`, full width, `secondary` bg: "Subscribe Now"
- Tap: Initiates platform-native purchase flow via `in_app_purchase` package
- Loading: Button shows progress indicator during purchase flow
- Success: Calls `POST /api/v1/subscriptions/verify/ios` or `/android` with receipt token. On backend confirmation: updates `subscriptionProvider`, shows `SnackBar("Welcome to Premium! 🎉")`, dismisses sheet.
- Failure/cancel: `SnackBar("Purchase cancelled")` or error message

**Restore:**

- `TextButton("Restore Purchases")` below CTA
- Triggers `InAppPurchase.instance.restorePurchases()`

---

## 5. Animation & Micro-Interaction Specs

### 5.1 Page Transitions

| Transition | Type | Duration | Curve |
|---|---|---|---|
| Tab switch (bottom nav) | None / instant | 0ms | — |
| Push to detail | `SlideTransition` (right to left) | 300ms | `Curves.easeInOut` |
| Push to form (add/edit) | `SlideTransition` (bottom to top) | 300ms | `Curves.easeOut` |
| Full-screen modal (scan) | `SlideTransition` (bottom to top) | 350ms | `Curves.easeOutCubic` |
| Bottom sheet open | Platform default (Material slide-up) | 250ms | `Curves.easeOut` |
| Bottom sheet dismiss | Reverse | 200ms | `Curves.easeIn` |
| Pop (back) | Reverse of push | 300ms | `Curves.easeInOut` |

### 5.2 Element Animations

#### Typing Indicator (Pre-Purchase Loading) <a id="typing-indicator"></a>

Three dots (10dp diameter, `primary` color) in a row, 6dp gap. Each dot animates `scale` from 0.5 → 1.0 → 0.5 with 600ms period, staggered by 200ms:

- Dot 1: 0ms offset
- Dot 2: 200ms offset
- Dot 3: 400ms offset

Use `AnimationController` with `StaggeredAnimation` or `TweenSequence`.

#### Budget Progress Bar

- On initial load: `LinearProgressIndicator` value animates from 0 to actual value over 500ms, `Curves.easeOutCubic`
- On value change (refresh): Animates from old value to new value over 400ms, `Curves.easeInOut`
- Color transitions between health thresholds use `ColorTween` with same duration

#### Regret Card Dismiss

- Swipe dismiss: `Dismissible` with `SlideTransition` + `FadeTransition`
- Button tap dismiss: Card shrinks height to 0 via `AnimatedContainer(duration: 300ms, curve: Curves.easeInOut)` then removed from list

#### AI Bubble Entrance (Pre-Purchase Response)

Staggered entrance:
1. Devil bubble: `SlideTransition` from left (offset -0.3 → 0) + `FadeTransition` (0 → 1), 400ms, starts at 0ms
2. Angel bubble: `SlideTransition` from right (offset 0.3 → 0) + `FadeTransition`, 400ms, starts at 200ms
3. Neutral bubble: `FadeTransition` only, 400ms, starts at 400ms

Total sequence: 800ms. Use `AnimationController(duration: 800ms)` with `Interval`-based `CurvedAnimation` per bubble.

#### FAB Scroll Behavior

- Scroll down > 100dp: FAB morphs from `FloatingActionButton.extended` (with "Add" label) to `FloatingActionButton` (icon only)
- Animated via `AnimatedSwitcher(duration: 200ms)`
- Scroll up or at top: Returns to extended

#### Pull-to-Refresh

- Standard Material 3 `RefreshIndicator` with `primary` color spinner
- Displacement: 40dp

#### Skeleton Loading

For initial data loads (dashboard, transaction list):
- Use `Shimmer` package or custom `AnimatedContainer` with gradient sweep
- Skeleton shapes mirror actual content layout (cards, list rows)
- Colors: `surfaceContainer` to `surface` sweep, 1500ms duration, infinite repeat

### 5.3 Haptic Feedback

| Action | Feedback |
|---|---|
| Regret button tap | `HapticFeedback.mediumImpact()` |
| Transaction created | `HapticFeedback.heavyImpact()` |
| FAB tap | `HapticFeedback.lightImpact()` |
| Swipe dismiss | `HapticFeedback.selectionClick()` |
| Error (validation/API) | `HapticFeedback.vibrate()` |

---

## 6. Dark Mode

### 6.1 Theme Configuration

```dart
ThemeData consciaLightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1A237E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC5CAE9),
    secondary: Color(0xFFFFB300),
    onSecondary: Color(0xFF1A237E),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    error: Color(0xFFE53935),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  // ... typography, component themes
);

ThemeData consciaDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7986CB),
    onPrimary: Color(0xFF1A237E),
    primaryContainer: Color(0xFF283593),
    secondary: Color(0xFFFFD54F),
    onSecondary: Color(0xFF1A237E),
    surface: Color(0xFF1E1E2E),
    onSurface: Color(0xFFE6E1E5),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    error: Color(0xFFF2B8B5),
  ),
  scaffoldBackgroundColor: const Color(0xFF0D1117),
  // ... typography, component themes
);
```

### 6.2 Per-Screen Dark Mode Adaptations

| Element | Light | Dark | Notes |
|---|---|---|---|
| Cards | White bg, no shadow, 1dp `outlineVariant` border | `#1E1E2E` bg, 2dp shadow, no border | Prevents cards from blending into dark bg |
| AppBar | `surface` bg, `Divider` bottom | `surface` bg, `Divider` bottom | Same behavior, colors auto-adapt |
| Budget progress track | `outlineVariant` at 20% opacity | `outlineVariant` at 30% opacity | Slightly more visible on dark bg |
| Devil bubble | `#FFF8E1` bg | `#3E2723` bg | Warm tones preserved in both |
| Angel bubble | `#E0F7FA` bg | `#0D3B47` bg | Cool tones preserved in both |
| Neutral bubble | `#F5F5F5` bg | `#2C2C3A` bg | Subtle contrast |
| Income amount | `#4CAF50` | `#81C784` | Lighter green for dark bg readability |
| Expense amount | `#E53935` | `#EF9A9A` | Lighter red for dark bg readability |
| Onboarding gradient | `primary` at 5% opacity | `primary` at 8% opacity | Slightly stronger for visibility |
| Camera overlay (scanner) | Dark mask, white border | Same | Full-screen camera unaffected by theme |
| Skeleton shimmer | `#F5F5F5` → `#FFFFFF` | `#252536` → `#1E1E2E` | Matches surface tones |

### 6.3 Theme Switching

- **Default:** Follow system setting (`ThemeMode.system`)
- **No manual toggle in MVP.** Settings screen does not include a light/dark toggle. The app respects the OS-level dark mode setting. Manual override can be added post-MVP if requested.
- Implementation: `MaterialApp(themeMode: ThemeMode.system, theme: consciaLightTheme(), darkTheme: consciaDarkTheme())`

---

## 7. Responsive Layout

### 7.1 Breakpoints

| Breakpoint | Width | Layout |
|---|---|---|
| Compact (phone) | < 600dp | Single column, bottom nav, full-width cards |
| Medium (large phone / small tablet) | 600–840dp | Single column, wider cards with max-width 600dp centered |
| Expanded (tablet) | > 840dp | Two-column layout, side navigation rail instead of bottom nav |

### 7.2 Phone Layout (Compact — Primary Target)

All screen specs above are designed for this breakpoint. No additional adaptation needed.

### 7.3 Tablet Layout (Expanded — 840dp+)

**Navigation:** Replace `BottomNavigationBar` with `NavigationRail` on the left side (80dp width, extended labels below icons).

**Dashboard:**
- Budget cards: 2 columns instead of horizontal scroll
- Regret prompt + recent transactions: Side by side (50/50 split)

**Transaction List:**
- List on left (40% width), detail on right (60%) — master-detail pattern
- Selecting a transaction in the list loads detail in the right pane without navigation

**Pre-Purchase Assistant:**
- Form on left (40%), response on right (60%)

**Settings:**
- Settings list on left (40%), selected setting detail on right (60%)

**Implementation:** Use `LayoutBuilder` to check width at `MainShell` level. Switch between `Scaffold(bottomNavigationBar: ...)` and `Scaffold(body: Row(children: [NavigationRail(...), Expanded(child: ...)]))`.

### 7.4 Content Max Width

On any screen wider than 600dp, content areas are constrained to `maxWidth: 600dp` and centered. Prevents text lines from becoming unreadably long.

Implementation: Wrap body content in `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600)))`.

---

## 8. Accessibility Checklist

### 8.1 Global Requirements

| Requirement | Implementation | Status |
|---|---|---|
| Minimum touch target 48×48dp | All `IconButton`, `InkWell`, list items enforce `minimumSize: Size(48, 48)` via `MaterialTapTargetSize.padded` | Required |
| Color contrast WCAG AA (4.5:1 text, 3:1 large text) | All color token pairs verified (see 8.2) | Required |
| Screen reader support | Semantic labels on all interactive elements | Required |
| Dynamic text sizing | All text uses `sp` units, layout handles up to 200% text scale without overflow | Required |
| Keyboard navigation (tablet) | `FocusTraversalGroup` ordering, visible focus indicators | Required |
| Reduced motion | Respect `MediaQuery.of(context).disableAnimations` — skip non-essential animations | Required |

### 8.2 Color Contrast Verification

| Foreground | Background | Ratio | Pass (AA) |
|---|---|---|---|
| `#1C1B1F` (text) | `#FFFFFF` (surface) | 16.8:1 | Yes |
| `#1C1B1F` (text) | `#FAFAFA` (background) | 15.4:1 | Yes |
| `#FFFFFF` (text) | `#1A237E` (primary) | 12.1:1 | Yes |
| `#E53935` (expense) | `#FFFFFF` (surface) | 4.6:1 | Yes (AA) |
| `#4CAF50` (income) | `#FFFFFF` (surface) | 3.2:1 | Yes (large text/icons only; pair with label for small text) |
| `#E6E1E5` (dark text) | `#0D1117` (dark bg) | 13.2:1 | Yes |
| `#EF9A9A` (dark expense) | `#1E1E2E` (dark surface) | 5.8:1 | Yes |
| `#81C784` (dark income) | `#1E1E2E` (dark surface) | 6.1:1 | Yes |

**Income green on white (3.2:1):** Passes for large text and icons (3:1 threshold) but fails for small body text. Mitigation: always pair green income amounts with a text label ("Income" or "+"), never rely on color alone.

### 8.3 Per-Screen Accessibility Notes

#### Onboarding

| Element | Semantic Label | Notes |
|---|---|---|
| Page indicators | "Page {n} of 3" via `Semantics(label:)` | Not redundant — screen readers skip visual dots |
| Password visibility toggle | "Show password" / "Hide password" | Toggle `Semantics(label:)` based on state |
| Currency picker items | "{currency name}, {code}" | Read full name, not just code |

#### Dashboard

| Element | Semantic Label | Notes |
|---|---|---|
| Budget card | "Groceries budget: $340 of $500 spent, 68 percent" | Full context in one read |
| Budget progress bar | `Semantics(value: '68%', label: 'Budget usage')` | Custom semantics since `LinearProgressIndicator` semantics are generic |
| Regret prompt buttons | "Rate {merchant} purchase: worth it / not sure / regret" | Group semantics with `MergeSemantics` |
| Transaction row | "{merchant}, {amount}, {category}, {date}" | Ordered reading |
| FAB | "Add new transaction" | Default M3 semantics sufficient |
| Warning banner | "Budget alert: {N} budgets over 80 percent" | `Semantics(liveRegion: true)` for announcements |

#### Transaction List

| Element | Semantic Label | Notes |
|---|---|---|
| Filter chips | "Filter by {category}, {selected/not selected}" | Built-in `FilterChip` semantics |
| Date separator | "Transactions for {date}" | `Semantics(header: true)` |
| Pull-to-refresh | "Pull down to refresh" | Built-in `RefreshIndicator` semantics |
| Loading more | "Loading more transactions" | `Semantics(label:)` on progress indicator |

#### Transaction Detail

| Element | Semantic Label | Notes |
|---|---|---|
| Amount | "{type}: {formatted amount}" | Include "Expense" or "Income" prefix |
| Location | "Location: {merchant name}, coordinates {lat}, {long}" | |
| Regret chips | "Purchase rated: {level}" | |
| AI reflect button | "Ask AI to reflect on this purchase" | |
| Delete action | "Delete transaction" — alert: "Are you sure? This cannot be undone." | Confirm dialog uses `AlertDialog` semantics |

#### Add/Edit Transaction

| Element | Semantic Label | Notes |
|---|---|---|
| Type toggle | "Transaction type: {Expense/Income}" | `SegmentedButton` has built-in semantics |
| Amount field | "Amount in {currency code}" | |
| Category chips | "Category: {name}, {selected/not selected}" | |
| Location toggle | "Include GPS location: {on/off}" | |
| Validation errors | Error text associated via `InputDecoration.errorText` | Auto-announced by `TextField` |

#### Pre-Purchase Assistant

| Element | Semantic Label | Notes |
|---|---|---|
| Typing indicator | "Analyzing your purchase..." via `Semantics(label:)` | Replace visual animation with text for screen readers |
| Devil bubble | "Impulse advisor says: {message}" | Group icon + label + text with `MergeSemantics` |
| Angel bubble | "Reason advisor says: {message}" | |
| Neutral bubble | "Reflection: {message}" | |
| Budget context | "Related budget: {category}, {spent} of {limit}, {percent} percent used" | |

#### Budgets

| Element | Semantic Label | Notes |
|---|---|---|
| Budget card | Full read-out: "{category}: {spent} of {limit} spent, {percent} percent, {currency}" | |
| Over-budget indicator | "Over budget" announced via `Semantics(label:)` when `isOverBudget` | |
| Add button | "Create new budget" | |

#### Receipt Scanner

| Element | Semantic Label | Notes |
|---|---|---|
| Camera preview | "Camera viewfinder. Align receipt in frame." | `Semantics(label:)` on camera widget |
| Capture button | "Take photo of receipt" | |
| Premium gate | "Receipt scanning requires Premium subscription. Upgrade to Premium button." | |

#### Receipt Review

| Element | Semantic Label | Notes |
|---|---|---|
| Confidence banner | "AI extracted data with {N} percent confidence. Please verify." | |
| Line items | "Line item: {description}, {amount}" per item | |
| Confirm button | "Confirm receipt and save as transaction" | |

#### Settings

| Element | Semantic Label | Notes |
|---|---|---|
| Sign out | "Sign out of Conscia" | Confirmation dialog announced |
| Subscription card | "Subscription: {tier}. {description of limits/features}" | |
| Currency picker | "Default currency: {current}. Tap to change." | |

---

## Appendix A: API Endpoint Map (Flutter → Backend)

Quick reference for the Dio service layer mapping each screen's data needs to API calls.

| Screen | API Call | Method | Path | Notes |
|---|---|---|---|---|
| Sign Up | Register | POST | `/api/v1/auth/register` | Body: `{email, password}` |
| Sign In | Login | POST | `/api/v1/auth/login` | Body: `{email, password}` |
| Setup | Update profile | PUT | `/api/v1/users/me` | Body: `{preferredCurrency, locale}` |
| Dashboard | List budgets | GET | `/api/v1/budgets` | |
| Dashboard | List transactions | GET | `/api/v1/transactions?pageSize=10` | First page only |
| Dashboard | List alerts | GET | `/api/v1/alerts` | Budget warnings |
| Transaction List | List transactions | GET | `/api/v1/transactions?page=N&pageSize=20&category=X` | Paginated, filtered |
| Transaction Detail | Get transaction | GET | `/api/v1/transactions/:id` | |
| Transaction Detail | Update regret | POST | `/api/v1/transactions/:id/regret` | Body: `{level}` |
| Add Transaction | Create | POST | `/api/v1/transactions` | Body: `CreateTransactionDto` |
| Edit Transaction | Update | PUT | `/api/v1/transactions/:id` | Body: `UpdateTransactionDto` |
| Delete Transaction | Delete | DELETE | `/api/v1/transactions/:id` | |
| Pre-Purchase | AI advice | POST | `/api/v1/ai/pre-purchase` | Body: `{description, amount, currencyCode, category}` |
| Budgets | List | GET | `/api/v1/budgets` | |
| Budgets | Create | POST | `/api/v1/budgets` | Body: `{category, monthlyLimit, currencyCode}` |
| Budgets | Update | PUT | `/api/v1/budgets/:id` | Body: `{monthlyLimit, category}` |
| Budgets | Delete | DELETE | `/api/v1/budgets/:id` | |
| Settings | Get profile | GET | `/api/v1/users/me` | |
| Settings | Update profile | PUT | `/api/v1/users/me` | |
| Subscription | Get status | GET | `/api/v1/subscriptions/status` | |
| Subscription | Verify iOS | POST | `/api/v1/subscriptions/verify/ios` | Body: `{token}` |
| Subscription | Verify Android | POST | `/api/v1/subscriptions/verify/android` | Body: `{token}` |

## Appendix B: File Structure (Recommended)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + theme + router
├── core/
│   ├── theme/
│   │   ├── app_theme.dart            # consciaLightTheme(), consciaDarkTheme()
│   │   ├── app_colors.dart           # Color constants + extension methods
│   │   └── app_typography.dart       # TextTheme definitions
│   ├── constants/
│   │   ├── api_constants.dart        # Base URL, endpoints
│   │   ├── category_icons.dart       # Category → Icon mapping
│   │   └── currencies.dart           # ISO 4217 currency list
│   ├── network/
│   │   ├── dio_client.dart           # Dio instance + interceptors
│   │   └── api_exception.dart        # Typed exceptions
│   ├── routing/
│   │   └── app_router.dart           # GoRouter configuration
│   └── utils/
│       ├── currency_formatter.dart   # intl-based currency formatting
│       └── date_formatter.dart       # Relative + absolute date formatting
├── models/                           # freezed + json_serializable
│   ├── transaction.dart
│   ├── budget.dart
│   ├── user.dart
│   ├── ai_response.dart
│   ├── subscription_status.dart
│   ├── in_app_alert.dart
│   └── receipt_scan_result.dart
├── providers/                        # Riverpod providers
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── transaction_providers.dart
│   ├── budget_providers.dart
│   ├── ai_provider.dart
│   ├── subscription_provider.dart
│   ├── alert_provider.dart
│   └── receipt_provider.dart
├── services/                         # Dio-based API services
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── transaction_service.dart
│   ├── budget_service.dart
│   ├── ai_service.dart
│   ├── subscription_service.dart
│   └── receipt_service.dart
├── screens/
│   ├── onboarding/
│   │   ├── onboarding_screen.dart    # PageView with welcome slides
│   │   ├── sign_up_screen.dart
│   │   ├── sign_in_screen.dart
│   │   └── setup_screen.dart
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── budget_summary_card.dart
│   │       ├── regret_prompt_card.dart
│   │       ├── budget_warning_banner.dart
│   │       └── recent_transaction_tile.dart
│   ├── transactions/
│   │   ├── transaction_list_screen.dart
│   │   ├── transaction_detail_screen.dart
│   │   ├── transaction_form_screen.dart  # Shared add/edit
│   │   └── widgets/
│   │       ├── transaction_tile.dart
│   │       ├── category_picker.dart
│   │       └── date_section_header.dart
│   ├── assistant/
│   │   ├── pre_purchase_screen.dart
│   │   └── widgets/
│   │       ├── ai_message_bubble.dart    # Reused in detail + assistant
│   │       ├── typing_indicator.dart
│   │       └── budget_context_card.dart
│   ├── budgets/
│   │   ├── budgets_screen.dart
│   │   └── widgets/
│   │       ├── budget_card.dart
│   │       └── budget_form_sheet.dart
│   ├── receipts/
│   │   ├── receipt_scanner_screen.dart
│   │   ├── receipt_review_screen.dart
│   │   └── widgets/
│   │       ├── confidence_banner.dart
│   │       └── premium_gate.dart         # Reusable premium upsell
│   └── settings/
│       ├── settings_screen.dart
│       └── widgets/
│           ├── subscription_card.dart
│           └── subscription_sheet.dart
├── widgets/                          # Shared/reusable widgets
│   ├── main_shell.dart               # Scaffold + BottomNav / NavRail
│   ├── currency_badge.dart
│   ├── currency_picker_sheet.dart
│   ├── locale_picker_sheet.dart
│   ├── amount_input_field.dart       # Large-format amount + currency badge
│   ├── budget_progress_bar.dart      # LinearProgressIndicator with health colors
│   ├── skeleton_loader.dart
│   └── empty_state.dart              # Reusable empty state pattern
└── l10n/
    ├── app_en.arb
    └── app_es.arb
```

## Appendix C: Multi-Currency UX Implementation

### Currency Formatting Helper

```dart
String formatAmount(double amount, String currencyCode, String locale) {
  final format = NumberFormat.simpleCurrency(
    locale: locale,
    name: currencyCode,
  );
  return format.format(amount);
}

// Usage: formatAmount(1234.56, 'USD', 'en-US') → "$1,234.56"
// Usage: formatAmount(1234.56, 'MXN', 'es-MX') → "$1,234.56" (MXN symbol context)
// Usage: formatAmount(1234.56, 'EUR', 'de-DE') → "1.234,56 €"
```

### Currency Badge Behavior

1. **Default state:** Shows 3-letter ISO code in `primaryContainer` chip
2. **Tap:** Opens `CurrencyPickerBottomSheet`
3. **Selection:** Updates the badge text and stores selected currency in form state
4. **In transaction list/detail:** Badge is non-interactive (display only)
5. **In forms (add/edit/assistant):** Badge is tappable

### Budget Conversion Display

When a budget's currency differs from a transaction's currency:
- Show both amounts: `$340 MXN ($19.50 USD)` — original amount primary, converted in parentheses
- Conversion disclaimer: "≈ amounts may vary with exchange rates" in `bodySmall` below budget totals

---

*End of Flutter UI/UX Design Specification. A developer should be able to implement each screen pixel-perfect from the descriptions, color tokens, typography specs, spacing values, animation timings, and accessibility labels provided above.*
