# Design: Onboarding Profiling Wizard

**Date:** 2026-05-07
**Status:** Draft
**Scope:** `app/lib/screens/onboarding/`, `app/lib/screens/transactions/widgets/quick_preset_chips.dart`, `app/lib/widgets/main_shell.dart`, `app/lib/widgets/speed_dial_fab.dart`, `app/lib/core/constants/category_icons.dart`, `src/Conscia.Domain/`, `src/Conscia.Application/`, `src/Conscia.Infrastructure/`, `src/Conscia.Api/`

---

## Overview

After sign-up and currency/locale setup, users see a 3-screen profiling wizard that personalises their budget setup. All screens are skippable. The collected data seeds the user's first budgets and is persisted so insights can use it later.

This spec also covers five cleanup/improvement tasks that travel with this feature:
- Platform-adaptive icon system: Cupertino icons on iOS, Material icons on Android/web
- Move Scan Receipt from the speed dial FAB to a prominent centre button in the main shell bottom nav
- Migrate Quick Add preset chips from emoji strings to adaptive `IconData` (consistency)
- Delete dead code: `BehaviorProfile` and `SessionCache` entities, repos, DI registrations, and DynamoDB table entries
- Integrate the existing `apple_button.dart` and `google_button.dart` files into the sign-in/sign-up screens

---

## Platform-Adaptive Icon System

All icons throughout the app — navigation, category chips, profiling wizard, quick add — use platform-adaptive icons: **Cupertino on iOS, Material on Android/web**.

### Helper (`app/lib/core/constants/app_icons.dart` — new file)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppIcons {
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static IconData adaptive({
    required IconData material,
    required IconData cupertino,
  }) => _isIOS ? cupertino : material;

  // Navigation
  static IconData get home => adaptive(material: Icons.home_outlined, cupertino: CupertinoIcons.house);
  static IconData get homeActive => adaptive(material: Icons.home, cupertino: CupertinoIcons.house_fill);
  static IconData get transactions => adaptive(material: Icons.receipt_long_outlined, cupertino: CupertinoIcons.list_bullet);
  static IconData get transactionsActive => adaptive(material: Icons.receipt_long, cupertino: CupertinoIcons.list_bullet);
  static IconData get scan => adaptive(material: Icons.document_scanner_outlined, cupertino: CupertinoIcons.camera_viewfinder);
  static IconData get assistant => adaptive(material: Icons.auto_awesome_outlined, cupertino: CupertinoIcons.sparkles);
  static IconData get assistantActive => adaptive(material: Icons.auto_awesome, cupertino: CupertinoIcons.sparkles);
  static IconData get settings => adaptive(material: Icons.settings_outlined, cupertino: CupertinoIcons.settings);
  static IconData get settingsActive => adaptive(material: Icons.settings, cupertino: CupertinoIcons.settings_solid);

  // Actions
  static IconData get add => adaptive(material: Icons.add, cupertino: CupertinoIcons.add);
  static IconData get close => adaptive(material: Icons.close, cupertino: CupertinoIcons.xmark);
  static IconData get edit => adaptive(material: Icons.edit_outlined, cupertino: CupertinoIcons.pencil);
  static IconData get check => adaptive(material: Icons.check, cupertino: CupertinoIcons.checkmark);
  static IconData get chevronRight => adaptive(material: Icons.chevron_right, cupertino: CupertinoIcons.chevron_right);

  // Profile / wizard
  static IconData get saver => adaptive(material: Icons.savings, cupertino: CupertinoIcons.money_dollar_circle);
  static IconData get balanced => adaptive(material: Icons.balance, cupertino: CupertinoIcons.equal_circle);
  static IconData get freeSpender => adaptive(material: Icons.celebration, cupertino: CupertinoIcons.star);
  static IconData get employed => adaptive(material: Icons.work, cupertino: CupertinoIcons.briefcase);
  static IconData get selfEmployed => adaptive(material: Icons.laptop, cupertino: CupertinoIcons.device_laptop);
  static IconData get student => adaptive(material: Icons.school, cupertino: CupertinoIcons.book);
  static IconData get retired => adaptive(material: Icons.beach_access, cupertino: CupertinoIcons.sun_max);
  static IconData get other => adaptive(material: Icons.more_horiz, cupertino: CupertinoIcons.ellipsis);
  static IconData get person => adaptive(material: Icons.person, cupertino: CupertinoIcons.person);
  static IconData get couple => adaptive(material: Icons.people, cupertino: CupertinoIcons.person_2);
  static IconData get family => adaptive(material: Icons.family_restroom, cupertino: CupertinoIcons.person_3);
  static IconData get sharedHome => adaptive(material: Icons.home, cupertino: CupertinoIcons.house);
}
```

### `CategoryIcons` update (`app/lib/core/constants/category_icons.dart`)

Add a parallel Cupertino map and update `forCategory()` to return the adaptive icon:

```dart
static const Map<String, IconData> _cupertinoMap = {
  'Groceries': CupertinoIcons.cart,
  'Dining': CupertinoIcons.fork_knife,
  'Transport': CupertinoIcons.car,
  'Gaming': CupertinoIcons.gamecontroller,
  'Entertainment': CupertinoIcons.film,
  'Shopping': CupertinoIcons.bag,
  'Health': CupertinoIcons.heart,
  'Bills': CupertinoIcons.doc_text,
  'Education': CupertinoIcons.book,
  'Travel': CupertinoIcons.airplane,
  'Coffee': CupertinoIcons.cup_and_saucer,
  'Subscriptions': CupertinoIcons.arrow_2_circlepath,
};

