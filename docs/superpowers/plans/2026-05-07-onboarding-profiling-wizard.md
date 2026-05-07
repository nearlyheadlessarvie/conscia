# Onboarding Profiling Wizard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 3-screen post-signup profiling wizard, platform-adaptive icons, a redesigned main shell (5-tab nav + scan button + plain Add Expense FAB), a cleaner transaction form, and a Settings > My Profile screen where users can update their spending profile. Onboarding state must be tracked explicitly by the backend with `HasCompletedOnboarding`, and social auth should live on sign-in only.

**Architecture:** Backend gains `HasCompletedOnboarding` plus 4 nullable string columns on `User` and an extended profile update endpoint. Flutter gains a new `AppIcons` helper and adaptive `CategoryIcons`, then the three wizard screens pass personality/income as go_router `extra` to avoid shared state. Profile data and onboarding state are persisted via the existing `PUT /api/v1/users/me` endpoint, authenticated routing should prefer the server-backed onboarding flag, the router should defer onboarding redirects until the current profile load completes, and the current-user provider should re-fetch when the authenticated `userId` changes so social sign-in and account switching cannot reuse stale profile data.

**Tech Stack:** Flutter (Riverpod, go_router, Dio), .NET 8 Minimal API, EF Core (Postgres), DynamoDB (for dead-code cleanup only).

---

## File Map

**Create:**
- `app/lib/core/constants/app_icons.dart` — platform-adaptive icon helper
- `app/lib/screens/onboarding/spending_profile_screen.dart` — wizard step 1
- `app/lib/screens/onboarding/suggested_budgets_screen.dart` — wizard step 2
- `app/lib/screens/onboarding/about_you_screen.dart` — wizard step 3
- `app/lib/screens/settings/profile_screen.dart` — post-onboarding profile editor

**Modify:**
- `src/Conscia.Domain/Entities/User.cs` — 4 new nullable string props
- `src/Conscia.Infrastructure/Migrations/*AddUserProfileFields*` — include onboarding flag default false
- `src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs` — varchar(50) configs
- `src/Conscia.Application/DTOs/UserProfileUpdateDto.cs` — 4 new nullable fields
- `src/Conscia.Application/Interfaces/IUserService.cs` — updated UpdateProfileAsync signature
- `src/Conscia.Application/Services/UserService.cs` — implementation update
- `src/Conscia.Api/Endpoints/UserEndpoints.cs` — pass DTO directly, return new fields in response
- `src/Conscia.Api/Program.cs` — remove 2 dead-code DI registrations
- `tools/DynamoSetup/Program.cs` — remove BehaviorProfiles + SessionCache table blocks
- `infra/src/Conscia.Infra/DatabaseStack.cs` — remove BehaviorProfilesTable + SessionCacheTable
- `app/lib/core/constants/category_icons.dart` — add Cupertino map + adaptive forCategory()
- `app/lib/core/routing/app_router.dart` — add 4 new routes + fix authenticated wizard redirect using `HasCompletedOnboarding`
- `app/lib/widgets/main_shell.dart` — 5-tab nav, Scan centre item, plain Add Expense FAB
- `app/lib/services/user_service.dart` — 4 new fields on UserProfile, extended updateProfile()
- `app/lib/screens/onboarding/setup_screen.dart` — redirect to /onboarding/profile instead of /
- `app/lib/screens/onboarding/sign_in_screen.dart` — keep Apple/Google buttons as the only social auth entrypoint
- `app/lib/screens/onboarding/sign_up_screen.dart` — remove Apple/Google buttons
- `app/lib/screens/transactions/widgets/quick_preset_chips.dart` — emoji → adaptive icons
- `app/lib/screens/transactions/transaction_form_screen.dart` — consolidated category, compact date, collapsed optional fields
- `app/lib/screens/settings/settings_screen.dart` — add My Profile tile + route

**Delete:**
- `app/lib/widgets/speed_dial_fab.dart`
- `src/Conscia.Domain/Entities/BehaviorProfile.cs`
- `src/Conscia.Application/Interfaces/IBehaviorProfileRepository.cs`
- `src/Conscia.Infrastructure/Repositories/BehaviorProfileRepository.cs`
- `src/Conscia.Application/Interfaces/ISessionCacheRepository.cs`
- `src/Conscia.Infrastructure/Repositories/SessionCacheRepository.cs`

---

## Task 1: Backend — Add 4 profile fields to User entity

**Files:**
- Modify: `src/Conscia.Domain/Entities/User.cs`
- Modify: `src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs`

- [ ] **Step 1: Add 4 nullable string properties to User**

Open `src/Conscia.Domain/Entities/User.cs`. Add after `public DateTime CreatedAt { get; set; } = DateTime.UtcNow;`:

```csharp
public string? SpendingPersonality { get; set; }   // "saver" | "balanced" | "free_spender"
public string? IncomeRange { get; set; }            // "low" | "mid" | "high" | "very_high" | "prefer_not_to_say"
public string? OccupationType { get; set; }         // "employed" | "self_employed" | "student" | "retired" | "other"
public string? HouseholdSize { get; set; }          // "solo" | "couple" | "family" | "shared"
```

- [ ] **Step 2: Configure varchar(50) in EF Core**

Open `src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs`. Add after the `Locale` property configuration:

```csharp
builder.Property(u => u.SpendingPersonality).HasMaxLength(50);
builder.Property(u => u.IncomeRange).HasMaxLength(50);
builder.Property(u => u.OccupationType).HasMaxLength(50);
builder.Property(u => u.HouseholdSize).HasMaxLength(50);
```

- [ ] **Step 3: Add EF Core migration**

```bash
cd src/Conscia.Infrastructure
dotnet ef migrations add AddUserProfileFields --startup-project ../Conscia.Api --context ConsciaDbContext
```

Expected: a new migration file in `Migrations/` with `AddColumn` calls for the four fields.

- [ ] **Step 4: Verify migration SQL**

Open the generated migration file and confirm it looks like:

```csharp
migrationBuilder.AddColumn<string>(
    name: "SpendingPersonality",
    table: "users",
    type: "character varying(50)",
    maxLength: 50,
    nullable: true);
// ... repeated for IncomeRange, OccupationType, HouseholdSize
```

- [ ] **Step 5: Apply migration (dev only)**

```bash
dotnet ef database update --startup-project ../Conscia.Api --context ConsciaDbContext
```

Expected: "Done."

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Domain/Entities/User.cs
git add src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs
git add src/Conscia.Infrastructure/Migrations/
git commit -m "feat: add spending profile fields to User entity"
```

---

## Task 2: Backend — Extend profile update DTO, service, and endpoint

**Files:**
- Modify: `src/Conscia.Application/DTOs/UserProfileUpdateDto.cs`
- Modify: `src/Conscia.Application/Interfaces/IUserService.cs`
- Modify: `src/Conscia.Application/Services/UserService.cs`
- Modify: `src/Conscia.Api/Endpoints/UserEndpoints.cs`

- [ ] **Step 1: Add 4 fields to UserProfileUpdateDto**

Replace `src/Conscia.Application/DTOs/UserProfileUpdateDto.cs` with:

```csharp
namespace Conscia.Application.DTOs;

