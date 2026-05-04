# Insights Conditional Rendering, Skeleton Loading & Auth Button Branding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the "Your Insights" section when there is no meaningful data, replace every page/section `CircularProgressIndicator` with purpose-shaped shimmer skeletons, and fix Google/Apple sign-in button branding.

**Architecture:** New skeleton widgets extend the existing `SkeletonLoader` base in `skeleton_loader.dart`. The insights provider becomes nullable (`BehavioralInsights?`) and swallows API errors, letting the dashboard conditionally render the entire section. Auth button changes are self-contained in `sign_in_screen.dart` plus a new SVG asset.

**Tech Stack:** Flutter, Riverpod (`FutureProvider`), `shimmer ^3.0.0`, `flutter_svg ^2.0.10`, `dio`, Material 3

---

## File Map

**Modified:**
- `app/lib/widgets/skeleton_loader.dart` — add `InsightSkeletonCard`, `InsightSkeletonSection`, `BudgetSummarySkeletonCard`, `BudgetListSkeletonCard`
- `app/lib/providers/behavioral_insights_provider.dart` — nullable return type, swallow errors
- `app/lib/screens/dashboard/dashboard_screen.dart` — conditional insights section, skeleton loading for all three sections
- `app/lib/screens/transactions/transaction_list_screen.dart` — replace initial load spinner
- `app/lib/screens/budgets/budgets_screen.dart` — replace initial load spinner
- `app/lib/screens/transactions/transaction_detail_screen.dart` — replace page load spinner
- `app/lib/screens/transactions/transaction_form_screen.dart` — replace edit-loading spinner
- `app/lib/screens/settings/settings_screen.dart` — replace subscription card spinner
- `app/lib/screens/onboarding/sign_in_screen.dart` — Google/Apple button branding

**Created:**
- `app/assets/images/google_logo.svg` — official four-color Google "G" mark

**Modified (non-Flutter):**
- `README.md` (root) — add Social Authentication Setup section

---

## Task 1: Add Insight and Budget Skeleton Widgets

**Files:**
- Modify: `app/lib/widgets/skeleton_loader.dart`

- [ ] **Step 1: Add `InsightSkeletonCard` and `InsightSkeletonSection`**

Append to the bottom of `app/lib/widgets/skeleton_loader.dart`:

```dart
class InsightSkeletonCard extends StatelessWidget {
  const InsightSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonLoader(height: 12, width: 140),
            SizedBox(height: 12),
            SkeletonLoader(height: 24, width: 180),
            SizedBox(height: 12),
            SkeletonLoader(height: 12),
            SizedBox(height: 6),
            SkeletonLoader(height: 12, width: 200),
          ],
        ),
      ),
    );
  }
}

class InsightSkeletonSection extends StatelessWidget {
  const InsightSkeletonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        InsightSkeletonCard(),
        SizedBox(height: 12),
        InsightSkeletonCard(),
        SizedBox(height: 12),
        InsightSkeletonCard(),
        SizedBox(height: 12),
      ],
    );
  }
}
```

- [ ] **Step 2: Add `BudgetSummarySkeletonCard` (for dashboard horizontal carousel)**

Append to the bottom of `app/lib/widgets/skeleton_loader.dart`:

