# Phase 4 AI Personality + Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global AI personality intensity preference, sharpen persona behavior across all AI flows, refresh assistant/reflection visuals and shared amount input, and establish a reusable Conscia icon/motif system that also informs the marketing page.

**Architecture:** Persist a new user-level AI intensity preference through the existing profile API, thread that preference into the AI orchestration layer, and centralize persona prompt/temperature strategy in `Conscia.AI`. On the Flutter side, introduce a small branded motif/icon system, reuse it across assistant and reflection loading states, restyle the shared amount input, and align `app/web/` with the same visual language.

**Tech Stack:** .NET 8, Flutter, Riverpod, GoRouter, SVG/image assets, existing user profile API, existing AI service abstraction.

---

## File Structure

- `src/Conscia.Domain/Entities/User.cs`
  Stores the new global AI intensity preference.
- `src/Conscia.Application/DTOs/UserProfileUpdateDto.cs`
  Accepts intensity updates from the app.
- `src/Conscia.Application/Services/UserService.cs`
  Persists the new preference.
- `src/Conscia.Application/Validators/UserProfileUpdateValidator.cs`
  Accepts profile updates containing only AI intensity.
- `src/Conscia.Api/Endpoints/UserEndpoints.cs`
  Returns the preference in profile responses.
- `src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs`
  Configures default persistence behavior.
- `src/Conscia.Infrastructure/Migrations/*AddAiPersonalityIntensityToUsers*.cs`
  Adds the column.
- `src/Conscia.Application/Models/AIContext.cs`
  Carries the effective intensity into the AI layer.
- `src/Conscia.Application/Interfaces/IAIService.cs`
  Uses the enriched context without changing the public AI entry points.
- `src/Conscia.AI/Prompts/PromptTemplates.cs`
  Holds persona prompt variants and directness rules.
- `src/Conscia.AI/Services/BaseAIService.cs`
  Applies intensity-aware temperature and prompt selection across pre-purchase and reflection flows.
- `app/lib/services/user_service.dart`
  Reads/writes the new preference in the app profile model.
- `app/lib/screens/settings/settings_screen.dart`
  Adds the AI Personality Intensity control.
- `app/lib/screens/assistant/pre_purchase_screen.dart`
  Uses new branded loader/header treatment.
- `app/lib/screens/assistant/widgets/typing_indicator.dart`
  Replace or evolve into the assistant clash-state loader.
- `app/lib/screens/transactions/transaction_detail_screen.dart`
  Uses the quieter reflection loader in the sheet.
- `app/lib/widgets/amount_input_field.dart`
  Shared amount input redesign used by assistant + transaction form.
- `app/lib/core/assets/` or `app/lib/widgets/`
  New conscience motif widgets/custom painters for small-size UI use.
- `app/lib/core/constants/category_icons.dart`
  Transition point for the new custom category icon family.
- `app/lib/core/constants/app_icons.dart`
  Transition point for any new shared branded AI icon tokens.
- `app/assets/images/app_icon.svg`
  Source brand reference for the refreshed app-icon direction.
- `app/web/index.html`
  Marketing-facing hero language / visual hook alignment starter.
- `app/test/screens/settings/`
  Settings tests for intensity preference.
- `app/test/screens/assistant/`
  Assistant loader / header / amount input tests.
- `app/test/screens/transactions/`
  Reflection loader and amount-input reuse tests.
- `tests/Conscia.Tests.Unit/`
  Backend profile + AI behavior coverage.

**Locked art direction:**
- base the conscience/app icon work on the previously reviewed `C` exploration direction
- keep the devil on the left and angel on the right
- shift the devil toward a darker, moodier red that blends more closely with the navy background
- keep the angel side brighter for contrast and launcher-size readability

---

### Task 1: Persist AI Personality Intensity In User Profile

**Files:**
- Modify: `src/Conscia.Domain/Entities/User.cs`
- Modify: `src/Conscia.Application/DTOs/UserProfileUpdateDto.cs`
- Modify: `src/Conscia.Application/Services/UserService.cs`
- Modify: `src/Conscia.Application/Validators/UserProfileUpdateValidator.cs`
- Modify: `src/Conscia.Api/Endpoints/UserEndpoints.cs`
- Modify: `src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs`
- Create: `src/Conscia.Infrastructure/Migrations/*AddAiPersonalityIntensityToUsers*.cs`
- Test: `tests/Conscia.Tests.Unit/Application/UserServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/UserEndpointTests.cs`

- [ ] **Step 1: Write the failing backend tests for profile persistence**

Add test coverage that expects:
- `GET /api/v1/users/me` returns `aiPersonalityIntensity`
- `PUT /api/v1/users/me` accepts `aiPersonalityIntensity`
- `UserService.UpdateProfileAsync` persists the new value