public class UserProfileUpdateDto
{
    public string? PreferredCurrency { get; set; }
    public string? Locale { get; set; }
    public string? SpendingPersonality { get; set; }
    public string? IncomeRange { get; set; }
    public string? OccupationType { get; set; }
    public string? HouseholdSize { get; set; }
}
```

- [ ] **Step 2: Update IUserService to accept the DTO**

Open `src/Conscia.Application/Interfaces/IUserService.cs`. Change the `UpdateProfileAsync` signature from:

```csharp
Task<User> UpdateProfileAsync(Guid id, string? preferredCurrency, string? locale, CancellationToken ct = default);
```

To:

```csharp
Task<User> UpdateProfileAsync(Guid id, UserProfileUpdateDto dto, CancellationToken ct = default);
```

Add `using Conscia.Application.DTOs;` at the top if not already present.

- [ ] **Step 3: Update UserService implementation**

Open `src/Conscia.Application/Services/UserService.cs`. Replace the `UpdateProfileAsync` method body:

```csharp
public async Task<User> UpdateProfileAsync(Guid id, UserProfileUpdateDto dto, CancellationToken ct = default)
{
    var user = await _repo.GetByIdAsync(id, ct)
        ?? throw new KeyNotFoundException($"User {id} not found");

    if (dto.PreferredCurrency is not null) user.PreferredCurrency = dto.PreferredCurrency;
    if (dto.Locale is not null) user.Locale = dto.Locale;
    if (dto.SpendingPersonality is not null) user.SpendingPersonality = dto.SpendingPersonality;
    if (dto.IncomeRange is not null) user.IncomeRange = dto.IncomeRange;
    if (dto.OccupationType is not null) user.OccupationType = dto.OccupationType;
    if (dto.HouseholdSize is not null) user.HouseholdSize = dto.HouseholdSize;

    return await _repo.UpdateAsync(user, ct);
}
```

- [ ] **Step 4: Update UserEndpoints — PUT /me handler**

Open `src/Conscia.Api/Endpoints/UserEndpoints.cs`. In the `MapPut("/me", ...)` handler, replace the `svc.UpdateProfileAsync(...)` call and its response:

```csharp
group.MapPut("/me", async (
    HttpContext ctx,
    UserProfileUpdateDto dto,
    IUserService svc,
    IValidator<UserProfileUpdateDto> validator) =>
{
    var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
    if (!validation.IsValid)
        return Results.ValidationProblem(validation.ToDictionary());

    var userId = ctx.User.GetUserId();
    var user = await svc.UpdateProfileAsync(userId, dto, ctx.RequestAborted);
    return Results.Ok(new
    {
        user.Id,
        user.Email,
        user.PreferredCurrency,
        user.Locale,
        user.CreatedAt,
        user.SpendingPersonality,
        user.IncomeRange,
        user.OccupationType,
        user.HouseholdSize,
    });
}).WithName("UpdateCurrentUser");
```

- [ ] **Step 5: Update GET /me to also return new fields**

In the same file, update the `MapGet("/me", ...)` handler response:

```csharp
return Results.Ok(new
{
    user.Id,
    user.Email,
    user.PreferredCurrency,
    user.Locale,
    user.CreatedAt,
    user.SpendingPersonality,
    user.IncomeRange,
    user.OccupationType,
    user.HouseholdSize,
});
```

- [ ] **Step 6: Build to confirm no compile errors**

```bash
cd src/Conscia.Api
dotnet build
```

Expected: `Build succeeded.`

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/DTOs/UserProfileUpdateDto.cs
git add src/Conscia.Application/Interfaces/IUserService.cs
git add src/Conscia.Application/Services/UserService.cs
git add src/Conscia.Api/Endpoints/UserEndpoints.cs
git commit -m "feat: extend profile update endpoint with spending profile fields"
```

---

## Task 3: Backend — Delete dead code (BehaviorProfile + SessionCache)

**Files:**
- Delete: `src/Conscia.Domain/Entities/BehaviorProfile.cs`
- Delete: `src/Conscia.Application/Interfaces/IBehaviorProfileRepository.cs`
- Delete: `src/Conscia.Infrastructure/Repositories/BehaviorProfileRepository.cs`
- Delete: `src/Conscia.Application/Interfaces/ISessionCacheRepository.cs`
- Delete: `src/Conscia.Infrastructure/Repositories/SessionCacheRepository.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Modify: `tools/DynamoSetup/Program.cs`
- Modify: `infra/src/Conscia.Infra/DatabaseStack.cs`

- [ ] **Step 1: Delete the 5 dead-code files**

```bash
git rm src/Conscia.Domain/Entities/BehaviorProfile.cs
git rm src/Conscia.Application/Interfaces/IBehaviorProfileRepository.cs
git rm src/Conscia.Infrastructure/Repositories/BehaviorProfileRepository.cs
git rm src/Conscia.Application/Interfaces/ISessionCacheRepository.cs
git rm src/Conscia.Infrastructure/Repositories/SessionCacheRepository.cs
```

- [ ] **Step 2: Remove DI registrations from Program.cs**

Open `src/Conscia.Api/Program.cs`. Remove these two lines (around line 137 and 145):

```csharp
builder.Services.AddScoped<IBehaviorProfileRepository, BehaviorProfileRepository>();
// ...
builder.Services.AddScoped<ISessionCacheRepository, SessionCacheRepository>();
```

Also remove the `using` directives for those namespaces if they are now unused (the compiler will warn you).

- [ ] **Step 3: Remove BehaviorProfiles from DynamoSetup**

Open `tools/DynamoSetup/Program.cs`. Delete the BehaviorProfiles block (lines ~81–94):

```csharp
// ---------------- BEHAVIOR PROFILE ----------------
("BehaviorProfiles", new CreateTableRequest
{
    TableName = "BehaviorProfiles",
    KeySchema = [new("PK", KeyType.HASH)],
    AttributeDefinitions = [new("PK", ScalarAttributeType.S)],
    BillingMode = BillingMode.PAY_PER_REQUEST
}),
```

Also delete the SessionCache block (lines ~194–207):

```csharp
// ---------------- SESSION CACHE ----------------
("SessionCache", new CreateTableRequest
{
    TableName = "SessionCache",
    KeySchema = [new("PK", KeyType.HASH)],
    AttributeDefinitions = [new("PK", ScalarAttributeType.S)],
    BillingMode = BillingMode.PAY_PER_REQUEST
}),
```

If there is a TTL-enable call for SessionCache after the table creation loop, delete that too (search for `"SessionCache"` in the file).

- [ ] **Step 4: Remove CDK table constructs from DatabaseStack.cs**

Open `infra/src/Conscia.Infra/DatabaseStack.cs`. Delete these blocks (lines ~100–109):

```csharp
BehaviorProfilesTable = CreateTable(
    "BehaviorProfiles",
    "PK"
);