```dart
class BudgetSummarySkeletonCard extends StatelessWidget {
  const BudgetSummarySkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                  SizedBox(width: 10),
                  SkeletonLoader(height: 14, width: 80),
                ],
              ),
              SizedBox(height: 16),
              SkeletonLoader(height: 8, borderRadius: 4),
              SizedBox(height: 10),
              SkeletonLoader(height: 12, width: 120),
              SizedBox(height: 6),
              SkeletonLoader(height: 12, width: 90),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add `BudgetListSkeletonCard` (for budgets screen full-width list)**

Append to the bottom of `app/lib/widgets/skeleton_loader.dart`:

```dart
class BudgetListSkeletonCard extends StatelessWidget {
  const BudgetListSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                SizedBox(width: 12),
                Expanded(child: SkeletonLoader(height: 16)),
                SizedBox(width: 12),
                SkeletonLoader(width: 24, height: 24, borderRadius: 4),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonLoader(height: 14)),
                SizedBox(width: 16),
                SkeletonLoader(width: 36, height: 14),
              ],
            ),
            SizedBox(height: 8),
            SkeletonLoader(height: 8, borderRadius: 4),
            SizedBox(height: 8),
            Row(
              children: [
                SkeletonLoader(width: 40, height: 12),
                Spacer(),
                SkeletonLoader(width: 100, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify no analysis errors**

```
cd app && flutter analyze lib/widgets/skeleton_loader.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/skeleton_loader.dart
git commit -m "feat: add InsightSkeletonCard, InsightSkeletonSection, BudgetSummarySkeletonCard, BudgetListSkeletonCard"
```

---

## Task 2: Make Behavioral Insights Provider Return Nullable

**Files:**
- Modify: `app/lib/providers/behavioral_insights_provider.dart`

- [ ] **Step 1: Replace the file contents**

Replace the entire contents of `app/lib/providers/behavioral_insights_provider.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../models/behavioral_insights.dart';
import '../core/constants/api_constants.dart';

final behavioralInsightsServiceProvider =
    Provider<BehavioralInsightsService>((ref) {
  return BehavioralInsightsService(ref.watch(dioProvider));
});

class BehavioralInsightsService {
  final Dio _dio;

  BehavioralInsightsService(this._dio);

  Future<BehavioralInsights?> getBehavioralInsights() async {
    try {
      final response = await _dio.get(ApiConstants.behavioralInsights);
      if (response.statusCode == 204) return null;
      return BehavioralInsights.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

final behavioralInsightsProvider =
    FutureProvider<BehavioralInsights?>((ref) async {
  final service = ref.watch(behavioralInsightsServiceProvider);
  return service.getBehavioralInsights();
});
```

- [ ] **Step 2: Verify no analysis errors**

```
cd app && flutter analyze lib/providers/behavioral_insights_provider.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/providers/behavioral_insights_provider.dart
git commit -m "feat: make behavioralInsightsProvider return null on error or no data"
```

---

## Task 3: Update Dashboard Screen — Insights Section

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`

The dashboard imports and `insightsState.when(...)` block need updating. The "Your Insights" section header must move inside each branch.

- [ ] **Step 1: Add skeleton import**

In `app/lib/screens/dashboard/dashboard_screen.dart`, add this import alongside the existing widget imports:

```dart
import 'package:conscia_app/widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace the insights `when` block**

Locate this block (roughly lines 123–169):

```dart
        // Behavioral Insights Section
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Your Insights'),
        ),
        insightsState.when(
          data: (insights) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FinancialMoodCard(
                  mood: insights.mood,
                  worthItPercentage: insights.worthItPercentage,
                  previousMonthPercentage:
                      insights.previousMonthWorthItCount > 0
                          ? (insights.previousMonthWorthItCount /
                              (insights.previousMonthWorthItCount + 10) *
                              100)
                          : 50,
                ),
                const SizedBox(height: 12),
                WorthItCounterCard(
                  thisMonthCount: insights.worthItCount,
                  previousMonthCount: insights.previousMonthWorthItCount,
                ),
                const SizedBox(height: 12),
                if (insights.impulseeTrends.isNotEmpty)
                  ImpulseTrendsCard(trends: insights.impulseeTrends),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Unable to load insights',
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ),
```

Replace the entire block with:

```dart
        // Behavioral Insights Section — only rendered when data is available
        ...insightsState.when(
          loading: () => [
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Your Insights'),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: InsightSkeletonSection(),
              ),
            ),
          ],
          data: (insights) {
            if (insights == null) return [];
            return [
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'Your Insights'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FinancialMoodCard(
                      mood: insights.mood,
                      worthItPercentage: insights.worthItPercentage,
                      previousMonthPercentage:
                          insights.previousMonthWorthItCount > 0
                              ? (insights.previousMonthWorthItCount /
                                  (insights.previousMonthWorthItCount + 10) *
                                  100)
                              : 50,
                    ),
                    const SizedBox(height: 12),
                    WorthItCounterCard(
                      thisMonthCount: insights.worthItCount,
                      previousMonthCount: insights.previousMonthWorthItCount,
                    ),
                    const SizedBox(height: 12),
                    if (insights.impulseeTrends.isNotEmpty)
                      ImpulseTrendsCard(trends: insights.impulseeTrends),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            ];
          },
          error: (_, __) => [],
        ),
```

Note: The spread operator (`...`) on `insightsState.when(...)` means each branch returns a `List<Widget>` which gets spread into the `slivers` list. This requires the outer `CustomScrollView` to accept `slivers: [...]` spread syntax — which it already does since `slivers` is a `List<Widget>`.

- [ ] **Step 3: Verify the file compiles**

```
cd app && flutter analyze lib/screens/dashboard/dashboard_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: hide insights section when no data, show skeleton while loading"
```

---

## Task 4: Update Dashboard Screen — Budgets and Transactions Skeleton Loading

**Files:**
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`

- [ ] **Step 1: Replace budgets loading spinner**

Locate (roughly lines 173–180):

```dart
        if (budgetState.isLoading && budgets.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
```

Replace with:

```dart
        if (budgetState.isLoading && budgets.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => const BudgetSummarySkeletonCard(),
              ),
            ),
          )
```

- [ ] **Step 2: Replace recent transactions loading spinner**

Locate (roughly lines 244–250):

```dart
        if (txState.isLoading && transactions.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
```

Replace with:

```dart
        if (txState.isLoading && transactions.isEmpty)
          SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const SkeletonListTile(),
          )
```

- [ ] **Step 3: Verify**

```
cd app && flutter analyze lib/screens/dashboard/dashboard_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: replace dashboard budget and transaction loading spinners with skeletons"
```

---

## Task 5: Update Transaction List Screen

**Files:**
- Modify: `app/lib/screens/transactions/transaction_list_screen.dart`

- [ ] **Step 1: Add skeleton import**

Add to the imports at the top of `transaction_list_screen.dart`:

```dart
import '../../widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace the initial-load spinner**

Locate (line 68–70):

```dart
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
```

Replace with:

```dart
    if (state.isLoading && state.transactions.isEmpty) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const SkeletonListTile(),
      );
    }
```

- [ ] **Step 3: Keep the pagination spinner at bottom (lines ~112–121)**

The "load more" spinner at the bottom of the scroll is intentionally kept as a small `CircularProgressIndicator(strokeWidth: 2)` — it is an action indicator, not a page load indicator. No change needed here.

- [ ] **Step 4: Verify**

```
cd app && flutter analyze lib/screens/transactions/transaction_list_screen.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/transactions/transaction_list_screen.dart
git commit -m "feat: replace transaction list initial load spinner with skeleton tiles"
```

---

## Task 6: Update Budgets Screen

**Files:**
- Modify: `app/lib/screens/budgets/budgets_screen.dart`

- [ ] **Step 1: Add skeleton import**

Add to imports:

```dart
import '../../widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace the initial-load spinner**

Locate (lines 38–40):

```dart
    if (state.isLoading && state.budgets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
```

Replace with:

```dart
    if (state.isLoading && state.budgets.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 3,
        itemBuilder: (_, __) => const BudgetListSkeletonCard(),
      );
    }
```

- [ ] **Step 3: Verify**

```
cd app && flutter analyze lib/screens/budgets/budgets_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/budgets/budgets_screen.dart
git commit -m "feat: replace budgets screen initial load spinner with skeleton cards"
```

---

## Task 7: Update Transaction Detail and Form Screens

**Files:**
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`

- [ ] **Step 1: Add skeleton import to detail screen**

Add to imports in `transaction_detail_screen.dart`:

```dart
import '../../widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace page-load spinner in detail screen**

Locate (line 163):

```dart
        loading: () => const Center(child: CircularProgressIndicator()),
```

Replace with:

```dart
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: const [
            SkeletonLoader(height: 40, width: 200),
            SizedBox(height: 24),
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
          ],
        ),
```

Note: The other `CircularProgressIndicator` instances in `transaction_detail_screen.dart` (lines 266, 280, 480) are **action button loading states** — leave them unchanged.

- [ ] **Step 3: Add skeleton import to form screen**

Add to imports in `transaction_form_screen.dart`:

```dart
import '../../widgets/skeleton_loader.dart';
```

- [ ] **Step 4: Replace edit-loading spinner in form screen**

Locate (lines 147–152):

```dart
    if (_isEditing && !_prefilled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
```

Replace with:

```dart
    if (_isEditing && !_prefilled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
            SizedBox(height: 16),
            SkeletonLoader(height: 48),
          ],
        ),
      );
    }
