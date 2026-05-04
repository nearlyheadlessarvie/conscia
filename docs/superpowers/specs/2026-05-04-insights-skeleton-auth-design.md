# Design: Insights Conditional Rendering, Skeleton Loading & Auth Button Branding

**Date:** 2026-05-04  
**Status:** Approved  
**Scope:** Flutter app (`app/`)

---

## 1. Insights — Conditional Rendering

### Problem
The "Your Insights" dashboard section always renders — header included — even when the backend is unreachable, the user has no data, or the API returns a failure. This surfaces a meaningless "Unable to load insights" message (or, once the backend exists, default-value cards) for users who don't yet have enough data to generate meaningful insights.

### Decision
Hide the entire "Your Insights" section (header + all three cards) whenever data is absent or insufficient. Show skeletons while loading, then either display cards or render nothing.

### Changes

**`app/lib/providers/behavioral_insights_provider.dart`**
- Change `FutureProvider<BehavioralInsights>` → `FutureProvider<BehavioralInsights?>`
- `BehavioralInsightsService.getBehavioralInsights()` wraps the API call in try/catch:
  - Any `DioException` → return `null`
  - HTTP 204 No Content → return `null`
  - Parse errors → return `null`
  - Valid response → return `BehavioralInsights.fromJson(...)`

**`app/lib/screens/dashboard/dashboard_screen.dart`**
- `insightsState.when(...)` updated:
  - `loading` → render section header + `InsightSkeletonSection`
  - `data(null)` → render nothing (no `SliverToBoxAdapter`, no header)
  - `data(insights)` → render section header + three insight cards (existing behavior)
  - `error` → render nothing (same as null; errors are already swallowed in the provider)
- The `_buildSectionHeader('Your Insights')` call moves inside each branch so it only appears when appropriate.

### Success Criteria
- New user with no backend data: "Your Insights" header and all cards are invisible.
- User with valid data: section renders normally.
- While fetching: section header + shimmer skeleton cards appear, then resolve.

---

## 2. Skeleton Loading Across the App

### Problem
Every loading state in the app uses `CircularProgressIndicator`, which gives no shape hint and causes significant layout shift when content loads.

### Decision
Replace all `CircularProgressIndicator` loading states with purpose-shaped shimmer skeletons using the existing `shimmer` package and `SkeletonLoader` base widget.

### New Widgets (extend `app/lib/widgets/skeleton_loader.dart`)

**`InsightSkeletonCard`**
- Height: ~100px, full width, `borderRadius: 12`
- Inner layout mirrors the real insight cards: a shimmer label line (120px wide, 12px tall) at top, a large shimmer heading (180px wide, 24px tall), two shimmer body lines
- Used three times stacked in `InsightSkeletonSection`

**`InsightSkeletonSection`**
- `Column` of three `InsightSkeletonCard` widgets separated by 12px gaps
- Wrapped in `SliverPadding(horizontal: 16)` for dashboard use
- This is what the dashboard renders while `insightsState` is loading

**`BudgetSkeletonCard`**
- Width: 180px, height: 140px, `borderRadius: 12`
- Inner layout: shimmer icon circle (40px), shimmer title line, shimmer progress bar, shimmer amount line
- Used in a horizontal `ListView` while budgets are loading (show 3 placeholders)

**`TransactionSkeletonTile`**
- Alias for the existing `SkeletonListTile` — no new widget needed, just use it consistently

### Replacement Audit

| Screen | Current state | New state |
|--------|--------------|-----------|
| Dashboard — insights loading | `CircularProgressIndicator` (160px box) | `InsightSkeletonSection` |
| Dashboard — budgets loading | `CircularProgressIndicator` (160px box) | 3× `BudgetSkeletonCard` in horizontal scroll |
| Dashboard — transactions loading | `CircularProgressIndicator` (200px box) | 5× `TransactionSkeletonTile` |
| Transaction list screen | `CircularProgressIndicator` | 8× `TransactionSkeletonTile` |
| Budgets screen | `CircularProgressIndicator` | 4× `BudgetSkeletonCard` in grid/list |
| Any other screen found during implementation | `CircularProgressIndicator` | Nearest matching skeleton widget |

### Notes
- Section headers for non-insights sections (Budgets, Recent Transactions, Reflect) continue to render during loading — only insights suppresses its header on null resolve.
- Skeletons respect dark mode via the existing `isDark` branch in `SkeletonLoader`.

### Success Criteria
- No `CircularProgressIndicator` remains in any screen's loading path.
- Each skeleton approximates the shape and size of the content it replaces.
- Dark mode skeletons use appropriate contrast colors.

---

## 3. Google / Apple Button Branding

### Problem
The Google sign-in button uses a plain text `"G"` character instead of Google's official logo. The Apple button is functionally correct but uses `OutlinedButton` which can be overridden by the theme. Neither button meets their platform's brand guidelines.

### Changes

**Google Sign-In Button**
- Add `assets/images/google_logo.svg` — the official four-color Google "G" SVG (from [Google Brand Resources](https://developers.google.com/identity/branding-guidelines))
- Create a private `_GoogleSignInButton` widget inside `sign_in_screen.dart`:
  - White background, 1dp grey border (`Color(0xFFDDDDDD)`), 12px border radius
  - `SvgPicture.asset('assets/images/google_logo.svg', width: 20, height: 20)` as the leading icon
  - Label: "Sign in with Google" in dark text (`Color(0xFF1F1F1F)`)
  - Full width, 48px height — matches the rest of the auth buttons
- Replaces the current `OutlinedButton.icon` with `"G"` text icon

**Apple Sign-In Button**
- Replace `OutlinedButton` with an explicit `ElevatedButton` using `backgroundColor: Colors.black`, `foregroundColor: Colors.white`
- This ensures the black background is not overridden by a light theme's `OutlinedButton` styling
- Keep `Icons.apple` icon and "Sign in with Apple" label
- Keep the `defaultTargetPlatform == TargetPlatform.iOS` guard

**`README.md` (root)**
- Add `## Social Authentication Setup` section covering:

  **Google**
  1. Create an OAuth 2.0 client ID at Google Cloud Console
  2. Add `google-services.json` to `app/android/app/`
  3. Add `GoogleService-Info.plist` to `app/ios/Runner/`
  4. Set the `WEB_CLIENT_ID` env var used by `google_sign_in`
  5. Backend: implement `POST /api/v1/auth/google` accepting `{ "idToken": string }`, verify with Google, return `{ accessToken, refreshToken, userId }`

  **Apple**
  1. Enable "Sign in with Apple" capability in Apple Developer portal for your App ID
  2. Add the capability in Xcode → Signing & Capabilities
  3. Backend: implement `POST /api/v1/auth/apple` accepting `{ "identityToken": string, "authorizationCode": string }`, verify with Apple, return `{ accessToken, refreshToken, userId }`
  4. Note: Apple sign-in is iOS-only in this app; the UI button is conditionally rendered

### Success Criteria
- Google button shows the four-color "G" SVG logo on a white pill button.
- Apple button shows white Apple logo on a solid black pill button regardless of theme.
- Root README has a clear Social Authentication Setup section a new developer can follow.

---

## Out of Scope
- Implementing the backend OAuth endpoints (`auth/google`, `auth/apple`)
- Configuring actual Google Cloud / Apple Developer credentials
- Any other Phase 1–8 features from the implementation plan