SessionCacheTable = CreateTable(
    "SessionCache",
    "PK",
    ttl: "TTL"
);
```

Also delete any public property declarations for `BehaviorProfilesTable` and `SessionCacheTable` (they will be near the top of the class).

- [ ] **Step 5: Build to confirm**

```bash
cd src/Conscia.Api
dotnet build
```

Expected: `Build succeeded.` with no errors about missing types.

- [ ] **Step 6: Commit**

```bash
git add -u
git commit -m "chore: delete BehaviorProfile and SessionCache dead code"
```

---

## Task 4: Flutter — Extend UserProfile model and UserService

**Files:**
- Modify: `app/lib/services/user_service.dart`

- [ ] **Step 1: Add 4 nullable fields to UserProfile**

Open `app/lib/services/user_service.dart`. Replace the entire file with:

```dart
import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class UserProfile {
  final String id;
  final String email;
  final String currencyCode;
  final String locale;
  final DateTime createdAt;
  final String? spendingPersonality;
  final String? incomeRange;
  final String? occupationType;
  final String? householdSize;

  const UserProfile({
    required this.id,
    required this.email,
    required this.currencyCode,
    required this.locale,
    required this.createdAt,
    this.spendingPersonality,
    this.incomeRange,
    this.occupationType,
    this.householdSize,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      currencyCode:
          (json['currencyCode'] ?? json['preferredCurrency']) as String? ??
              'USD',
      locale: json['locale'] as String? ?? 'en_US',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      spendingPersonality: json['spendingPersonality'] as String?,
      incomeRange: json['incomeRange'] as String?,
      occupationType: json['occupationType'] as String?,
      householdSize: json['householdSize'] as String?,
    );
  }
}

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<UserProfile> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
  }) async {
    final response = await _dio.put(
      ApiConstants.profile,
      data: {
        if (preferredCurrency != null) 'preferredCurrency': preferredCurrency,
        if (locale != null) 'locale': locale,
        if (spendingPersonality != null) 'spendingPersonality': spendingPersonality,
        if (incomeRange != null) 'incomeRange': incomeRange,
        if (occupationType != null) 'occupationType': occupationType,
        if (householdSize != null) 'householdSize': householdSize,
      },
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
```

- [ ] **Step 2: Verify app still compiles**

```bash
cd app
flutter analyze
```

Expected: no new errors (existing callers of `updateProfile` used named params, so they still work).

- [ ] **Step 3: Commit**

```bash
git add app/lib/services/user_service.dart
git commit -m "feat: add profile fields to UserProfile model and UserService"
```

---

## Task 5: Flutter — AppIcons adaptive icon helper

**Files:**
- Create: `app/lib/core/constants/app_icons.dart`

- [ ] **Step 1: Create the file**

```dart
// app/lib/core/constants/app_icons.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppIcons {
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static IconData adaptive({
    required IconData material,
    required IconData cupertino,
  }) =>
      _isIOS ? cupertino : material;

  // ── Navigation ────────────────────────────────────────────────────
  static IconData get home =>
      adaptive(material: Icons.home_outlined, cupertino: CupertinoIcons.house);
  static IconData get homeActive =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house_fill);
  static IconData get transactions => adaptive(
      material: Icons.receipt_long_outlined,
      cupertino: CupertinoIcons.list_bullet);
  static IconData get transactionsActive => adaptive(
      material: Icons.receipt_long, cupertino: CupertinoIcons.list_bullet);
  static IconData get scan => adaptive(
      material: Icons.document_scanner_outlined,
      cupertino: CupertinoIcons.camera_viewfinder);
  static IconData get assistant => adaptive(
      material: Icons.auto_awesome_outlined,
      cupertino: CupertinoIcons.sparkles);
  static IconData get assistantActive =>
      adaptive(material: Icons.auto_awesome, cupertino: CupertinoIcons.sparkles);
  static IconData get settings => adaptive(
      material: Icons.settings_outlined, cupertino: CupertinoIcons.settings);
  static IconData get settingsActive =>
      adaptive(material: Icons.settings, cupertino: CupertinoIcons.settings_solid);

  // ── Actions ───────────────────────────────────────────────────────
  static IconData get add =>
      adaptive(material: Icons.add, cupertino: CupertinoIcons.add);
  static IconData get close =>
      adaptive(material: Icons.close, cupertino: CupertinoIcons.xmark);
  static IconData get edit => adaptive(
      material: Icons.edit_outlined, cupertino: CupertinoIcons.pencil);
  static IconData get check =>
      adaptive(material: Icons.check, cupertino: CupertinoIcons.checkmark);
  static IconData get chevronRight => adaptive(
      material: Icons.chevron_right, cupertino: CupertinoIcons.chevron_right);
  static IconData get calendar => adaptive(
      material: Icons.calendar_today, cupertino: CupertinoIcons.calendar);
  static IconData get person =>
      adaptive(material: Icons.person, cupertino: CupertinoIcons.person);

  // ── Profile / wizard ──────────────────────────────────────────────
  static IconData get saver => adaptive(
      material: Icons.savings, cupertino: CupertinoIcons.money_dollar_circle);
  static IconData get balanced => adaptive(
      material: Icons.balance, cupertino: CupertinoIcons.equal_circle);
  static IconData get freeSpender =>
      adaptive(material: Icons.celebration, cupertino: CupertinoIcons.star);
  static IconData get employed =>
      adaptive(material: Icons.work, cupertino: CupertinoIcons.briefcase);
  static IconData get selfEmployed => adaptive(
      material: Icons.laptop, cupertino: CupertinoIcons.device_laptop);
  static IconData get student =>
      adaptive(material: Icons.school, cupertino: CupertinoIcons.book);
  static IconData get retired => adaptive(
      material: Icons.beach_access, cupertino: CupertinoIcons.sun_max);
  static IconData get other =>
      adaptive(material: Icons.more_horiz, cupertino: CupertinoIcons.ellipsis);
  static IconData get couple =>
      adaptive(material: Icons.people, cupertino: CupertinoIcons.person_2);
  static IconData get family => adaptive(
      material: Icons.family_restroom, cupertino: CupertinoIcons.person_3);
  static IconData get sharedHome =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house);
}
```

- [ ] **Step 2: Verify no import errors**

```bash
cd app
flutter analyze lib/core/constants/app_icons.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/constants/app_icons.dart
git commit -m "feat: add AppIcons platform-adaptive icon helper"
```

---

## Task 6: Flutter — CategoryIcons adaptive (Cupertino on iOS)

**Files:**
- Modify: `app/lib/core/constants/category_icons.dart`

- [ ] **Step 1: Replace the file with adaptive version**

```dart
// app/lib/core/constants/category_icons.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> map = {
    'Groceries': Icons.shopping_cart,
    'Dining': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Gaming': Icons.videogame_asset,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Health': Icons.favorite,
    'Bills': Icons.receipt,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Coffee': Icons.coffee,
    'Subscriptions': Icons.autorenew,
    'Salary': Icons.account_balance,
    'Freelance': Icons.work,
    'Business': Icons.storefront,
    'Investment': Icons.trending_up,
    'Rental Income': Icons.home,
    'Bonus': Icons.star,
    'Gift': Icons.card_giftcard,
    'Other': Icons.more_horiz,
  };

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
    'Salary': CupertinoIcons.building_2_fill,
    'Freelance': CupertinoIcons.briefcase,
    'Business': CupertinoIcons.bag_fill,
    'Investment': CupertinoIcons.chart_bar_alt_fill,
    'Rental Income': CupertinoIcons.house_fill,
    'Bonus': CupertinoIcons.star_fill,
    'Gift': CupertinoIcons.gift,
    'Other': CupertinoIcons.ellipsis_circle,
  };

  static IconData forCategory(String category) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _cupertinoMap[category] ?? CupertinoIcons.ellipsis_circle;
    }
    return map[category] ?? Icons.more_horiz;
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
cd app
flutter analyze lib/core/constants/category_icons.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/constants/category_icons.dart
git commit -m "feat: make CategoryIcons platform-adaptive (Cupertino on iOS)"
```

---

## Task 7: Flutter — Main shell redesign (5-tab nav + Scan + FAB) + delete SpeedDialFab

**Files:**
- Modify: `app/lib/widgets/main_shell.dart`
- Delete: `app/lib/widgets/speed_dial_fab.dart`
- Modify: `app/lib/core/routing/app_router.dart` (remove SpeedDialFab import)

- [ ] **Step 1: Delete speed_dial_fab.dart**

```bash
git rm app/lib/widgets/speed_dial_fab.dart
```

- [ ] **Step 2: Replace main_shell.dart**

```dart
// app/lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';
import '../core/routing/app_router.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/', label: 'Home', icon: _Icon.home, activeIcon: _Icon.homeActive),
    (path: '/transactions', label: 'Transactions', icon: _Icon.transactions, activeIcon: _Icon.transactionsActive),
    (path: '/assistant', label: 'AI', icon: _Icon.assistant, activeIcon: _Icon.assistantActive),
    (path: '/settings', label: 'Settings', icon: _Icon.settings, activeIcon: _Icon.settingsActive),
  ];

  // Scan is index 2 in the NavigationBar but not a real tab (it pushes to /scan)
  // Home=0, Transactions=1, [Scan=2 placeholder], AI=3→displays as index 2 in _tabs, Settings=4→index 3
  int _selectedIndex(String location) {
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/assistant')) return 2;
    if (location.startsWith('/transactions')) return 1;
    return 0;
  }

  // Maps NavigationBar index (0-4, including scan at 2) to tab index (0-3)
  int _navIndexToTabIndex(int navIndex) {
    if (navIndex < 2) return navIndex;       // 0→0, 1→1
    if (navIndex > 2) return navIndex - 1;   // 3→2 (AI), 4→3 (Settings)
    return -1;                               // 2 = Scan (special)
  }

  // Maps tab index (0-3) to nav index (0-4, skipping 2)
  int _tabIndexToNavIndex(int tabIndex) {
    if (tabIndex < 2) return tabIndex;       // 0→0, 1→1
    return tabIndex + 1;                     // 2→3 (AI), 3→4 (Settings)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentTabIndex = _selectedIndex(location);
    final currentNavIndex = _tabIndexToNavIndex(currentTabIndex);
    final isWide = MediaQuery.sizeOf(context).width > 840;
    final colors = Theme.of(context).colorScheme;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentTabIndex,
              onDestinationSelected: (i) => context.go(_tabs[i].path),
              labelType: NavigationRailLabelType.all,
              leading: FloatingActionButton(
                mini: true,
                onPressed: () => context.push(AppRoutes.addTransaction),
                child: Icon(AppIcons.add),
              ),
              destinations: [
                ..._tabs.map((t) => NavigationRailDestination(
                      icon: Icon(_iconData(t.icon)),
                      selectedIcon: Icon(_iconData(t.activeIcon)),
                      label: Text(t.label),
                    )),
                NavigationRailDestination(
                  icon: Icon(AppIcons.scan),
                  label: const Text('Scan'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        child: Icon(AppIcons.add),
      ),
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: currentNavIndex,
        onDestinationSelected: (navIndex) {
          if (navIndex == 2) {
            context.push('/scan');
            return;
          }
          final tabIndex = _navIndexToTabIndex(navIndex);
          context.go(_tabs[tabIndex].path);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(_iconData(_Icon.home)),
            selectedIcon: Icon(_iconData(_Icon.homeActive)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(_iconData(_Icon.transactions)),
            selectedIcon: Icon(_iconData(_Icon.transactionsActive)),
            label: 'Transactions',
          ),
          // Scan — visually prominent centre item
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.scan, size: 22, color: colors.onPrimaryContainer),
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.scan, size: 22, color: colors.onPrimary),
            ),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(_iconData(_Icon.assistant)),
            selectedIcon: Icon(_iconData(_Icon.assistantActive)),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(_iconData(_Icon.settings)),
            selectedIcon: Icon(_iconData(_Icon.settingsActive)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  static IconData _iconData(_Icon icon) {
    return switch (icon) {
      _Icon.home => AppIcons.home,
      _Icon.homeActive => AppIcons.homeActive,
      _Icon.transactions => AppIcons.transactions,
      _Icon.transactionsActive => AppIcons.transactionsActive,
      _Icon.assistant => AppIcons.assistant,
      _Icon.assistantActive => AppIcons.assistantActive,
      _Icon.settings => AppIcons.settings,
      _Icon.settingsActive => AppIcons.settingsActive,
    };
  }
}

enum _Icon {
  home, homeActive, transactions, transactionsActive,
  assistant, assistantActive, settings, settingsActive,
}
```

- [ ] **Step 3: Remove SpeedDialFab import from any file that still references it**

Search for `speed_dial_fab` imports:

```bash
cd app
grep -r "speed_dial_fab" lib/
```

If any file still imports it, remove the import and any usage. The only file that referenced `SpeedDialFab` was `main_shell.dart`, which we've just replaced.

- [ ] **Step 4: Verify hot restart works**

```bash
cd app
flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/main_shell.dart
git add -u  # stages the deletion of speed_dial_fab.dart
git commit -m "feat: 5-tab nav with Scan centre button and plain Add Expense FAB"
```

---

## Task 8: Flutter — Quick preset chips: emoji → adaptive icons

**Files:**
- Modify: `app/lib/screens/transactions/widgets/quick_preset_chips.dart`

- [ ] **Step 1: Replace the file**

```dart
// app/lib/screens/transactions/widgets/quick_preset_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../providers/category_frequency_provider.dart';

class QuickPresetChips extends ConsumerWidget {
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const QuickPresetChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryFrequencyProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final icon = CategoryIcons.forCategory(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(icon, size: 16),
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => onCategorySelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the existing test to confirm nothing broke**

```bash
cd app
flutter test test/providers/category_frequency_provider_test.dart
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add app/lib/screens/transactions/widgets/quick_preset_chips.dart
git commit -m "fix: replace emoji icon map with adaptive CategoryIcons in QuickPresetChips"
```

---

## Task 9: Flutter — Transaction form redesign

**Files:**
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`

- [ ] **Step 1: Replace `_buildForm` with the redesigned layout**

Open `app/lib/screens/transactions/transaction_form_screen.dart`. Add the import for `AppIcons` at the top:

```dart
import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
```

- [ ] **Step 2: Add `_relativeDateLabel` helper method to the state class**

Add this method to `_TransactionFormScreenState`:

```dart
String _relativeDateLabel(DateTime d) {
  final today = DateTime.now();
  final diff = DateTime(today.year, today.month, today.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
```

- [ ] **Step 3: Add `_openCategorySheet` helper method**

Add to `_TransactionFormScreenState`:

```dart
void _openCategorySheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => CategoryPicker(
        selected: _selectedCategory,
        onSelected: (cat) {
          setState(() => _selectedCategory = cat);
          Navigator.pop(context);
        },
        isExpense: _isExpense,
      ),
    ),
  );
}
```

- [ ] **Step 4: Replace the body of `_buildForm` with the new layout**

Replace everything inside the `SingleChildScrollView`'s `Column` children with:

```dart
children: [
  // Expense / Income toggle
  SegmentedButton<bool>(
    segments: [
      ButtonSegment(
        value: true,
        label: const Text('Expense'),
        icon: Icon(Icons.arrow_downward,
            color: _isExpense
                ? (colors.brightness == Brightness.light
                    ? const Color(0xFFE53935)
                    : const Color(0xFFEF9A9A))
                : null),
      ),
      ButtonSegment(
        value: false,
        label: const Text('Income'),
        icon: Icon(Icons.arrow_upward,
            color: !_isExpense
                ? (colors.brightness == Brightness.light
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF81C784))
                : null),
      ),
    ],
    selected: {_isExpense},
    onSelectionChanged: (v) => setState(() {
      _isExpense = v.first;
      _selectedCategory = null;
    }),
  ),
  const SizedBox(height: 16),

  // Amount
  AmountInputField(
    controller: _amountController,
    isExpense: _isExpense,
    currencyCode: _currencyCode,
    isPremium: isPremium,
    onChanged: (_) => setState(() {}),
    onCurrencyChanged: (code) => setState(() {
      _currencyManuallyChanged = true;
      _currencyCode = code;
    }),
  ),
  const SizedBox(height: 16),

  // Exchange rate (foreign currency only)
  Consumer(builder: (context, ref, _) {
    final userCurrency = ref.watch(userPreferencesProvider).currency;
    if (_currencyCode == userCurrency) return const SizedBox.shrink();
    final rateAsync = ref.watch(exchangeRateProvider((_currencyCode, userCurrency)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: rateAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
        data: (liveRate) => TextField(
          controller: _exchangeRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Exchange rate (optional)',
            hintText: liveRate != null ? liveRate.toStringAsFixed(4) : 'Enter rate manually',
            helperText: liveRate != null
                ? 'Leave blank to use live rate (1 $_currencyCode = ${liveRate.toStringAsFixed(4)} $userCurrency)'
                : 'Live rate unavailable — enter manually or leave blank',
          ),
        ),
      ),
    );
  }),

  // AI purchase suggestions (add-mode only)
  if (!_isEditing) ...[
    PurchaseSuggestionChips(
      onSuggestionSelected: (desc, amount, cat) {
        setState(() {
          _merchantController.text = desc;
          _amountController.text = amount.toStringAsFixed(2);
          _selectedCategory = cat;
        });
      },
    ),
    const SizedBox(height: 12),
  ],

  // Category — quick chips or selected chip
  Text('Category',
      style: textTheme.labelSmall
          ?.copyWith(color: colors.onSurfaceVariant)),
  const SizedBox(height: 6),
  if (_selectedCategory != null) ...[
    Row(children: [
      Chip(
        avatar: Icon(CategoryIcons.forCategory(_selectedCategory!), size: 16),
        label: Text(_selectedCategory!),
        deleteIcon: Icon(AppIcons.close, size: 16),
        onDeleted: () => setState(() => _selectedCategory = null),
        backgroundColor: colors.primaryContainer,
        labelStyle: TextStyle(color: colors.onPrimaryContainer),
      ),
    ]),
    const SizedBox(height: 4),
    TextButton.icon(
      icon: Icon(AppIcons.edit, size: 16),
      label: const Text('Change category'),
      onPressed: _openCategorySheet,
    ),
  ] else ...[
    if (!_isEditing)
      QuickPresetChips(
        selectedCategory: _selectedCategory,
        onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
      ),
    const SizedBox(height: 8),
    TextButton.icon(
      icon: Icon(AppIcons.add, size: 16),
      label: const Text('More categories'),
      onPressed: _openCategorySheet,
    ),
  ],
  const SizedBox(height: 16),

  // Merchant
  TextField(
    controller: _merchantController,
    textCapitalization: TextCapitalization.words,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      labelText: 'Merchant (optional)',
      suffixIcon: VoiceInputButton(onTranscriptReady: _onTranscriptReady),
    ),
  ),
  const SizedBox(height: 12),

  // Date — compact row
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
  ),
  const SizedBox(height: 12),

  // Optional fields — collapsed by default
  ExpansionTile(
    title: Text('More options', style: textTheme.bodyMedium),
    initiallyExpanded: _isEditing && _notesController.text.isNotEmpty,
    children: [
      SwitchListTile(
        title: Text('Include Location', style: textTheme.titleSmall),
        subtitle: Text('Attach GPS coordinates',
            style: textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant)),
        value: _includeLocation,
        onChanged: (v) => setState(() => _includeLocation = v),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _notesController,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(labelText: 'Notes (optional)'),
      ),
      const SizedBox(height: 8),
    ],
  ),
  const SizedBox(height: 24),

  // Save button
  FilledButton(
    onPressed: _isValid && !_submitting ? _submit : null,
    child: _submitting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(_isEditing ? 'Update Transaction' : 'Save Transaction'),
  ),
  const SizedBox(height: 16),
],
```

- [ ] **Step 5: Hot-reload and manually test the form**

Run the app. Open Add Transaction. Verify:
- Quick chips appear when no category is selected
- Tapping a chip shows the selected chip with ×
- Tapping × clears the selection
- "More categories" opens the bottom sheet picker
- Date row shows "Today"
- "More options" is collapsed by default and expands on tap

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/transactions/transaction_form_screen.dart
git commit -m "feat: redesign transaction form — consolidated category, compact date, collapsed optional fields"
```