```

- [ ] **Step 5: Verify both files**

```
cd app && flutter analyze lib/screens/transactions/transaction_detail_screen.dart lib/screens/transactions/transaction_form_screen.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/transactions/transaction_detail_screen.dart app/lib/screens/transactions/transaction_form_screen.dart
git commit -m "feat: replace transaction detail and form page-load spinners with skeletons"
```

---

## Task 8: Update Settings Screen

**Files:**
- Modify: `app/lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Add skeleton import**

Add to imports in `settings_screen.dart`:

```dart
import '../../widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace subscription card spinner**

Locate (line 178):

```dart
              loading: () => const Center(child: CircularProgressIndicator()),
```

Replace with:

```dart
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SkeletonCard(),
              ),
```

- [ ] **Step 3: Verify**

```
cd app && flutter analyze lib/screens/settings/settings_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/settings/settings_screen.dart
git commit -m "feat: replace settings subscription loading spinner with skeleton"
```

---

## Task 9: Add Google Logo SVG Asset

**Files:**
- Create: `app/assets/images/google_logo.svg`

- [ ] **Step 1: Create the SVG file**

Create `app/assets/images/google_logo.svg` with this content (the official Google "G" mark):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#4285F4" d="M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z"/>
  <path fill="#34A853" d="M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z"/>
  <path fill="#FBBC05" d="M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24c0 3.55.85 6.91 2.34 9.88l7.35-5.7z"/>
  <path fill="#EA4335" d="M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z"/>
</svg>
```