- [ ] **Step 2: Run the focused tests to verify they fail**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~UserServiceTests|FullyQualifiedName~UserEndpointTests"`
Expected: FAIL with missing property / response-field assertions

- [ ] **Step 3: Add the domain + DTO + service property**

Use a string-backed preference for the first pass:
- allowed values: `mild`, `balanced`, `intense`
- default: `balanced`

- [ ] **Step 4: Add migration and endpoint serialization**

Ensure profile responses include the new field and profile updates can persist it without breaking existing profile updates.

- [ ] **Step 5: Re-run focused tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~UserServiceTests|FullyQualifiedName~UserEndpointTests"`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Domain/Entities/User.cs src/Conscia.Application/DTOs/UserProfileUpdateDto.cs src/Conscia.Application/Services/UserService.cs src/Conscia.Application/Validators/UserProfileUpdateValidator.cs src/Conscia.Api/Endpoints/UserEndpoints.cs src/Conscia.Infrastructure/Persistence/Configurations/UserConfiguration.cs src/Conscia.Infrastructure/Migrations tests/Conscia.Tests.Unit/Application/UserServiceTests.cs tests/Conscia.Tests.Unit/Api/UserEndpointTests.cs
git commit -m "feat: persist ai personality intensity preference"
```

### Task 2: Make AI Orchestration Intensity-Aware

**Files:**
- Modify: `src/Conscia.Application/Models/AIContext.cs`
- Modify: `src/Conscia.AI/Prompts/PromptTemplates.cs`
- Modify: `src/Conscia.AI/Services/BaseAIService.cs`
- Modify: `src/Conscia.Api/Endpoints/AIEndpoints.cs`
- Test: `tests/Conscia.Tests.Unit/Api/AIEndpointTests.cs`
- Create: `tests/Conscia.Tests.Unit/Application/PromptTemplateTests.cs`

- [ ] **Step 1: Write failing tests for intensity-aware prompt/temperature behavior**

Cover:
- default intensity is `balanced`
- mild/balanced/intense select different temperatures
- reflection/pre-purchase both respect the same intensity input

- [ ] **Step 2: Run focused tests to verify failure**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~AIEndpointTests|FullyQualifiedName~PromptTemplateTests"`
Expected: FAIL because intensity is not yet applied

- [ ] **Step 3: Extend `AIContext` with the effective intensity**

Thread the preference in without adding separate endpoint parameters. The API should derive the value from the current user profile before calling the AI service.

- [ ] **Step 4: Add prompt/directness selection in `PromptTemplates.cs`**

Implement:
- persona instruction variants
- directness copy shaping
- mild/balanced/intense lookup helpers

- [ ] **Step 5: Apply intensity-aware temperatures in `BaseAIService.cs`**

Map:
- mild: softer
- balanced: default
- intense: stronger contrast

Keep safety/business logic unchanged.

- [ ] **Step 6: Re-run focused tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~AIEndpointTests|FullyQualifiedName~PromptTemplateTests"`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/Models/AIContext.cs src/Conscia.AI/Prompts/PromptTemplates.cs src/Conscia.AI/Services/BaseAIService.cs src/Conscia.Api/Endpoints/AIEndpoints.cs tests/Conscia.Tests.Unit/Api/AIEndpointTests.cs tests/Conscia.Tests.Unit/Application
git commit -m "feat: make ai personas intensity aware"
```

### Task 3: Expose AI Personality Intensity In Flutter Settings

**Files:**
- Modify: `app/lib/services/user_service.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Test: `app/test/screens/settings/settings_screen_ai_intensity_test.dart`

- [ ] **Step 1: Write the failing settings widget test**

Cover:
- setting row renders `Mild`, `Balanced`, `Intense`
- current profile value selects the correct option
- tapping a new option calls `updateProfile(aiPersonalityIntensity: ...)`

- [ ] **Step 2: Run the focused Flutter test and verify it fails**

Run: `flutter test test/screens/settings/settings_screen_ai_intensity_test.dart`
Expected: FAIL because the control does not exist yet

- [ ] **Step 3: Extend `UserProfile` and `updateProfile()` in `user_service.dart`**

Add `aiPersonalityIntensity` to the profile model and request payload.

- [ ] **Step 4: Add the Settings UI control**

Use a segmented/pill-style selector consistent with the visual spec:
- `Mild`
- `Balanced`
- `Intense`

- [ ] **Step 5: Re-run the focused test**