---

## Task 10: Flutter — Social sign-in buttons

**Files:**
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/lib/screens/onboarding/sign_up_screen.dart`

- [ ] **Step 1: Verify sign_in_screen.dart**

Open `app/lib/screens/onboarding/sign_in_screen.dart`. Check if `AppleButton` and `GoogleButton` are already imported and rendered. The modified file likely already references them.

If imports are missing, add:
```dart
import 'apple_button.dart';
import 'google_button.dart';
```

If `AppleButton` and `GoogleButton` are present but `onPressed` is a real implementation, leave as-is. If `onPressed` is null or missing, ensure both are rendered with `onPressed: null` and a TODO comment:

```dart
GoogleButton(
  isLoading: false,
  onPressed: null, // TODO: implement Google OAuth token exchange
  buttonText: 'Continue with Google',
),
const SizedBox(height: 12),
AppleButton(
  isLoading: false,
  onPressed: null, // TODO: implement Apple Sign-In token exchange
  buttonText: 'Continue with Apple',
),
```

These should appear after an `_OrDivider()` below the main sign-in button.

- [ ] **Step 2: Add `_OrDivider` private widget**

Add to the bottom of `sign_in_screen.dart` (before the closing `}`):

```dart
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}
```

- [ ] **Step 3: Add social buttons to sign_up_screen.dart**

Open `app/lib/screens/onboarding/sign_up_screen.dart`. Add imports:

```dart
import 'apple_button.dart';
import 'google_button.dart';
```

Find the primary register `FilledButton`. After it, add:

```dart
const SizedBox(height: 16),
const _OrDivider(),
const SizedBox(height: 16),
GoogleButton(
  isLoading: _loading,
  onPressed: null, // TODO: implement Google OAuth token exchange
  buttonText: 'Sign up with Google',
),
const SizedBox(height: 12),
AppleButton(
  isLoading: _loading,
  onPressed: null, // TODO: implement Apple Sign-In
  buttonText: 'Sign up with Apple',
),
```

Add the same `_OrDivider` class at the bottom of `sign_up_screen.dart`.

- [ ] **Step 4: Verify**

```bash
cd app
flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/onboarding/sign_in_screen.dart
git add app/lib/screens/onboarding/sign_up_screen.dart
git commit -m "feat: add Google/Apple sign-in buttons to auth screens (UI only)"
```

---

## Task 11: Flutter — Router: new routes + SetupScreen redirect + wizard auth fix

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/onboarding/setup_screen.dart`