- [ ] **Step 2: Verify asset is declared in pubspec**

Open `app/pubspec.yaml`. The assets section should already contain:

```yaml
  assets:
    - assets/
    - assets/images/
```

If `assets/images/` is not listed, add it. (Current file already has it — no change needed.)

- [ ] **Step 3: Commit**

```bash
git add app/assets/images/google_logo.svg
git commit -m "feat: add official Google G mark SVG asset"
```

---

## Task 10: Fix Google/Apple Sign-In Button Branding

**Files:**
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`

- [ ] **Step 1: Add flutter_svg import**

Add to imports at top of `sign_in_screen.dart`:

```dart
import 'package:flutter_svg/flutter_svg.dart';
```

- [ ] **Step 2: Add `_GoogleSignInButton` private widget**

Add this widget class at the bottom of `sign_in_screen.dart` (after the `SignInScreen` class, before any closing braces):

```dart
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/google_logo.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 12),
            const Text('Sign in with Google'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Replace the Google button in `build`**

Locate the current Google `OutlinedButton.icon` (roughly lines 302–331):

```dart
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Text('G',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  label: const Text('Sign in with Google'),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          try {
                            await ref.read(authProvider.notifier).signInWithGoogle();
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _errorMessage = e.toString());
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                ),
              ),
```

Replace with:

```dart
              _GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  try {
                    await ref.read(authProvider.notifier).signInWithGoogle();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _errorMessage = e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
```

- [ ] **Step 4: Fix Apple button to use solid black fill**

Locate the Apple `OutlinedButton.icon` (roughly lines 269–301):

```dart
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Sign in with Apple'),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            try {
                              await ref.read(authProvider.notifier).signInWithApple();
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _errorMessage = e.toString());
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                  ),
                ),
```

Replace with:

```dart
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Sign in with Apple'),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            try {
                              await ref.read(authProvider.notifier).signInWithApple();
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _errorMessage = e.toString());
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                  ),
                ),
```

- [ ] **Step 5: Verify**

```
cd app && flutter analyze lib/screens/onboarding/sign_in_screen.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/onboarding/sign_in_screen.dart
git commit -m "feat: replace Google text-G button with branded SVG button, fix Apple button fill"
```

---

## Task 11: Update Root README with Social Auth Setup

**Files:**
- Modify: `README.md` (repo root)

- [ ] **Step 1: Append Social Authentication Setup section**

Open `README.md` (repo root) and append the following at the end of the file:

```markdown
## Social Authentication Setup

The app supports Sign in with Google and Sign in with Apple. The UI and service code are in place; the steps below wire up the credentials and backend endpoints needed to make them work.

### Sign in with Google

**Frontend (Flutter)**

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials.
2. Create an **OAuth 2.0 Client ID** for each platform:
   - Android: package name `com.conscia.app`, SHA-1 fingerprint from your keystore
   - iOS: bundle ID `com.conscia.app`
   - Web: needed for the `serverClientId` used to get an `idToken`
3. Download `google-services.json` (Android) → place at `app/android/app/google-services.json`
4. Download `GoogleService-Info.plist` (iOS) → place at `app/ios/Runner/GoogleService-Info.plist`
5. In `app/android/app/build.gradle`, confirm `apply plugin: 'com.google.gms.google-services'` is present.
6. Pass the web client ID to `GoogleSignIn` in `app/lib/services/auth_service.dart`:
   ```dart
   final googleUser = await GoogleSignIn(
     serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
   ).signIn();
   ```

**Backend**

Implement `POST /api/v1/auth/google`:
- Request body: `{ "idToken": "<Google ID token>" }`
- Verify the token with Google's tokeninfo endpoint or the `google-auth-library`
- Look up or create the user, issue JWT access/refresh tokens
- Response: `{ "accessToken": "...", "refreshToken": "...", "userId": "..." }`

---

### Sign in with Apple

> Apple sign-in is iOS-only. The button is conditionally rendered and will not appear on Android.

**Frontend (Flutter)**

1. In the [Apple Developer Portal](https://developer.apple.com/), navigate to your App ID → Capabilities and enable **Sign in with Apple**.
2. In Xcode: open `app/ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → `+ Capability` → **Sign in with Apple**.
3. No additional Flutter package config is needed (`sign_in_with_apple` handles entitlements automatically once the capability is enabled).

**Backend**

Implement `POST /api/v1/auth/apple`:
- Request body: `{ "identityToken": "<Apple identity token>", "authorizationCode": "<code>" }`
- Verify the identity token using Apple's public keys (`https://appleid.apple.com/auth/keys`)
- Look up or create the user, issue JWT access/refresh tokens
- Response: `{ "accessToken": "...", "refreshToken": "...", "userId": "..." }`

Note: Apple only returns the user's name and email on the **first** sign-in. Store them immediately on first token exchange.

---

### Disabling Mock Auth

During development `MOCK_AUTH=true` is the default (set in `ApiConstants`). To test real OAuth:

```bash
# Flutter run with mock auth disabled
cd app && flutter run --dart-define=MOCK_AUTH=false --dart-define=API_BASE_URL=https://your-api-host/api/v1/
```
```

- [ ] **Step 2: Verify README renders correctly**

Open `README.md` in a Markdown viewer and confirm headings and code blocks look correct.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add Social Authentication Setup section to README"
```

---

## Final Verification

- [ ] Run `flutter analyze` across the full app — zero errors expected:

```
cd app && flutter analyze lib/
```

- [ ] Run `flutter build apk --debug` (or `flutter build ios --debug` on macOS) to confirm no runtime compilation issues:

```
cd app && flutter build apk --debug
```

- [ ] **Manually verify on device/simulator:**
  - Dashboard with no backend running: "Your Insights" section is invisible
  - Dashboard loading: shimmer skeletons appear for insights, budgets, and transactions
  - Transaction list initial load: shimmer list tiles appear
  - Budgets screen initial load: shimmer budget cards appear
  - Transaction detail load: shimmer cards appear
  - Edit transaction loading: shimmer form fields appear
  - Settings screen subscription loading: shimmer card appears
  - Sign-in screen: Google button shows four-color "G" logo on white background
  - Sign-in screen on iOS: Apple button is solid black with white text

- [ ] **Final commit** (if any cleanup needed):

```bash
git add -A
git commit -m "chore: final cleanup for insights conditional, skeleton loading, and auth branding"
```