Run: `flutter test test/screens/settings/settings_screen_ai_intensity_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/services/user_service.dart app/lib/screens/settings/settings_screen.dart app/test/screens/settings/settings_screen_ai_intensity_test.dart
git commit -m "feat: add ai personality intensity setting"
```

### Task 4: Build The Small-Size Conscience Motif System

**Files:**
- Create: `app/lib/widgets/conscience_motif.dart`
- Create: `app/lib/widgets/conscience_loader.dart`
- Modify: `app/lib/screens/assistant/widgets/typing_indicator.dart`
- Test: `app/test/widgets/conscience_loader_test.dart`

- [ ] **Step 1: Write widget tests for branded loader states**

Cover:
- assistant clash-state variant renders
- reflection variant renders
- captions can differ by mode

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `flutter test test/widgets/conscience_loader_test.dart`
Expected: FAIL because the motif widgets do not exist yet

- [ ] **Step 3: Create the simplified conscience motif widgets**

Implement:
- compact angel/devil emblem
- assistant clash-state motion variant
- reflection calm variant
- devil-left / angel-right orientation

Prefer small custom-painted/vector-like widgets over reusing the full detailed icon.

- [ ] **Step 4: Wire `typing_indicator.dart` to the new loader**

Keep the API surface focused so assistant/reflection can reuse the same family with different intensity.

- [ ] **Step 5: Re-run the focused test**

Run: `flutter test test/widgets/conscience_loader_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/widgets/conscience_motif.dart app/lib/widgets/conscience_loader.dart app/lib/screens/assistant/widgets/typing_indicator.dart app/test/widgets/conscience_loader_test.dart
git commit -m "feat: add branded conscience loader system"
```

### Task 5: Refresh Pre-Purchase Assistant And Reflection Loading States

**Files:**
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/assistant/widgets/ai_message_bubble.dart` (only if spacing/styling needs alignment)
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Add failing widget assertions for the new branded states**

Cover:
- assistant input screen shows the new conscience motif header
- assistant loading state uses the clash-state loader copy
- reflection sheet loading uses the calmer branded loader

- [ ] **Step 2: Run focused tests to verify failure**

Run: `flutter test test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart`
Expected: FAIL on missing loader/header expectations

- [ ] **Step 3: Update Pre-Purchase Assistant UI**

Apply:
- new header motif
- branded thinking copy
- cleaner spacing aligned with the spec

- [ ] **Step 4: Update reflection sheet loading**

Swap the generic spinner for the quieter conscience loader.

- [ ] **Step 5: Re-run focused tests**

Run: `flutter test test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "feat: refresh assistant and reflection loading states"
```

### Task 6: Redesign The Shared Amount Input

**Files:**
- Modify: `app/lib/widgets/amount_input_field.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Test: `app/test/widgets/amount_input_field_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`

- [ ] **Step 1: Write failing tests for the updated amount input hierarchy**

Cover:
- centered hero amount
- left sign accent
- right currency chip
- expense/income visual variants remain distinguishable

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/widgets/amount_input_field_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: FAIL because current structure does not match the new hierarchy

- [ ] **Step 3: Refactor `AmountInputField`**

Keep behavior intact while changing:
- spacing
- typography scale
- sign placement
- currency chip balance
- container treatment

- [ ] **Step 4: Update both consuming screens if they need layout adjustments**

Ensure assistant and transaction form both look intentional with the shared component.

- [ ] **Step 5: Re-run focused tests**

Run: `flutter test test/widgets/amount_input_field_test.dart test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/transaction_form_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/widgets/amount_input_field.dart app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/transaction_form_screen.dart app/test/widgets/amount_input_field_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/transaction_form_screen_test.dart
git commit -m "feat: redesign shared amount input"
```

### Task 7: Introduce The Full Custom Category Icon Family

**Files:**
- Modify: `app/lib/core/constants/category_icons.dart`
- Create: `app/lib/core/assets/conscia_category_icons.dart` (or equivalent focused file if splitting by platform helps)
- Modify: category-consuming screens/widgets that need rendering adjustments
- Test: `app/test/core/category_icons_test.dart`
- Test: `app/test/screens/transactions/widgets/quick_preset_chips_test.dart`

- [ ] **Step 1: Write failing tests for category icon coverage**

Cover:
- every supported category resolves to a Conscia-owned icon
- platform adaptation preserves the same concept per category

- [ ] **Step 2: Run focused tests to verify failure**

Run: `flutter test test/core/category_icons_test.dart test/screens/transactions/widgets/quick_preset_chips_test.dart`
Expected: FAIL because current mapping still relies on platform-native icon defaults

- [ ] **Step 3: Implement the category icon family**

Add all current categories in one pass.

Keep:
- same conceptual metaphors across platforms
- slightly bolder Android treatment
- slightly lighter/cleaner iOS treatment