- [ ] **Step 1: Add wizard route constants to AppRoutes**

Open `app/lib/core/routing/app_router.dart`. In the `AppRoutes` abstract class, add:

```dart
static const spendingProfile = '/onboarding/profile';
static const suggestedBudgets = '/onboarding/budgets';
static const aboutYou = '/onboarding/about';
static const settingsProfile = '/settings/profile';
```

- [ ] **Step 2: Fix the authenticated-user wizard redirect**

The router's `redirect` function currently has:

```dart
if (isAuthenticated && isOnboarding && state.uri.path != AppRoutes.setup) {
  return AppRoutes.home;
}
```

Replace it with:

```dart
const _wizardRoutes = {
  '/onboarding/setup',
  '/onboarding/profile',
  '/onboarding/budgets',
  '/onboarding/about',
};

if (isAuthenticated && isOnboarding && !_wizardRoutes.contains(state.uri.path)) {
  return AppRoutes.home;
}
```

Note: declare `_wizardRoutes` as a top-level constant outside the `appRouterProvider`, not inside the redirect closure.

- [ ] **Step 3: Add wizard sub-routes under /onboarding**

Inside the `/onboarding` `GoRoute`, after the existing `setup` sub-route, add:

```dart
GoRoute(
  path: 'profile',
  builder: (context, state) => const SpendingProfileScreen(),
),
GoRoute(
  path: 'budgets',
  builder: (context, state) {
    final extra = state.extra as Map<String, String>? ?? {};
    return SuggestedBudgetsScreen(
      personality: extra['personality'] ?? 'balanced',
      incomeRange: extra['incomeRange'] ?? 'mid',
    );
  },
),
GoRoute(
  path: 'about',
  builder: (context, state) => const AboutYouScreen(),
),
```

