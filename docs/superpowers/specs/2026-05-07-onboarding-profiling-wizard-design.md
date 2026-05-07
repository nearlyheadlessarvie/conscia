# Design: Onboarding Profiling Wizard

**Date:** 2026-05-07
**Status:** Draft
**Scope:** `app/lib/screens/onboarding/`, `app/lib/screens/transactions/`, `app/lib/screens/settings/`, `app/lib/widgets/main_shell.dart`, `app/lib/widgets/speed_dial_fab.dart`, `app/lib/core/constants/`, `src/Conscia.Domain/`, `src/Conscia.Application/`, `src/Conscia.Infrastructure/`, `src/Conscia.Api/`

---

## Overview

After sign-up and currency/locale setup, users see a 3-screen profiling wizard that personalises their budget setup. All screens are skippable. The collected data seeds the user's first budgets and is persisted so insights can use it later. Onboarding completion is tracked explicitly on the backend via a `HasCompletedOnboarding` flag on `User`; the client does not infer onboarding state from optional profile fields.

This spec also covers seven cleanup/improvement tasks that travel with this feature:
- Platform-adaptive icon system: Cupertino icons on iOS, Material icons on Android/web
- Move Scan Receipt to a visually prominent centre nav item; replace speed dial with a plain Add Expense FAB
- Redesign the transaction form: consolidated category picker, collapsed secondary fields
- Migrate Quick Add preset chips from emoji strings to adaptive `IconData` (consistency)
- Settings > Profile screen: editable view of all four profile fields post-onboarding
- Delete dead code: `BehaviorProfile` and `SessionCache` entities, repos, DI registrations, and DynamoDB table entries
- Keep Google/Apple entry points on the sign-in screen only; social sign-in may create a new backend user and then route into onboarding when `HasCompletedOnboarding == false`

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

## Main Shell — Scan Centre Button + Add Expense FAB

### Layout change (`app/lib/widgets/main_shell.dart`)

**Mobile layout — 5-destination `NavigationBar`:**

```
╔════════════════════════════════════════════════╗
║  [Home]  [Trans]  [● Scan]  [AI]  [Settings]  ║
╚════════════════════════════════════════════════╝
                                          ⊕ (FAB)
```

- Keep `NavigationBar` (Material 3). Add Scan as the middle (index 2) `NavigationDestination`.
- The Scan destination uses a custom icon widget — a filled circle with the scan icon — so it visually pops against the other items without using the `floatingActionButton` slot:

```dart
NavigationDestination(
  icon: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: colorScheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(AppIcons.scan, size: 22, color: colorScheme.onPrimaryContainer),
  ),
  selectedIcon: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: colorScheme.primary,
      shape: BoxShape.circle,
    ),
    child: Icon(AppIcons.scan, size: 22, color: colorScheme.onPrimary),
  ),
  label: 'Scan',
),
```

- Tapping Scan navigates to `/scan` (existing route).
- The 5 nav items are: Home (0), Transactions (1), Scan (2), Assistant (3), Settings (4).
- `_selectedIndex` logic updates accordingly; Scan is never "selected" in the nav sense (navigating to `/scan` is a full-screen push, not a shell tab).

**Shell `floatingActionButton`:** Replace `SpeedDialFab` with a plain `FloatingActionButton`:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => context.push(AppRoutes.addTransaction),
  child: Icon(AppIcons.add),
),
```

Show the FAB on all tabs (always visible). This is the primary quick-add action. The app is an expense tracker — `+` always means Add Expense.

**Wide (> 840 px) layout:** Keep `NavigationRail`. Add Scan as a standard rail destination (index 2) between Transactions and Assistant, no special styling. Remove the `SpeedDialFab` leading widget; instead, add a regular `FloatingActionButton` as the `leading` widget that navigates to Add Transaction.

### `SpeedDialFab` deletion (`app/lib/widgets/speed_dial_fab.dart`)

Delete the file entirely. No replacement — the speed dial is removed. The three actions it contained are now covered by:
- **Scan Receipt** → Scan nav item (centre button)
- **Ask Conscia** → Assistant nav item
- **Add Expense** → shell FAB (`+`)

---

## Onboarding Flow

```
OnboardingScreen (slides)
  → SignUpScreen / SignInScreen
    → SetupScreen (currency/locale)          ← existing
      → SpendingProfileScreen  (Step 1 of 3, skippable)  ← new
        → SuggestedBudgetsScreen (Step 2 of 3, skippable) ← new
          → AboutYouScreen (Step 3 of 3, optional)        ← new
            → Dashboard (/)