static IconData forCategory(String category) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return _cupertinoMap[category] ?? CupertinoIcons.ellipsis_circle;
  }
  return map[category] ?? Icons.more_horiz;
}
```

All existing call sites (`CategoryIcons.forCategory(name)`) remain unchanged — the platform selection is internal.

---

## Main Shell — Scan Centre Button

### Layout change (`app/lib/widgets/main_shell.dart`)

Replace the current `NavigationBar` + `SpeedDialFab` with a `BottomAppBar` that has a notch and a centred `FloatingActionButton` for Scan:

**Mobile layout:**

```
╔══════════════════════════════════════════╗
║  [Home]  [Transactions]  ○  [AI] [⚙️]   ║
╚══════════════╤═══════════╧══════════════╝
               │ ⬛ Scan (FAB, pops above)
```

- `FloatingActionButton` at `FloatingActionButtonLocation.centerDocked` with `BottomAppBar(shape: CircularNotchedRectangle(), notchMargin: 8)`
- FAB uses `AppIcons.scan` icon, primary colour background, slightly larger than standard (size 56)
- 4 nav items split 2 left / 2 right of the notch, using `AppIcons` getters
- Selected state: colour change (primary) + active icon, no label change
- Tapping FAB navigates to `/scan` (existing route)

**Wide (> 840 px) layout:** Keep the existing `NavigationRail`. Add Scan as a rail destination between Transactions and Assistant, using a standard icon (no special emphasis — the notch effect only works on mobile). Remove the `SpeedDialFab` leading widget.

### `SpeedDialFab` update (`app/lib/widgets/speed_dial_fab.dart`)

Remove the "Scan Receipt" `SpeedDialChild`. Remaining children: "Ask Conscia" and "Add Expense". The FAB is no longer shown in `MainShell` (it was conditionally shown on Home and Transactions); those tabs now only need the `BottomAppBar` notch layout. The `SpeedDialFab` widget is retained for the speed dial actions only, rendered as the `floatingActionButton` slot is now occupied by the Scan FAB — so the speed dial moves to a secondary FAB or is removed entirely.

> **Decision:** Since the notch FAB occupies `centerDocked`, there's no standard slot for a second FAB. Remove `SpeedDialFab` entirely. "Add Expense" and "Ask Conscia" are reachable via the bottom nav tabs directly. If a quick-add shortcut is needed in a future iteration, it can be a `+` button in the `AppBar` of the Transactions screen.

---

## Onboarding Flow

```
OnboardingScreen (slides)
  → SignUpScreen / SignInScreen  (with Google + Apple buttons)
    → SetupScreen (currency/locale)          ← existing
      → SpendingProfileScreen  (Step 1 of 3, skippable)  ← new
        → SuggestedBudgetsScreen (Step 2 of 3, skippable) ← new
          → AboutYouScreen (Step 3 of 3, optional)        ← new
            → Dashboard (/)