- [ ] **Step 4: Add /settings/profile route**

In the full-screen routes section (after the `/settings/status` route), add:

```dart
GoRoute(
  path: '/settings/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

- [ ] **Step 5: Add all required imports to app_router.dart**

```dart
import '../../screens/onboarding/spending_profile_screen.dart';
import '../../screens/onboarding/suggested_budgets_screen.dart';
import '../../screens/onboarding/about_you_screen.dart';
import '../../screens/settings/profile_screen.dart';
```

- [ ] **Step 6: Update SetupScreen to redirect to wizard**

Open `app/lib/screens/onboarding/setup_screen.dart`. Find the `onPressed` callback for the "Let's Go!" button. Change:

```dart
GoRouter.of(this.context).go('/');
```

To:

```dart
GoRouter.of(this.context).go(AppRoutes.spendingProfile);
```

Add the `AppRoutes` import if not already present:
```dart
import '../../../core/routing/app_router.dart';
```

- [ ] **Step 7: Verify compile**

```bash
cd app
flutter analyze
```

Expected: no errors (the new screen files don't exist yet; the analyzer will report missing files — that's expected, we create them next).

- [ ] **Step 8: Commit**

```bash
git add app/lib/core/routing/app_router.dart
git add app/lib/screens/onboarding/setup_screen.dart
git commit -m "feat: add wizard + profile routes, fix auth redirect for onboarding screens"
```

---

## Task 12: Flutter — SpendingProfileScreen (wizard step 1)

**Files:**
- Create: `app/lib/screens/onboarding/spending_profile_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// app/lib/screens/onboarding/spending_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';

class SpendingProfileScreen extends ConsumerStatefulWidget {
  const SpendingProfileScreen({super.key});

  @override
  ConsumerState<SpendingProfileScreen> createState() =>
      _SpendingProfileScreenState();
}