```

`SetupScreen` currently calls `context.go('/')` on save. Change it to `context.go('/onboarding/profile')` instead. After any wizard screen navigates to `/` (skip or finish), `markOnboardingComplete()` is called as normal.

### Onboarding state source of truth

The source of truth for onboarding state is `User.HasCompletedOnboarding` on the backend. The client still keeps a local onboarding flag as a convenience cache, but authenticated routing must prefer the server-backed field once the current user profile has loaded.

While the authenticated profile is still loading, the router should avoid making a premature onboarding redirect from cached local state alone. This prevents returning users from being bounced into setup during the brief window before `/api/v1/users/me` resolves.

The client-side current-user fetch should also be scoped to the authenticated session rather than treated as a global cache. When the authenticated `userId` changes, the profile provider must re-fetch `/api/v1/users/me` so onboarding decisions and profile-driven UI always reflect the newly signed-in account.

This avoids two failure modes:
- Returning users on a new device should not be sent through onboarding again just because local storage is empty.
- Optional profile fields should remain optional and must not be used to infer whether onboarding is complete.

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
- Calls `PATCH /api/users/profile` with `{ spendingPersonality, incomeRange, occupationType, householdSize, hasCompletedOnboarding: true }` (all nullable except the onboarding flag).
- Calls `markOnboardingComplete()` after the backend update succeeds (or as best-effort fallback if the UI should not strand the user).
- Navigates to `/`.

Skip logic summary:
- Step 1 Skip → `/onboarding/about` (user skips personality/income but still fills in About You)
- Step 2 Skip → `/onboarding/about` (user skips budget creation but still fills in About You)
- Step 3 Skip → `/` (user skips demographics; `hasCompletedOnboarding` is still set to `true`)

When Skip is tapped on Step 1 or Step 2, persist whatever was already selected before navigating away (best-effort `PATCH /api/users/profile` call, fire-and-forget).

---

## Backend — User Entity Changes

### New columns on `User`

```csharp
public bool HasCompletedOnboarding { get; set; }
public string? SpendingPersonality { get; set; }   // "saver" | "balanced" | "free_spender"
public string? IncomeRange { get; set; }           // "low" | "mid" | "high" | "very_high" | "prefer_not_to_say"
public string? OccupationType { get; set; }        // "employed" | "self_employed" | "student" | "retired" | "other"
public string? HouseholdSize { get; set; }         // "solo" | "couple" | "family" | "shared"
```

Values are stored as lowercase strings (not enums) to avoid migration churn if new values are added later.
`HasCompletedOnboarding` defaults to `false` for new users and flips to `true` only when the wizard is completed or intentionally skipped at the final step.

### EF Core migration

Add a migration: `AddUserProfileFields`. Four nullable `varchar(50)` columns plus a non-null boolean `HasCompletedOnboarding` defaulting to `false` on the `Users` table. Existing users can be left at the default and will complete onboarding the next time the app routes them through the flow if desired.

### API endpoint

Extend `PATCH /api/users/profile` (or `PUT /api/users/profile` if that's the existing pattern) to accept and persist the four new fields plus `hasCompletedOnboarding`. The profile fields remain optional in the request body; the onboarding flag is also optional so callers can set it only when onboarding completion changes.

The existing `updateProfile` in `UserService` (Flutter) sends `preferredCurrency` and `locale`. Extend the Dart `UserService.updateProfile()` method to accept the four new nullable fields plus `hasCompletedOnboarding` and include them in the request body when non-null.

---

## Google + Apple Sign-In Integration

`apple_button.dart` and `google_button.dart` belong on `sign_in_screen.dart` only, with a visual separator ("— or —") between the email form and the social buttons. `sign_up_screen.dart` stays email/password only.

The social entrypoints handle sign-in-or-create-account semantics through the backend auth endpoints. If the backend needs to create a user record for a first-time social identity, it does so there. After the client receives tokens and fetches the current profile, the router sends the user into onboarding when `HasCompletedOnboarding == false`.

> **Note:** The actual OAuth flow implementation (plugin configuration, token exchange) is still out of scope here. This spec covers client routing/placement and the onboarding decision rule.

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

## Transaction Form Redesign (`transaction_form_screen.dart`)

The current form has two problems: the category picker appears twice (quick chips + full grid inline), and secondary fields (Location, Notes) take up as much space as primary ones. The redesign consolidates category into one interaction and collapses the optional fields.

### New layout order

```
AppBar: [✕]  Add Transaction / Edit Transaction
─────────────────────────────────────────────
[Expense ●] [Income  ] ← compact segmented toggle (same as now)

[Amount input — large, prominent]              (same as now)
[Exchange rate field, if foreign currency]     (same as now)

───── Category ─────────────────────────────
[AI suggestions row — PurchaseSuggestionChips]  (new add-only, moved up)
[Quick chips — recently used categories]        (icon + label, adaptive icon)
[● Selected: Groceries  ×]  ← shown when category selected, replaces chips
[+ More categories]  ← opens CategoryPicker bottom sheet