- [ ] **Step 4: Update consuming chips/cards if spacing needs to change**

Make sure the more illustrative mini-icons still scan cleanly in repeated rows.

- [ ] **Step 5: Re-run focused tests**

Run: `flutter test test/core/category_icons_test.dart test/screens/transactions/widgets/quick_preset_chips_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/core/constants/category_icons.dart app/lib/core/assets/conscia_category_icons.dart app/test/core/category_icons_test.dart app/test/screens/transactions/widgets/quick_preset_chips_test.dart
git commit -m "feat: add custom category icon family"
```

### Task 8: Refine App Icon Direction Assets

**Files:**
- Modify: `app/assets/images/app_icon.svg`
- Create: any supporting simplified conscience SVGs or derived assets under `app/assets/images/`
- Test: visual/manual review in launcher-sized export where practical

- [ ] **Step 1: Create the refined icon brief in comments or asset notes before editing**

Lock:
- `C` direction base
- devil on the left
- angel on the right
- darker devil red close to the navy field
- richer but cleaner premium mark at launcher size

- [ ] **Step 2: Update the app icon asset direction**

Refine `app_icon.svg` or add a simplified launcher-ready sibling asset that follows the locked direction.

- [ ] **Step 3: Manually inspect small-size readability**

Check the mark at compact sizes to ensure:
- silhouettes still read clearly
- left/right character roles remain obvious
- darker devil red does not disappear into the background

- [ ] **Step 4: Commit**

```bash
git add app/assets/images/app_icon.svg app/assets/images
git commit -m "feat: refine conscience app icon direction"
```

### Task 9: Align The Marketing Entry Surface With The New Visual Language

**Files:**
- Modify: `app/web/index.html`
- Create: `app/web/phase4-preview.css`

- [ ] **Step 1: Write down the minimal marketing alignment checklist in comments or a tiny fixture**

Checklist:
- hero wording references the financial conscience framing
- visual hook can reuse the simplified conscience mark direction
- amount-input/assistant visual language is reflected in the hero treatment

- [ ] **Step 2: Update `app/web/index.html` with the Phase 4-aligned hero starter**

Keep this limited:
- headline
- supporting copy
- motif placement hook
- no full site rewrite

- [ ] **Step 3: Manually verify the web entry file reads coherently with the app direction**

Run: open `app/web/index.html` in the existing local web flow or inspect the resulting markup
Expected: the hero language and structure no longer feel like a separate brand voice

- [ ] **Step 4: Commit**

```bash
git add app/web/index.html
git commit -m "docs: align web hero with phase 4 visual language"
```

### Task 10: Full Verification Pass

**Files:**
- Verify all changed files from Tasks 1-8

- [ ] **Step 1: Run backend build**

Run: `dotnet build src/Conscia.Api/Conscia.Api.csproj`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run focused backend tests**

Run: `dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~UserServiceTests|FullyQualifiedName~UserEndpointTests|FullyQualifiedName~AIEndpointTests|FullyQualifiedName~PromptTemplateTests"`
Expected: PASS

- [ ] **Step 3: Run focused Flutter tests**

Run: `flutter test test/screens/settings/ test/screens/assistant/ test/screens/transactions/ test/widgets/amount_input_field_test.dart test/widgets/conscience_loader_test.dart test/core/category_icons_test.dart`
Expected: PASS

- [ ] **Step 4: Run focused Flutter analyze**

Run: `flutter analyze lib/screens/settings/settings_screen.dart lib/screens/assistant/pre_purchase_screen.dart lib/screens/transactions/transaction_form_screen.dart lib/screens/transactions/transaction_detail_screen.dart lib/widgets/amount_input_field.dart lib/widgets/conscience_loader.dart lib/core/constants/category_icons.dart`
Expected: No errors

- [ ] **Step 5: Commit any final fixups**

```bash
git add .
git commit -m "test: verify phase 4 ai personality refresh"
```

---

## Spec Coverage Check

- Global AI intensity preference: Task 1 + Task 3
- Prompt/directness/temperature behavior: Task 2
- Assistant branded clash-state loader: Task 4 + Task 5
- Reflection loader: Task 4 + Task 5
- Shared amount-input redesign: Task 6
- Simplified conscience motif family: Task 4
- App icon direction refinement: Task 8
- App/web alignment starter: Task 9
- Full category icon family with platform adaptation: Task 7

## Notes

- Voice input remains deliberately out of scope for this phase.
- The category icon family is included in this plan because the spec explicitly expanded Phase 4 to include it in one pass.
- The marketing work here is intentionally a starter alignment, not a full landing-page redesign.