class _SpendingProfileScreenState
    extends ConsumerState<SpendingProfileScreen> {
  String _personality = 'balanced';
  String? _incomeRange;

  static const _personalities = [
    (value: 'saver', label: 'Saver', icon: _PersonalityIcon.saver),
    (value: 'balanced', label: 'Balanced', icon: _PersonalityIcon.balanced),
    (value: 'free_spender', label: 'Free spender', icon: _PersonalityIcon.freeSpender),
  ];

  // USD midpoints for bracket labels
  static const _incomeMidpointsUsd = {
    'low': 300.0,
    'mid': 700.0,
    'high': 1400.0,
    'very_high': 2500.0,
  };

  // Threshold pairs for display: [lower, upper] in USD (null = no bound)
  static const _incomeThresholdsUsd = [
    (key: 'low', lower: null, upper: 500.0),
    (key: 'mid', lower: 500.0, upper: 1500.0),
    (key: 'high', lower: 1500.0, upper: 3000.0),
    (key: 'very_high', lower: 3000.0, upper: null),
    (key: 'prefer_not_to_say', lower: null, upper: null),
  ];

  String _incomeLabel(String key, String currencyCode, double fxRate) {
    if (key == 'prefer_not_to_say') return 'Prefer not to say';
    final fmt = NumberFormat.compactCurrency(
      symbol: currencyCode,
      decimalDigits: 0,
    );
    final threshold = _incomeThresholdsUsd.firstWhere((t) => t.key == key);
    if (threshold.lower == null) {
      return 'Under ${fmt.format(threshold.upper! * fxRate)}';
    }
    if (threshold.upper == null) {
      return 'Over ${fmt.format(threshold.lower! * fxRate)}';
    }
    return '${fmt.format(threshold.lower! * fxRate)} – ${fmt.format(threshold.upper! * fxRate)}';
  }

  Future<void> _saveAndNavigate(String destination) async {
    // Best-effort save — fire and forget
    final service = ref.read(userServiceProvider);
    unawaited(service.updateProfile(
      spendingPersonality: _personality,
      incomeRange: _incomeRange,
    ).catchError((_) {}));

    context.go(destination, extra: {
      'personality': _personality,
      'incomeRange': _incomeRange ?? 'prefer_not_to_say',
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = ref.watch(userPreferencesProvider);

    // Use 1.0 as fallback rate (show USD amounts) if no rate available
    // The exchange rate provider isn't needed here — we just display labels.
    // For simplicity, we compute approximate amounts using a fixed PHP reference
    // rate when currency is PHP, otherwise use USD amounts.
    // The bracket KEY (not amount) is what gets saved.
    const double fxRate = 1.0; // Display in USD; format with user's currency symbol as fallback
    final currencyCode = prefs.currency;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Spending Profile'),
        actions: [
          TextButton(
            onPressed: () => _saveAndNavigate(AppRoutes.aboutYou),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Step 1 of 3',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text('How do you spend?', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Helps us suggest realistic budgets',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text('Your spending style',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: _personalities.map((p) {
                  final selected = _personality == p.value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _personality = p.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? colors.primary
                                  : colors.outlineVariant,
                              width: selected ? 2 : 1,
                            ),
                            color: selected
                                ? colors.primaryContainer
                                : colors.surface,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _personalityIcon(p.icon),
                                color: selected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.label,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? colors.onPrimaryContainer
                                      : colors.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Monthly income',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._incomeThresholdsUsd.map((t) {
                final selected = _incomeRange == t.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _incomeRange = t.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? colors.primary
                              : colors.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        color: selected
                            ? colors.primaryContainer
                            : colors.surface,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _incomeLabel(t.key, currencyCode, fxRate),
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.key == 'prefer_not_to_say'
                                    ? colors.onSurfaceVariant
                                    : null,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(AppIcons.check,
                                size: 18, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => _saveAndNavigate(AppRoutes.suggestedBudgets),
                child: const Text('Next →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _personalityIcon(_PersonalityIcon icon) {
    return switch (icon) {
      _PersonalityIcon.saver => AppIcons.saver,
      _PersonalityIcon.balanced => AppIcons.balanced,
      _PersonalityIcon.freeSpender => AppIcons.freeSpender,
    };
  }
}

enum _PersonalityIcon { saver, balanced, freeSpender }
```

Add this import at the top of the file (after the existing imports):

```dart
import 'dart:async' show unawaited;
```

- [ ] **Step 2: Verify compile**

```bash
cd app
flutter analyze lib/screens/onboarding/spending_profile_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/screens/onboarding/spending_profile_screen.dart
git commit -m "feat: add SpendingProfileScreen (wizard step 1)"
```

---

## Task 13: Flutter — SuggestedBudgetsScreen (wizard step 2)

**Files:**
- Create: `app/lib/screens/onboarding/suggested_budgets_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// app/lib/screens/onboarding/suggested_budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/budget_providers.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/budget_service.dart';
import '../../services/user_service.dart';
import '../transactions/widgets/category_picker.dart';

class SuggestedBudgetsScreen extends ConsumerStatefulWidget {
  final String personality;
  final String incomeRange;

  const SuggestedBudgetsScreen({
    super.key,
    required this.personality,
    required this.incomeRange,
  });

  @override
  ConsumerState<SuggestedBudgetsScreen> createState() =>
      _SuggestedBudgetsScreenState();
}

class _SuggestedBudgetsScreenState
    extends ConsumerState<SuggestedBudgetsScreen> {
  static const _personalityFactors = {
    'saver': 0.60,
    'balanced': 0.70,
    'free_spender': 0.85,
  };

  static const _incomeMidpointsUsd = {
    'low': 300.0,
    'mid': 700.0,
    'high': 1400.0,
    'very_high': 2500.0,
    'prefer_not_to_say': 700.0,
  };

  static const _top5 = {
    'saver': ['Groceries', 'Bills', 'Transport', 'Health', 'Dining'],
    'balanced': ['Groceries', 'Bills', 'Dining', 'Transport', 'Shopping'],
    'free_spender': ['Dining', 'Shopping', 'Groceries', 'Entertainment', 'Transport'],
  };

  static const _weights = {
    'saver': {
      'Groceries': 0.28, 'Bills': 0.25, 'Transport': 0.15,
      'Health': 0.15, 'Dining': 0.10,
    },
    'balanced': {
      'Groceries': 0.28, 'Bills': 0.20, 'Dining': 0.18,
      'Transport': 0.14, 'Shopping': 0.10,
    },
    'free_spender': {
      'Dining': 0.22, 'Shopping': 0.15, 'Groceries': 0.15,
      'Entertainment': 0.14, 'Transport': 0.12,
    },
  };

  late List<({String category, double amount})> _budgets;
  bool _saving = false;

  List<({String category, double amount})> _computeBudgets(double fxRate) {
    final factor = _personalityFactors[widget.personality] ?? 0.70;
    final midpoint = _incomeMidpointsUsd[widget.incomeRange] ?? 700.0;
    final spendingBudget = midpoint * fxRate * factor;
    final categories = _top5[widget.personality] ?? _top5['balanced']!;
    final weights = _weights[widget.personality] ?? _weights['balanced']!;
    return categories
        .map((cat) => (
              category: cat,
              amount: double.parse(
                  (spendingBudget * (weights[cat] ?? 0.1)).toStringAsFixed(2)),
            ))
        .toList();
  }

  Future<void> _createBudgets() async {
    setState(() => _saving = true);
    final service = ref.read(budgetServiceProvider);
    final currencyCode = ref.read(userPreferencesProvider).currency;
    try {
      for (final b in _budgets.where((b) => b.amount > 0)) {
        await service.create(CreateBudgetDto(
          category: b.category,
          monthlyLimit: b.amount,
          currencyCode: currencyCode,
        ));
      }
      if (!mounted) return;
      context.go(AppRoutes.aboutYou);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create budgets: $e')),
      );
    }
  }

  void _editAmount(int index) {
    final ctrl =
        TextEditingController(text: _budgets[index].amount.toStringAsFixed(2));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(_).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_budgets[index].category,
                style: Theme.of(_).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(ctrl.text) ?? _budgets[index].amount;
                setState(() {
                  _budgets[index] = (
                    category: _budgets[index].category,
                    amount: val,
                  );
                });
                Navigator.pop(_);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCategory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => CategoryPicker(
          selected: null,
          isExpense: true,
          onSelected: (cat) {
            Navigator.pop(_);
            if (!_budgets.any((b) => b.category == cat)) {
              setState(() => _budgets.add((category: cat, amount: 0)));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userCurrency = ref.watch(userPreferencesProvider).currency;
    final rateAsync =
        ref.watch(exchangeRateProvider(('USD', userCurrency)));

    return rateAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Suggested Budgets')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Exchange rates unavailable'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.aboutYou),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
      data: (rate) {
        final fxRate = rate ?? 1.0;
        // Initialise budgets once
        if (!_budgetsInitialised) {
          _budgets = _computeBudgets(fxRate);
          _budgetsInitialised = true;
        }

        final personalityLabel = switch (widget.personality) {
          'saver' => 'Saver',
          'free_spender' => 'Free spender',
          _ => 'Balanced',
        };
        final incomeLabel = switch (widget.incomeRange) {
          'low' => 'Lower income',
          'high' => 'Higher income',
          'very_high' => 'Very high income',
          'prefer_not_to_say' => '',
          _ => 'Mid income',
        };

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Suggested Budgets'),
            actions: [
              TextButton(
                onPressed: () => context.go(AppRoutes.aboutYou),
                child: const Text('Skip'),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Step 2 of 3',
                          style: textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('Your suggested budgets',
                          style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        [personalityLabel, if (incomeLabel.isNotEmpty) incomeLabel]
                            .join(' · '),
                        style: textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text('Tap an amount to edit',
                          style: textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _budgets.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      if (i == _budgets.length) {
                        return TextButton.icon(
                          icon: Icon(AppIcons.add, size: 16),
                          label: const Text('Add more categories'),
                          onPressed: _addCategory,
                        );
                      }
                      final b = _budgets[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(CategoryIcons.forCategory(b.category)),
                        title: Text(b.category),
                        trailing: GestureDetector(
                          onTap: () => _editAmount(i),
                          child: Text(
                            '$userCurrency ${b.amount.toStringAsFixed(0)}',
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _saving ? null : _createBudgets,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create budgets →'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _budgetsInitialised = false;
}
```

- [ ] **Step 2: Verify compile**

```bash
cd app
flutter analyze lib/screens/onboarding/suggested_budgets_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/screens/onboarding/suggested_budgets_screen.dart
git commit -m "feat: add SuggestedBudgetsScreen (wizard step 2)"
```

---

## Task 14: Flutter — AboutYouScreen (wizard step 3)

**Files:**
- Create: `app/lib/screens/onboarding/about_you_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// app/lib/screens/onboarding/about_you_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';

class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});

  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  String? _occupation;
  String? _household;
  bool _saving = false;

  static const _occupations = [
    (value: 'employed', label: 'Employed', icon: _OccupationIcon.employed),
    (value: 'self_employed', label: 'Self-employed', icon: _OccupationIcon.selfEmployed),
    (value: 'student', label: 'Student', icon: _OccupationIcon.student),
    (value: 'retired', label: 'Retired', icon: _OccupationIcon.retired),
    (value: 'other', label: 'Other', icon: _OccupationIcon.other),
  ];

  static const _households = [
    (value: 'solo', label: 'Just me', icon: _HouseholdIcon.solo),
    (value: 'couple', label: 'Couple', icon: _HouseholdIcon.couple),
    (value: 'family', label: 'Family', icon: _HouseholdIcon.family),
    (value: 'shared', label: 'Shared', icon: _HouseholdIcon.shared),
  ];

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(userServiceProvider);
      await service.updateProfile(
        occupationType: _occupation,
        householdSize: _household,
      );
    } catch (_) {
      // Best-effort — don't block navigation
    }
    if (!mounted) return;
    await markOnboardingComplete();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _skip() async {
    await markOnboardingComplete();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('About You'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Step 3 of 3',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text('A bit more about you', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('All optional. Helps us personalise your experience.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 28),
              Text('Occupation',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _occupations.map((o) {
                  final selected = _occupation == o.value;
                  return ChoiceChip(
                    avatar: Icon(_occupationIcon(o.icon), size: 16),
                    label: Text(o.label),
                    selected: selected,
                    onSelected: (_) => setState(
                        () => _occupation = selected ? null : o.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Household',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _households.map((h) {
                  final selected = _household == h.value;
                  return ChoiceChip(
                    avatar: Icon(_householdIcon(h.icon), size: 16),
                    label: Text(h.label),
                    selected: selected,
                    onSelected: (_) => setState(
                        () => _household = selected ? null : h.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _saving ? null : _finish,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Go to dashboard 🎉'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _occupationIcon(_OccupationIcon icon) {
    return switch (icon) {
      _OccupationIcon.employed => AppIcons.employed,
      _OccupationIcon.selfEmployed => AppIcons.selfEmployed,
      _OccupationIcon.student => AppIcons.student,
      _OccupationIcon.retired => AppIcons.retired,
      _OccupationIcon.other => AppIcons.other,
    };
  }

  static IconData _householdIcon(_HouseholdIcon icon) {
    return switch (icon) {
      _HouseholdIcon.solo => AppIcons.person,
      _HouseholdIcon.couple => AppIcons.couple,
      _HouseholdIcon.family => AppIcons.family,
      _HouseholdIcon.shared => AppIcons.sharedHome,
    };
  }
}

enum _OccupationIcon { employed, selfEmployed, student, retired, other }
enum _HouseholdIcon { solo, couple, family, shared }
```

- [ ] **Step 2: Verify compile**

```bash
cd app
flutter analyze lib/screens/onboarding/about_you_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/screens/onboarding/about_you_screen.dart
git commit -m "feat: add AboutYouScreen (wizard step 3)"
```

---

## Task 15: Flutter — Settings Profile screen + settings entry

**Files:**
- Create: `app/lib/screens/settings/profile_screen.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Create ProfileScreen**

```dart
// app/lib/screens/settings/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _personality = 'balanced';
  String? _incomeRange;
  String? _occupation;
  String? _household;
  bool _loaded = false;
  bool _saving = false;

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _personality = profile.spendingPersonality ?? 'balanced';
    _incomeRange = profile.incomeRange;
    _occupation = profile.occupationType;
    _household = profile.householdSize;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(userServiceProvider);
      await service.updateProfile(
        spendingPersonality: _personality,
        incomeRange: _incomeRange,
        occupationType: _occupation,
        householdSize: _household,
      );
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          _loadFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Read-only account info
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(profile.email.isNotEmpty
                        ? profile.email[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(profile.email,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant)),
                  subtitle: Text(
                    'Member since ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                const Divider(height: 32),

                // Spending style
                _sectionHeader(textTheme, 'Spending Style'),
                const SizedBox(height: 12),
                Row(children: [
                  _personalityCard(colors, textTheme, 'saver', 'Saver', AppIcons.saver),
                  const SizedBox(width: 8),
                  _personalityCard(colors, textTheme, 'balanced', 'Balanced', AppIcons.balanced),
                  const SizedBox(width: 8),
                  _personalityCard(colors, textTheme, 'free_spender', 'Free\nspender', AppIcons.freeSpender),
                ]),
                const SizedBox(height: 24),

                // Income range
                _sectionHeader(textTheme, 'Monthly Income'),
                const SizedBox(height: 12),
                ..._incomeOptions.map((o) => _incomeRow(colors, textTheme, o.$1, o.$2)),
                const SizedBox(height: 24),

                // Occupation
                _sectionHeader(textTheme, 'Occupation'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(colors, 'employed', 'Employed', AppIcons.employed),
                  _chip(colors, 'self_employed', 'Self-employed', AppIcons.selfEmployed),
                  _chip(colors, 'student', 'Student', AppIcons.student),
                  _chip(colors, 'retired', 'Retired', AppIcons.retired),
                  _chip(colors, 'other', 'Other', AppIcons.other),
                ]),
                const SizedBox(height: 24),

                // Household
                _sectionHeader(textTheme, 'Household'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _householdChip(colors, 'solo', 'Just me', AppIcons.person),
                  _householdChip(colors, 'couple', 'Couple', AppIcons.couple),
                  _householdChip(colors, 'family', 'Family', AppIcons.family),
                  _householdChip(colors, 'shared', 'Shared', AppIcons.sharedHome),
                ]),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _incomeOptions = [
    ('low', 'Lower income'),
    ('mid', 'Mid income'),
    ('high', 'Higher income'),
    ('very_high', 'Very high income'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  Widget _sectionHeader(TextTheme textTheme, String title) {
    return Text(title,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
  }

  Widget _personalityCard(ColorScheme colors, TextTheme textTheme,
      String value, String label, IconData icon) {
    final selected = _personality == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _personality = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colors.primaryContainer : colors.surface,
          ),
          child: Column(children: [
            Icon(icon,
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _incomeRow(
      ColorScheme colors, TextTheme textTheme, String value, String label) {
    final selected = _incomeRange == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _incomeRange = value),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color:
                selected ? colors.primaryContainer : colors.surface,
          ),
          child: Row(children: [
            Expanded(child: Text(label, style: textTheme.bodyMedium)),
            if (selected)
              Icon(AppIcons.check, size: 18, color: colors.primary),
          ]),
        ),
      ),
    );
  }

  Widget _chip(ColorScheme colors, String value, String label, IconData icon) {
    final selected = _occupation == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          setState(() => _occupation = selected ? null : value),
    );
  }

  Widget _householdChip(
      ColorScheme colors, String value, String label, IconData icon) {
    final selected = _household == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          setState(() => _household = selected ? null : value),
    );
  }
}
```

- [ ] **Step 2: Add My Profile entry to SettingsScreen**

Open `app/lib/screens/settings/settings_screen.dart`. In the Profile section (just after the `userAsync.when(...)` `ListTile` block and before the `const Divider()`), add:

```dart
ListTile(
  leading: Icon(Icons.manage_accounts_outlined),
  title: const Text('My Profile'),
  subtitle: const Text('Spending style, income, household'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/settings/profile'),
),
```

Add import for `app_icons.dart` if using `AppIcons` icons (or keep using `Icons.*` to minimise scope).

- [ ] **Step 3: Verify**

```bash
cd app
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/settings/profile_screen.dart
git add app/lib/screens/settings/settings_screen.dart
git commit -m "feat: add Settings > My Profile screen with editable spending profile"
```

---

## Self-Review

### Spec coverage check

| Spec section | Task(s) |
|---|---|
| Platform-adaptive AppIcons | Task 5 |
| CategoryIcons adaptive | Task 6 |
| Main shell 5-tab + Scan centre + Add Expense FAB | Task 7 |
| Delete SpeedDialFab | Task 7 |
| Quick Add chips emoji → adaptive | Task 8 |
| Transaction form redesign | Task 9 |
| Social sign-in buttons | Task 10 |
| Router wizard routes + auth fix | Task 11 |
| SetupScreen redirect | Task 11 |
| User entity 4 new fields + migration | Task 1 |
| Backend DTO + service + endpoint | Task 2 |
| Dead code deletion | Task 3 |
| UserProfile model + UserService update | Task 4 |
| SpendingProfileScreen | Task 12 |
| SuggestedBudgetsScreen | Task 13 |
| AboutYouScreen | Task 14 |
| Settings ProfileScreen | Task 15 |
| Settings entry tile | Task 15 |
| Profile data returned in GET /me | Task 2 |

All spec sections covered. ✓

### Type consistency check

- `UserProfile.spendingPersonality` defined in Task 4, consumed in Tasks 12, 14, 15 ✓
- `AppIcons.calendar` defined in Task 5, used in Task 9 ✓
- `AppIcons.add` defined in Task 5, used in Tasks 7, 9, 13 ✓
- `SuggestedBudgetsScreen(personality:, incomeRange:)` defined in Task 13, constructed in Task 11 ✓
- `CreateBudgetDto(category:, monthlyLimit:, currencyCode:)` — matches `budget_service.dart` definition ✓
- `markOnboardingComplete()` — imported from `app_router.dart` in Task 14 ✓
- `_budgetsInitialised` flag — declared at class level in Task 13 ✓
- `AppRoutes.suggestedBudgets`, `AppRoutes.aboutYou`, `AppRoutes.spendingProfile` — defined in Task 11, used in Tasks 12, 13, 14 ✓