───── Details ──────────────────────────────
[🏪 Merchant (optional) ____  🎤]
[📅 Today  ›]   ← compact date row (tap to change)

[▸ More options]  ← ExpansionTile, collapsed by default
    [📍 Include Location  toggle]
    [Notes (optional) — single line, expands on tap]

─────────────────────────────────────────────
[       Save Transaction        ]   ← FilledButton
```

### Key changes from current

**1. Consolidated category selection**

Remove the inline `CategoryPicker` grid entirely from the form body. Replace with:
- `QuickPresetChips` as the only always-visible category selector (shows recently-used)
- When a category is selected, show a single chip: `[Icon] Groceries ×` (tapping `×` clears it)
- A `TextButton('+ More categories', onPressed: ...)` that opens `CategoryPicker` in a `showModalBottomSheet`
- `PurchaseSuggestionChips` moves above the quick chips (AI suggestions — more prominent placement)

This removes the redundant full-grid that was always shown below the chips.

**2. Date — compact row instead of ListTile**

Replace the `ListTile` with a lighter `InkWell`-wrapped row:

```dart
InkWell(
  onTap: _pickDate,
  borderRadius: BorderRadius.circular(12),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Icon(AppIcons.calendar, size: 18, color: colors.onSurfaceVariant),
      const SizedBox(width: 8),
      Text(_relativeDateLabel(_selectedDate), style: textTheme.bodyMedium),
      const Spacer(),
      Icon(AppIcons.chevronRight, size: 16, color: colors.outline),
    ]),
  ),
)
```

`_relativeDateLabel` returns "Today", "Yesterday", or the full date.

**3. Collapsed optional fields**

Wrap Location and Notes in an `ExpansionTile` labelled "More options" (collapsed by default). When editing a transaction that already has notes, auto-expand the tile.

**4. `CategoryPicker` as bottom sheet (not inline)**

`CategoryPicker` is unchanged internally. Wrap the call in `showModalBottomSheet` from a `TextButton`:

```dart
TextButton.icon(
  icon: Icon(AppIcons.add, size: 16),
  label: const Text('More categories'),
  onPressed: () => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      builder: (_, ctrl) => CategoryPicker(
        selected: _selectedCategory,
        onSelected: (cat) {
          setState(() => _selectedCategory = cat);
          Navigator.pop(context);
        },
        isExpense: _isExpense,
      ),
    ),
  ),
),
```

---



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

## Settings — Profile Screen

The current Settings > Profile section shows only email and "Member since [date]". Extend it to expose the four new profile fields so users can review and update them after onboarding.

### New screen: `app/lib/screens/settings/profile_screen.dart`

Accessible via a new `ListTile` in `SettingsScreen` under the Profile section:

```dart
ListTile(
  leading: Icon(AppIcons.person),
  title: const Text('My Profile'),
  subtitle: const Text('Spending style, income, household'),
  trailing: Icon(AppIcons.chevronRight),
  onTap: () => context.push('/settings/profile'),
),
```

New route in `app_router.dart`: `/settings/profile` → `ProfileScreen`.

### `ProfileScreen` layout

Loads `currentUserProvider` to pre-populate. Mirrors the wizard screens' UX (same chip selectors, same labels, same values). Has a "Save" button that calls `PATCH /api/users/profile`.

```
AppBar: [←]  My Profile

Email: nearlyheadlessarvie@gmail.com   (read-only, greyed out)
Member since: May 2026                 (read-only)

─── Spending Style ──────────────────────
[Saver]  [● Balanced]  [Free spender]   (same 3-card row as wizard)

─── Monthly Income ──────────────────────
[ ] Under X                             (same selectable list as wizard)
[●] X – Y
[ ] Y – Z
[ ] Over Z
[ ] Prefer not to say

─── Occupation ──────────────────────────
[Employed ●]  [Self-employed]  [Student]  [Retired]  [Other]

─── Household ───────────────────────────
[Just me]  [Couple ●]  [Family]  [Shared]

─────────────────────────────────────────
[       Save Changes       ]
```

Fields default to whatever is stored on `UserProfile`. If a field is null (user skipped it during onboarding), show it unselected. Saving calls `PATCH /api/users/profile` with only the changed fields, then calls `ref.invalidate(currentUserProvider)` and shows a success `SnackBar`.

### `UserProfile` model extension

The Dart `UserProfile` class (returned by `UserService.getProfile()`) must include the four new fields:

```dart
final String? spendingPersonality;
final String? incomeRange;
final String? occupationType;
final String? householdSize;
```

These are already returned by the API after the backend change; add them to the Dart model and `fromJson` parsing.

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