```

`SetupScreen` currently calls `context.go('/')` on save. Change it to `context.go('/onboarding/profile')` instead. After any wizard screen navigates to `/` (skip or finish), `markOnboardingComplete()` is called as normal.

### New routes (add to `app_router.dart`)

```
/onboarding/profile    → SpendingProfileScreen
/onboarding/budgets    → SuggestedBudgetsScreen
/onboarding/about      → AboutYouScreen
```

All three routes are accessible only when authenticated (the router's existing auth guard covers this; they live under the `/onboarding` prefix which is already exempt from the "go to sign-in" redirect).

---

## Screen 1 — Spending Profile (`spending_profile_screen.dart`)

**Header:** "How do you spend?"  
**Subheader:** "Helps us suggest realistic budgets"  
**Top-right:** "Step 1 of 3 · Skip" (tapping Skip goes to `/onboarding/about`)

### Spending style selector (required for budget generation, but skippable overall)

Three horizontally-arranged tappable cards:

| Label | Icon | Value stored |
|---|---|---|
| Saver | `AppIcons.saver` | `saver` |
| Balanced | `AppIcons.balanced` | `balanced` |
| Free spender | `AppIcons.freeSpender` | `free_spender` |

Default selection: `balanced`.

### Monthly income range (optional within the screen)

Vertically-stacked selectable list items:

| Label | Bracket key | USD midpoint |
|---|---|---|
| Under ₱20,000 (or local equiv) | `low` | 300 |
| ₱20,000–₱50,000 | `mid` | 700 |
| ₱50,000–₱100,000 | `high` | 1400 |
| Over ₱100,000 | `very_high` | 2500 |
| Prefer not to say | `prefer_not_to_say` | — |

The Flutter UI formats bracket thresholds using the user's preferred currency via the existing `userPreferencesProvider` + `NumberFormat.currency`. The USD thresholds in the table are what the backend uses to compute budget amounts; the Flutter app sends the bracket key, not an amount.

**Next →** button advances to `/onboarding/budgets`.  
If personality is selected but income is not, treat income as `prefer_not_to_say`.  
If neither is selected and user taps Next, treat both as defaults (`balanced`, `mid`).

---

## Screen 2 — Suggested Budgets (`suggested_budgets_screen.dart`)

**Header:** "Your suggested budgets"  
**Subheader:** "Based on [Personality] · [Income label]. Tap to edit."  
**Top-right:** "Step 2 of 3 · Skip" (Skip goes to `/onboarding/about`)

### Budget suggestion algorithm (computed on the Flutter side)

```
spendingBudget = incomeMidpointUsd × fxRate × personalityFactor
```

**Personality factors:**
- Saver: 0.60
- Balanced: 0.70
- Free spender: 0.85

**Category weights per personality (top 5):**

| Category | Saver | Balanced | Free spender |
|---|---|---|---|
| Groceries | 28% | 28% | 15% |
| Bills | 25% | 20% | 12% |
| Dining | 10% | 18% | 22% |
| Transport | 15% | 14% | 12% |
| Shopping | 7% | 10% | 15% |
| Entertainment | — | — | 14% |
| Health | 15% | — | 10% |

Top 5 per personality are selected automatically. The category list is displayed with icons from `CategoryIcons.forCategory(categoryName)` (adaptive — Cupertino on iOS, Material elsewhere).

Each row shows: `[Icon] Category name` on the left, editable amount on the right. Tapping the amount opens a bottom sheet with a numeric input. The "+" button at the bottom lets the user add extra categories (opens the existing `CategoryPicker` widget).

**"Create budgets →"** button:
- For each category in the list with a non-zero amount, calls `POST /api/budgets` (existing endpoint) with `{ categoryName, limit }`.
- On success, navigates to `/onboarding/about`.
- On error, shows a `SnackBar` and stays on screen.

If income bracket is `prefer_not_to_say`, compute using `mid` midpoint.  
If no fx rate is available yet, show amounts as `—` and disable the Create button with a "Rates unavailable" message.

---

## Screen 3 — About You (`about_you_screen.dart`)

**Header:** "A bit more about you"  
**Subheader:** "All optional. Helps us personalise your experience."  
**Top-right:** "Step 3 of 3 · Skip" (Skip goes to `/`)

### Occupation type (multi-chip, single-select)

| Label | `AppIcons.*` | Value stored |
|---|---|---|
| Employed | `AppIcons.employed` | `employed` |
| Self-employed | `AppIcons.selfEmployed` | `self_employed` |
| Student | `AppIcons.student` | `student` |
| Retired | `AppIcons.retired` | `retired` |
| Other | `AppIcons.other` | `other` |

### Household size (multi-chip, single-select)

| Label | `AppIcons.*` | Value stored |
|---|---|---|
| Just me | `AppIcons.person` | `solo` |
| Couple | `AppIcons.couple` | `couple` |
| Family | `AppIcons.family` | `family` |
| Shared | `AppIcons.sharedHome` | `shared` |

**"Go to dashboard 🎉"** button:
- Calls `PATCH /api/users/profile` with `{ spendingPersonality, incomeRange, occupationType, householdSize }` (all nullable; only sends fields that were selected).
- Calls `markOnboardingComplete()`.
- Navigates to `/`.

Skip logic summary:
- Step 1 Skip → `/onboarding/about` (user skips personality/income but still fills in About You)
- Step 2 Skip → `/onboarding/about` (user skips budget creation but still fills in About You)
- Step 3 Skip → `/` (user skips demographics; `markOnboardingComplete()` called)

When Skip is tapped on Step 1 or Step 2, persist whatever was already selected before navigating away (best-effort `PATCH /api/users/profile` call, fire-and-forget).

---

## Backend — User Entity Changes

### New columns on `User` (all nullable strings)

```csharp
public string? SpendingPersonality { get; set; }   // "saver" | "balanced" | "free_spender"
public string? IncomeRange { get; set; }           // "low" | "mid" | "high" | "very_high" | "prefer_not_to_say"
public string? OccupationType { get; set; }        // "employed" | "self_employed" | "student" | "retired" | "other"
public string? HouseholdSize { get; set; }         // "solo" | "couple" | "family" | "shared"
```

Values are stored as lowercase strings (not enums) to avoid migration churn if new values are added later.

### EF Core migration

Add a migration: `AddUserProfileFields`. Four nullable `varchar(50)` columns on the `Users` table. No data backfill needed.

### API endpoint

Extend `PATCH /api/users/profile` (or `PUT /api/users/profile` if that's the existing pattern) to accept and persist the four new fields. All four are optional in the request body.

The existing `updateProfile` in `UserService` (Flutter) sends `preferredCurrency` and `locale`. Extend the Dart `UserService.updateProfile()` method to accept the four new nullable fields and include them in the request body when non-null.

---

## Google + Apple Sign-In Integration

`apple_button.dart` and `google_button.dart` already exist in the working tree. Add them to `sign_up_screen.dart` and `sign_in_screen.dart` with a visual separator ("— or —") between the email form and the social buttons.

The button widgets handle their own auth flow and should call the same `authProvider.notifier.login()` method after receiving a token, so the router redirect picks them up automatically.

> **Note:** The actual OAuth flow implementation (plugin configuration, token exchange) is out of scope for this spec. This spec covers UI placement only; if the buttons are not yet functional, they should be visible but disabled with a `TODO` comment.

---

## Quick Add Icon Consistency (`quick_preset_chips.dart`)

`QuickPresetChips` currently uses a hardcoded emoji map. Replace it with `CategoryIcons.forCategory()` (which is now platform-adaptive):

```dart
// Remove _categoryIcons map.
// In the Row builder:
final icon = CategoryIcons.forCategory(cat);
child: FilterChip(
  avatar: Icon(icon, size: 16),
  label: Text(cat),
  selected: selectedCategory == cat,
  onSelected: (_) => onCategorySelected(cat),
),
```

Use `avatar:` (not inside `label`) so the icon renders at the correct size and doesn't conflict with the chip's selected-state indicator.

---

## Dead Code Deletion

### Files to delete

- `src/Conscia.Domain/Entities/BehaviorProfile.cs`
- `src/Conscia.Application/Interfaces/IBehaviorProfileRepository.cs`
- `src/Conscia.Infrastructure/Repositories/BehaviorProfileRepository.cs`
- `src/Conscia.Application/Interfaces/ISessionCacheRepository.cs`
- `src/Conscia.Infrastructure/Repositories/SessionCacheRepository.cs`

### DI registrations to remove (`src/Conscia.Api/Program.cs`)

Remove the `builder.Services.AddScoped<IBehaviorProfileRepository, BehaviorProfileRepository>()` and the equivalent `ISessionCacheRepository` registration.

### DynamoDB table entries to remove

- `tools/DynamoSetup/Program.cs`: remove `BehaviorProfile` and `SessionCache` table creation blocks
- `infra/src/Conscia.Infra/DatabaseStack.cs`: remove the corresponding CDK table constructs

### Why SessionCache is safe to delete

Session timeout is handled entirely by the Dio interceptor in `dio_client.dart`: on a 401 response, all tokens are cleared from `FlutterSecureStorage` and the auth state is set to logged-out. The refresh token endpoint exists (`auth/refresh`) but is not currently called — when refresh is implemented in the future, it will live in the Dio interceptor, not SessionCache.

---

## Profile Data in Insights

The four new fields (`spendingPersonality`, `incomeRange`, `occupationType`, `householdSize`) are returned in `GET /api/users/profile` and available via `currentUserProvider`. The existing insights providers (`categoryFrequencyProvider`, regret providers, etc.) do not need to change for this feature — the data is simply available for future segmentation. No insights changes are in scope here.

---

## What's Out of Scope

- Actual OAuth token exchange for Google/Apple (UI placement only)
- Insights segmentation by demographic fields (data is stored; no UI changes to insights screens)
- Budget reset or re-profiling flow (Settings → "Redo profile setup" is a future feature)
- Income bracket currency conversion via live exchange rates for non-PHP users (the app formats the label amounts client-side using `NumberFormat.currency`; the backend receives the bracket key only)
- JWT refresh token implementation (future; the Dio interceptor currently logs out on 401)
